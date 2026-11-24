//
//  SelfMadeGoogleTokenProvider.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/20.
//

import Foundation

struct SelfMadeGoogleTokenProvider: GoogleTokenProvider {

  // MARK: - Properties

  private let discoveryClient: any GoogleDiscoveryClientProtocol

    // MARK: - Init
  init(discoveryClient: any GoogleDiscoveryClientProtocol = GoogleDiscoveryClient()) {
    self.discoveryClient = discoveryClient
  }

  // MARK: - fetchVerifiedTokens

  func fetchVerifiedTokens() async throws -> GoogleTokens {

    // ディスカバリへのリクエスト。各種エンドポイントを取得。
    let googleEndpoints = try await discoveryClient.fetchEndpoints()

    // stateとnonceの作成
    let state = try SecureRandom.base64URLString(byteCount: 32)
    let nonce = try SecureRandom.base64URLString(byteCount: 32)

    // PKCEの構成
    let pkce: PKCE = try PKCE()


    let idToken = Secret("test")
    let accessToken = Secret("test")
    return GoogleTokens(idToken: idToken, accessToken: accessToken)
  }
}
