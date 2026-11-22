//
//  GoogleSignInButton.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/19.
//

import SwiftUI

/// Googleの公式素材の画像（アセット SignInWithGoogle）をそのまま使うサインインボタン。
/// 無効にするときは、呼び出し側で .disabled(_:) を付ける。
struct GoogleSignInButton: View {
  
  let action: () -> Void
  
  var body: some View {
    Button(action: action) {
      Image("SignInWithGoogle")
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Googleでサインイン")
  }
}

#Preview {
  GoogleSignInButton {}
}
