//
//  MemberInfo.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/04.
//

import Foundation

/// 会員情報。画面に表示するユーザー向けの情報。
/// 名前は個人情報なので、print などで出力しない（出すのは「取得できたかどうか」だけ）。
nonisolated struct MemberInfo: Sendable {
    let name: String
    let loggedInAt: Date
}
