//
//  MemberStatus.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/04.
//

import Foundation

/// ログインした会員が、既存の会員か新規登録か。
nonisolated enum MemberStatus: Sendable {
    case existing
    case newlyRegistered
}
