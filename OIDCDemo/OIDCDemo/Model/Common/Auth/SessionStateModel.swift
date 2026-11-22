//
//  SessionStateModel.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/20.
//

import Foundation
import Observation

/// 画面に見せるサインイン状態（セッションの有無と会員情報）。状態を変えるのはこのクラスだけ。
/// 自社トークンもGoogleのトークンも持たない。トークンを使った状態の管理は SessionTokenManager が行う。
@Observable
@MainActor
final class SessionStateModel {

  // MARK: - Types

  enum Phase {
    /// 起動時の復元中（セッションがあるかまだ分からない）
    case restoring
    /// セッションがない（サインイン前）
    case signedOut
    /// セッションがある。会員情報は名前を含むため print に渡さない
    case signedIn(MemberInfo)
  }

  // MARK: - Properties

  /// 今のサインイン状態。書き換えられるのはこのクラスの中だけ
  private(set) var phase: Phase = .restoring

  /// 認証の手続きの窓口
  private let authService: AuthService

  init(authService: AuthService) {
    self.authService = authService
  }

  // MARK: - 起動時の復元

  /// 起動時に1回だけ呼ぶ。失敗した場合はサインイン前にする。
  func restore() async {
    guard case .restoring = phase else { return }
    do {
      if let memberInfo = try await authService.restore() {
        phase = .signedIn(memberInfo)
      } else {
        phase = .signedOut
      }
    } catch {
      print("[SessionState] restore: 失敗（\(type(of: error))）")
      phase = .signedOut
    }
  }
}

// MARK: - サインイン

extension SessionStateModel: SignInPerforming {

  func signIn() async throws {
    let memberInfo = try await authService.signIn()
    phase = .signedIn(memberInfo)
  }
}

// MARK: - サインアウト

extension SessionStateModel: SignOutPerforming {

  /// AuthService は失敗してもローカルのトークンを消すため、常にサインイン前に戻す。
  func signOut() async {
    await authService.signOut()
    phase = .signedOut
  }
}
