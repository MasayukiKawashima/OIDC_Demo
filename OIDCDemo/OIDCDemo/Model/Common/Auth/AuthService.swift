//
//  AuthService.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/14.
//

import Foundation

/// 認証処理の共通の窓口（サインイン、サインアウト、起動時の復元、会員情報の取得）。
/// - IDトークンを得る部分は GoogleTokenProvider に、自社トークンの管理は SessionTokenManager に任せる
/// - サインインが必要な API（会員情報）は、SessionTokenManager.withValidAccessToken で有効なアクセストークンを借りて呼ぶ
/// 自前実装と AppAuth版は、GoogleTokenProvider と保存先（KeychainService）が違う AuthService として作る。
@MainActor
final class AuthService {

  private let tokenProvider: any GoogleTokenProvider
  private let profileClient: any GoogleProfileClientProtocol
  private let revocationClient: any GoogleTokenRevocationClientProtocol
  private let sessionTokenManager: SessionTokenManager
  /// サインインが必要な API を呼ぶためのバックエンド（SessionTokenManager に渡したものと同じ）
  private let backend: any BackendClientProtocol
  /// 起動時の復元を行うか（FirstLaunchKeychainReset が削除に失敗した場合は false）
  private let restoresSession: Bool

  init(tokenProvider: any GoogleTokenProvider,
       profileClient: any GoogleProfileClientProtocol,
       revocationClient: any GoogleTokenRevocationClientProtocol,
       sessionTokenManager: SessionTokenManager,
       backend: any BackendClientProtocol,
       restoresSession: Bool) {
    self.tokenProvider = tokenProvider
    self.profileClient = profileClient
    self.revocationClient = revocationClient
    self.sessionTokenManager = sessionTokenManager
    self.backend = backend
    self.restoresSession = restoresSession
  }

  // MARK: - 起動時の復元

  /// 起動時の復元。サインイン状態なら会員情報を、サインインしていなければ nil を返す。
  func restore() async throws -> MemberInfo? {
    guard restoresSession else {
      print("[Auth] restore: 前のインストールのデータが残っている可能性があるため、復元しない")
      return nil
    }
    guard try await sessionTokenManager.restore() else {
      return nil
    }
    do {
      return try await memberInfo()
    } catch SessionError.sessionExpired {
      print("[Auth] restore: サインイン状態が無効（サインインし直しが必要）")
      return nil
    }
  }

  // MARK: - 会員情報

  /// 会員情報を取得する（サインインが必要な API）。
  func memberInfo() async throws -> MemberInfo {
    let backend = self.backend
    let info = try await sessionTokenManager.withValidAccessToken { accessToken in
      try await backend.fetchMemberInfo(accessToken: accessToken)
    }
    print("[Auth] memberInfo: 取得できた")
    return info
  }

  // MARK: - サインイン

  /// Google でサインインし、バックエンドにサインインして、会員情報を返す。
  /// Google のトークンはこの関数の中だけで使い、終われば破棄される（保存しない）
  func signIn() async throws -> MemberInfo {

    // 各種トークンの取得
    let googleTokens = try await tokenProvider.fetchVerifiedTokens()
    // People API の結果は、失効を済ませるまで投げずに取っておく
    let nameResult: Result<String, any Error>
    do {
      // PeopleAPIにアクセスしてリソースの取得
      nameResult = .success(try await profileClient.fetchDisplayName(accessToken: googleTokens.accessToken))
    } catch {
      // PeopleAPIが失敗してもここではエラーを投げない
      // なぜならPeopleAPIの成否にかかわらずアクセストークンの失効を行う必要があり、ここで投げると失効処理まで進まないから
      nameResult = .failure(error)
    }

    //　アクセストークンの失効
    // People API の成否を問わず、使い終わったアクセストークンを失効させる（対応するリフレッシュトークンもあわせて無効になる）
    do {
      try await revocationClient.revoke(token: googleTokens.accessToken)
    } catch {
      // People API も失敗していた場合は、原因である People API のエラーを投げる
      if case .failure(let profileError) = nameResult {
        throw profileError
      }
      // 失効に失敗したら、サインイン全体を失敗にする（モックへのサインインには進まない）
      throw error
    }

    // People API が失敗しているときはここでエラーを投げる
    // この段階であればアクセストークンの失効が完了しているので投げても問題なし
    let name = try nameResult.get()

    //　自社バックエンドにアクセスして会員情報の取得と自社トークンの保存
    let status = try await sessionTokenManager.signIn(idToken: googleTokens.idToken, name: name)
    print("[Auth] signIn: 成功（\(status == .existing ? "既存会員" : "新規登録")）")
    return try await memberInfo()
  }

  // MARK: - サインアウト

  func signOut() async {
    await sessionTokenManager.signOut()
  }
}
