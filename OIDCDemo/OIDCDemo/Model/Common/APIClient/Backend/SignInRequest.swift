//
//  SignInRequest.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/15.
//

import Foundation

/// サインインAPIに送る内容。
nonisolated struct SignInRequest: Sendable {
    let idToken: Secret
    let name: String
}
