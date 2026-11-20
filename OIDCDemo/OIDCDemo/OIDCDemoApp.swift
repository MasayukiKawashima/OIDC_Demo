//
//  OIDCDemoApp.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/10/30.
//

import SwiftUI

@main
struct OIDCDemoApp: App {

  // アプリのセッション状態（サインイン状態）を管理するModel
  @State private var sessionState: SessionStateModel

  init() {
    // Keychain の項目の初回削除処理
    // Keychain を読むどの処理よりも先に呼ぶ（false なら起動時の復元をしない）
    let restoresSession = FirstLaunchKeychainReset.run()
    // モックバックエンド構築
    let backend = Self.makeBackend()
    // authServiceの構築
    let authService = Self.makeSelfMadeAuthService(backend: backend, restoresSession: restoresSession)
    //sessionStateModelの構築
    _sessionState = State(initialValue: SessionStateModel(authService: authService))
  }

  var body: some Scene {
    WindowGroup {
      RootView()
        .environment(sessionState)
    }
  }

// MARK: - 依存関係の組み立ての起点処理（コンポジションルート）
// MARK: - 共通
  /// バックエンド（モック）とのやり取りの窓口を作る。自前実装とAppAuth版で共通。
  private static func makeBackend() -> BackendClient {
    // モックと IDトークンの確認で、同じ client_id を使う
    let server = MockBackendServer(expectedAudience: AppConfig.googleClientID)
    return BackendClient(server: server)
  }

// MARK:  - 自前実装

  private static func makeSelfMadeAuthService(backend: BackendClient, restoresSession: Bool) -> AuthService {
    // 自社トークンの保存先は、実装ごとに分ける
    let signInState = SignInStateManager(backend: backend, service: .selfMade)

    return AuthService(
      tokenProvider: SelfMadeGoogleTokenProvider(),
      profileClient: GooglePeopleAPIClient(),
      revocationClient: GoogleTokenRevocationClient(),
      signInState: signInState,
      backend: backend,
      restoresSession: restoresSession
    )
  }

// MARK: - AppAuth-iOS実装

}

#Preview {
}
