//
//  BackendClientProtocol.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/04.
//
import Foundation

nonisolated protocol BackendClientProtocol: Sendable {
  
  func login(_ request: LoginRequest) async throws -> LoginResult
  func refresh(refreshToken: Secret) async throws -> BackendTokenResponse
  func fetchMemberInfo(accessToken: Secret) async throws -> MemberInfo
  func logout(refreshToken: Secret) async throws
}

