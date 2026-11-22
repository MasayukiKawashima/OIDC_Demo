//
//  SignInHeaderView.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/19.
//

import SwiftUI

/// サインイン画面の上部（アイコン、アプリ名、説明文）。
/// Googleのロゴはボタン以外に使えないため、アイコンにはSF Symbolsを使う。
struct SignInHeaderView: View {
  
  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "person.badge.key.fill")
        .font(.system(size: 52))
        .foregroundStyle(.tint)
        .frame(width: 112, height: 112)
        .background(.tint.opacity(0.12), in: Circle())
      
      Text("OIDC Demo")
        .font(.largeTitle.bold())
      
      Text("Googleアカウントでサインインする\nOpenID Connectの学習用デモアプリです")
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
  }
}

#Preview {
  SignInHeaderView()
}
