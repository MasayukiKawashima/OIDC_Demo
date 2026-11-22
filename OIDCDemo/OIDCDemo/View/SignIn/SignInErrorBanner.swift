//
//  SignInErrorBanner.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/19.
//

import SwiftUI

/// サインインに失敗したときのエラー表示。
/// 文言は原因の詳細を含まない一般的なものにする（詳細は print() で型とコードだけを出す）。
struct SignInErrorBanner: View {
  
  let message: String
  
  var body: some View {
    Label(message, systemImage: "exclamationmark.triangle.fill")
      .font(.footnote)
      .foregroundStyle(.red)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(12)
      .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
  }
}

#Preview {
  SignInErrorBanner(message: "サインインに失敗しました。もう一度お試しください。")
    .padding()
}
