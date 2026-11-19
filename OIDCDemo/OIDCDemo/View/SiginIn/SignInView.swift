//
//  SignInView.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/19.
//
//
//  SignInView.swift
//  OIDCDemo
//

import SwiftUI

/// サインイン前の画面。
/// 画面が持つのは表示のための状態（処理中かどうか、エラーの文言）だけにし、Googleのトークンは持たない。
struct SignInView: View {
  
  /// サインインの処理中かどうか。処理中はボタンを無効にし、認可リクエストが2つ同時に始まらないようにする
  @State private var isSigningIn: Bool
  /// サインインに失敗したときの文言。キャンセルのとき（サインイン画面を閉じただけ）は表示しない
  @State private var errorMessage: String?
  
  init(isSigningIn: Bool = false, errorMessage: String? = nil) {
    _isSigningIn = State(initialValue: isSigningIn)
    _errorMessage = State(initialValue: errorMessage)
  }
  
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
          // 処理は手順①の組み込みで追加する
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
}

#Preview("サインイン前") {
  SignInView()
}

#Preview("処理中") {
  SignInView(isSigningIn: true)
}

#Preview("エラー") {
  SignInView(errorMessage: "サインインに失敗しました。もう一度お試しください。")
}
