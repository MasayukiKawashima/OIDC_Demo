//
//  SelfMadeGoogleTokenProvider.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/20.
//

import Foundation

struct SelfMadeGoogleTokenProvider: GoogleTokenProvider {

  func fetchVerifiedTokens() async throws -> GoogleTokens {
    print("SelfMadeGoogleTokenProviderのfetchVerifiedTokensが呼ばれた")

    let idToken = Secret("test")
    let accessToken = Secret("test")
    return GoogleTokens(idToken: idToken, accessToken: accessToken)
  }
}
