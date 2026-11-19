//
//  SignInProgressView.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/19.
//

import SwiftUI

/// サインインの処理中の表示。ボタンの画像は変えられないため、ボタンの下に出す。
/// 表示しないときも場所を確保し、切り替わってもボタンの位置がずれないようにする。
struct SignInProgressView: View {
  
  let isVisible: Bool
  
  var body: some View {
    HStack(spacing: 8) {
      ProgressView()
      Text("サインイン中…")
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
    .opacity(isVisible ? 1 : 0)
    .accessibilityHidden(!isVisible)
  }
}

#Preview {
  SignInProgressView(isVisible: true)
}
