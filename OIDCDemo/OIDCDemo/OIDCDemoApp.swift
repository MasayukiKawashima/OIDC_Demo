//
//  OIDCDemoApp.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/10/30.
//

import SwiftUI

@main
struct OIDCDemoApp: App {

  @State private var sessionState: SessionStateModel

  init() {
    _sessionState = State(initialValue: SessionStateModel(authService: Self.makeSelfMadeAuthService()))
  }

  var body: some Scene {
    WindowGroup {
      RootView()
        .environment(sessionState)
    }
  }

// MARK: - 自前実装

/// 自前実装の AuthService を組み立てる。
private static func makeSelfMadeAuthService() -> AuthService {
  // Keychain を読むどの処理よりも先に呼ぶ（false なら起動時の復元をしない）
  let restoresSession = FirstLaunchKeychainReset.run()

  // モックと IDトークンの確認で、同じ client_id を使う
  let server = MockBackendServer(expectedAudience: AppConfig.googleClientID)
  let backend = BackendClient(server: server)
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
