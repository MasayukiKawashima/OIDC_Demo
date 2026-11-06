//
//  LoginResult.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/04.
//

import Foundation

nonisolated struct LoginResult: Sendable {
    let tokens: BackendTokenResponse
    let memberStatus: MemberStatus
}
