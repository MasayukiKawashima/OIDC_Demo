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
    print("SelfMadeGoogleTokenProviderのfetchVerifiedTokensが呼ばれた")

    let googleEndpoints = try await discoveryClient.fetchEndpoints()

    let idToken = Secret("test")
    let accessToken = Secret("test")
    return GoogleTokens(idToken: idToken, accessToken: accessToken)
  }
}
