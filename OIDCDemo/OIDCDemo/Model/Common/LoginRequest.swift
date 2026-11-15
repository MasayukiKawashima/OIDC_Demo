//
//  LoginRequest.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/15.
//

import Foundation

/// ログインAPIに送る内容。
nonisolated struct LoginRequest: Sendable {
    let idToken: Secret
    let name: String
}
