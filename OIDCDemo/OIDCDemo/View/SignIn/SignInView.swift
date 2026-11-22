//
//  SignInView.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/19.
//

import SwiftUI

/// サインイン前の画面。
/// 画面が持つのは表示のための状態（処理中かどうか、エラーの文言）だけにし、Googleのトークンは持たない。
struct SignInView: View {

  // MARK: - Properties

  /// サインインの処理中かどうか。処理中はボタンを無効にし、認可リクエストが2つ同時に始まらないようにする
  @State private var isSigningIn: Bool
  /// サインインに失敗したときの文言。キャンセルのとき（サインイン画面を閉じただけ）は表示しない
  @State private var errorMessage: String?

  // SignInのみしかできない形で依存
  private let signInPerformer: any SignInPerforming

  init(isSigningIn: Bool = false, errorMessage: String? = nil, signInPerformer: any SignInPerforming) {
    _isSigningIn = State(initialValue: isSigningIn)
    _errorMessage = State(initialValue: errorMessage)
    self.signInPerformer = signInPerformer
  }

  // MARK: - Body

  var body: some View {
    VStack(spacing: 0) {
      Spacer()
      SignInHeaderView()
        .padding(.horizontal, 24)
      Spacer()
      VStack(spacing: 16) {
        if let errorMessage {
          SignInErrorBanner(message: errorMessage)
        }
        GoogleSignInButton {
          startSignIn()
        }
        .disabled(isSigningIn)
        SignInProgressView(isVisible: isSigningIn)
      }
      .padding(.horizontal, 24)
      .padding(.bottom, 48)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.systemGroupedBackground))
  }

  // MARK: - Methods

  private func startSignIn() {
    guard !isSigningIn else { return }
    // サイン中にしてボタンを無効化
    isSigningIn = true

    // エラーメッセージ初期化
    errorMessage = nil

    Task {
      // サインインが終わったらボタンを有効化
      defer { isSigningIn = false }

      do {
        try await signInPerformer.signIn()
      } catch GoogleTokenProviderError.canceled {
        print("[SignIn] キャンセル")
      } catch {
        print("[SignIn] 失敗（\(type(of: error))）")
        errorMessage = "サインインに失敗しました。もう一度お試しください。"
      }
    }
  }
}

// MARK: - Preview

/// プレビュー用のサインインの相手。決まった結果を、決まった時間の後に返す。
private struct PreviewSignInPerformer: SignInPerforming {
  /// サインインの結果（失敗させる場合はエラーを入れる）
  var result: Result<Void, any Error> = .success(())
  /// 結果を返すまでの時間（処理中の表示を確かめるため）
  var delay: Duration = .seconds(2)

  func signIn() async throws {
    try await Task.sleep(for: delay)
    try result.get()
  }
}

/// プレビュー用の失敗
private struct PreviewSignInError: Error {}

#Preview("サインイン前") {
  SignInView(signInPerformer: PreviewSignInPerformer())
}
#Preview("処理中") {
  SignInView(isSigningIn: true, signInPerformer: PreviewSignInPerformer())
}
#Preview("エラー") {
  SignInView(
    errorMessage: "サインインに失敗しました。もう一度お試しください。", signInPerformer: PreviewSignInPerformer()
  )
}
