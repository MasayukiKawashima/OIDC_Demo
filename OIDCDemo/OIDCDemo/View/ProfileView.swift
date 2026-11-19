//
//  ProfileView.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/19.
//
import SwiftUI

/// サインイン後の画面。名前とサインイン日時（どちらもモックの会員情報APIから受け取ったもの）とサインアウトボタンを表示する。
/// トークン、sub、検証結果などの内部情報は表示しない。
struct ProfileView: View {

  /// 会員情報。名前は個人情報のため print に渡さない
  let memberInfo: MemberInfo

  var body: some View {
    NavigationStack {
      List {
        Section {
          HStack(spacing: 16) {
            Image(systemName: "person.crop.circle.fill")
              .font(.system(size: 52))
              .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 4) {
              Text(memberInfo.name)
                .font(.title3.bold())
              Text("サインイン中")
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
          }
          .padding(.vertical, 8)
        }

        Section {
          LabeledContent("サインイン日時") {
            Text(memberInfo.signedInAt, format: .dateTime.year().month().day().hour().minute())
          }
        }

        Section {
          Button(role: .destructive) {
            // 処理は手順①の組み込みで追加する
          } label: {
            Text("サインアウト")
              .frame(maxWidth: .infinity)
          }
        }
      }
      .navigationTitle("プロフィール")
    }
  }
}

#Preview {
  ProfileView(memberInfo: MemberInfo(name: "山田 太郎", signedInAt: .now))
}
