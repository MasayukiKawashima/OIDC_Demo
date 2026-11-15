//
//  AuthService.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/14.
//

import Foundation

// 認証処理の共通の窓口（ログイン、ログアウト、起動時の復元、会員情報の取得）。
/// - IDトークンを得る部分は GoogleTokenProvider に、ログイン状態の管理は LoginStateManager に任せる
/// - ログインが必要な API（会員情報）は、LoginStateManager.withValidAccessToken で有効なアクセストークンを借りて呼ぶ
/// 自前実装と AppAuth版は、GoogleTokenProvider と保存先（KeychainService）が違う AuthService として作る。
@MainActor
final class AuthService {

  private let tokenProvider: any GoogleTokenProvider
  private let profileClient: any GoogleProfileClientProtocol
  private let loginState: LoginStateManager
  /// ログインが必要な API を呼ぶためのバックエンド（LoginStateManager に渡したものと同じ）
  private let backend: any BackendClientProtocol
  /// 起動時の復元を行うか（FirstLaunchKeychainReset が削除に失敗した場合は false）
  private let restoresSession: Bool

  init(tokenProvider: any GoogleTokenProvider,
       profileClient: any GoogleProfileClientProtocol,
       loginState: LoginStateManager,
       backend: any BackendClientProtocol,
       restoresSession: Bool) {
    self.tokenProvider = tokenProvider
    self.profileClient = profileClient
    self.loginState = loginState
    self.backend = backend
    self.restoresSession = restoresSession
  }

  // MARK: - 起動時の復元

  /// 起動時の復元。ログイン状態なら会員情報を、ログインしていなければ nil を返す。
  func restore() async throws -> MemberInfo? {
    guard restoresSession else {
      print("[Auth] restore: 前のインストールのデータが残っている可能性があるため、復元しない")
      return nil
    }
    guard try await loginState.restore() else {
      return nil
    }
    do {
      return try await memberInfo()
    } catch LoginStateError.sessionExpired {
      print("[Auth] restore: ログイン状態が無効（ログインし直しが必要）")
      return nil
    }
  }

  // MARK: - ログイン

  /// Google でログインし、バックエンドにログインして、会員情報を返す。
  func login() async throws -> MemberInfo {
      // Google のトークンはこの関数の中だけで使い、終われば破棄される（保存しない）
      let googleTokens = try await tokenProvider.fetchVerifiedTokens()
      let name = try await profileClient.fetchDisplayName(accessToken: googleTokens.accessToken)
      let status = try await loginState.login(idToken: googleTokens.idToken, name: name)
      print("[Auth] login: 成功（\(status == .existing ? "既存会員" : "新規登録")）")
      return try await memberInfo()
    }

  // MARK: - 会員情報

  /// 会員情報を取得する（ログインが必要な API）。
  func memberInfo() async throws -> MemberInfo {
    let backend = self.backend
    let info = try await loginState.withValidAccessToken { accessToken in
      try await backend.fetchMemberInfo(accessToken: accessToken)
    }
    print("[Auth] memberInfo: 取得できた")
    return info
  }

  // MARK: - ログアウト

  /// ログアウトする。
  func logout() async {
    await loginState.logout()
  }
}
