//
//  BackendClientProtocol.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/04.
//
import Foundation

nonisolated protocol BackendClientProtocol: Sendable {
  
  func signIn(_ request: SignInRequest) async throws -> SignInResult
  func refresh(refreshToken: Secret) async throws -> BackendTokenResponse
  func fetchMemberInfo(accessToken: Secret) async throws -> MemberInfo
  func signOut(refreshToken: Secret) async throws
}

