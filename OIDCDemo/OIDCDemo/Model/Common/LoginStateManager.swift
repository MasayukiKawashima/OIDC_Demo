//
//  LoginStateManager.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/09.
//
import Foundation

/// 自社トークンを使って、アプリのログイン状態を管理する（自前実装・AppAuth版で共通）。
/// - ログイン状態を変える処理（バックエンドへのログイン、トークンの保存・読み込み、リフレッシュ、ログアウト）を受け持つ
/// - ログインが必要な API は、withValidAccessToken で有効なアクセストークンを借りて、呼び出し側が呼ぶ。個々の API（会員情報など）は知らない
/// - Google とのやり取り（IDトークンを得るまで）は行わない。それは GoogleTokenProvider が受け持つ
actor LoginStateManager {
  private let backend: any BackendClientProtocol
  private let tokenStore: SessionTokenStore
  /// アクセストークンの期限のこの秒数前から、期限切れとみなして先にリフレッシュする
  private let refreshMargin: TimeInterval

  /// 今のトークン（メモリ上）。nil ならログインしていない
  private var tokens: SessionTokens?
  /// トークンが入れ替わるたびに増える番号。入れ替わった後に古いトークンでリフレッシュしないために使う
  private var generation = 0
  /// 実行中のリフレッシュ。リフレッシュを同時に2回走らせないよう、実行中ならこれを待つ
  private var refreshTask: Task<SessionTokens, Error>?

  /// - Parameters:
  ///   - backend: バックエンドとのやり取り（相手がモックか本物かは知らない）
  ///   - service: 自社トークンの保存先（.selfMade または .appAuth）
  ///   - refreshMargin: 期限のこの秒数前から、先にリフレッシュする
  init(backend: any BackendClientProtocol, service: KeychainService, refreshMargin: TimeInterval = 60) {
    self.backend = backend
    self.tokenStore = SessionTokenStore(service: service)
    self.refreshMargin = refreshMargin
  }

  /// ログインしているか（メモリ上にトークンがあるか）
  var isSignedIn: Bool { tokens != nil }

  // MARK: - ログイン

  /// 確認済みの IDトークンでバックエンドにログインし、受け取ったトークンを保存する。
  func login(idToken: Secret) async throws -> MemberStatus {
    let result: LoginResult
    do {
      result = try await backend.login(idToken: idToken)
    } catch BackendError.invalidIDToken {
      print("[LoginState] login: 失敗（バックエンドが IDトークンを受け付けなかった）")
      throw LoginStateError.loginRejected
    }
    try replaceTokens(with: result.tokens.sessionTokens())
    print("[LoginState] login: 成功（トークンを保存した）")
    return result.memberStatus
  }

  // MARK: - 起動時の読み込み

  /// 保存されたトークンを読み込む。トークンが使えるかどうかは、次に withValidAccessToken を使ったときに分かる。
  /// - Returns: トークンがあれば true（ログイン状態）、なければ false
  func restore() throws -> Bool {
    guard let saved = try tokenStore.load() else {
      print("[LoginState] restore: 保存されたトークンなし（ログインしていない）")
      return false
    }
    tokens = saved
    generation += 1
    print("[LoginState] restore: 保存されたトークンを読み込んだ")
    return true
  }

  // MARK: - 有効なアクセストークンの貸し出し

  /// 有効なアクセストークンを貸して、ログインが必要な処理を実行する。
  /// - ログインしていなければ、処理を実行せずに notSignedIn を投げる
  /// - 期限が近ければ（または切れていれば）、先にリフレッシュしてから貸す
  /// - 処理が BackendError.unauthorized（401）を投げたら、1回だけリフレッシュして新しいトークンで貸し直す
  /// - 貸し直しても 401、またはリフレッシュに失敗したら、トークンを削除して sessionExpired を投げる
  func withValidAccessToken<T: Sendable>(
    _ operation: @Sendable (Secret) async throws -> T
  ) async throws -> T {
    // 有効なアクセストークンの取得
    let (current, currentGeneration) = try await validTokens()

    do {
      // 渡された処理の実行
      return try await operation(current.accessToken)

      // リフレッシュトークンが無効だった場合
      // 一回だけリフレッシュして再実行
    } catch BackendError.unauthorized {
      print("[LoginState] 401。リフレッシュして1回だけ貸し直します")
      let refreshed = try await refreshTokens(ifGenerationIs: currentGeneration)
      do {
        let result = try await operation(refreshed.accessToken)
        print("[LoginState] 貸し直したトークンで成功した")
        return result

        // 再実行してもunauthorizedが投げられた場合
        // トークンを削除してセッション（セッションとはログイン状態を維持している状態）の終了
      } catch BackendError.unauthorized {
        print("[LoginState] 貸し直しても 401。セッションを終了します")
        try clearTokens()
        throw LoginStateError.sessionExpired
      }
    }
  }

  // MARK: - ログアウト

  /// バックエンドのログアウトを呼び、成否にかかわらずトークンを削除する。
  func logout() async {
    if let current = tokens {
      do {
        try await backend.logout(refreshToken: current.refreshToken)
      } catch {
        print("[LoginState] logout: バックエンドのログアウトに失敗（\(type(of: error))）。ローカルの削除は続ける")
      }
    }
    do {
      try clearTokens()
      print("[LoginState] logout: トークンを削除した")
    } catch {
      print("[LoginState] logout: トークンの削除に失敗（\(type(of: error))）")
    }
  }

  // MARK: - HelperMethods

  // MARK: 有効なトークンの取得

  private func validTokens() async throws -> (SessionTokens, Int) {
    guard let current = tokens else { throw LoginStateError.notSignedIn }
    if Date().addingTimeInterval(refreshMargin) < current.expiresAt {
      return (current, generation)
    }
    print("[LoginState] アクセストークンの期限が近い（または切れている）ため、先にリフレッシュします")
    let refreshed = try await refreshTokens(ifGenerationIs: generation)
    return (refreshed, generation)
  }

  // MARK: トークンのリフレッシュ
  
  /// リフレッシュする。同時に呼ばれても、実際のリフレッシュは1回だけにする。
  /// - Parameter expected: 呼び出し側が使っていたトークンの番号。すでに入れ替わっていれば、リフレッシュせずに新しいトークンを返す
  private func refreshTokens(ifGenerationIs expected: Int) async throws -> SessionTokens {
    // 他の処理ですでに入れ替わっていれば、それを使う（使用済みのリフレッシュトークンを送らない）
    if generation != expected {
      guard let tokens else { throw LoginStateError.sessionExpired }
      return tokens
    }
    // 実行中のリフレッシュがあれば、その結果を待つ
    if let refreshTask {
      return try await refreshTask.value
    }
    guard let current = tokens else { throw LoginStateError.notSignedIn }

    // actor の中で作った Task は actor の上で動くので、tokens などを直接書き換えられる
    let task = Task<SessionTokens, Error> {
      defer { self.refreshTask = nil }
      do {
        let response = try await self.backend.refresh(refreshToken: current.refreshToken)
        let newTokens = response.sessionTokens()
        try self.replaceTokens(with: newTokens)
        print("[LoginState] refresh: 成功（新しいトークンを保存した）")
        return newTokens
      } catch BackendError.invalidRefreshToken {
        print("[LoginState] refresh: 失敗（リフレッシュトークンが無効）。トークンを削除します")
        try? self.clearTokens()
        throw LoginStateError.sessionExpired
      }
    }
    refreshTask = task
    return try await task.value
  }

  // MARK:  トークンの置換

  /// トークンを入れ替えて保存する。メモリを先に更新し、今の起動中は新しいトークンで動けるようにする。
  private func replaceTokens(with newTokens: SessionTokens) throws {
    tokens = newTokens
    generation += 1
    try tokenStore.save(newTokens)
  }

  // MARK: トークンの削除

  /// トークンを削除する。メモリを先に消し、Keychain の削除に失敗してもログアウト状態にする。
  private func clearTokens() throws {
    tokens = nil
    generation += 1
    try tokenStore.delete()
  }
}
