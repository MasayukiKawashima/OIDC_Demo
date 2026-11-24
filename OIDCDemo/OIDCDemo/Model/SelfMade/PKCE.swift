//
//  PKCE.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/24.
//

import Foundation

nonisolated struct PKCE: Sendable {

  // MARK: - Properties

  let verifier: Secret
  /// code_challenge
  let challenge: String
  /// code_challenge_method
  let method = "S256"

  // MARK: - Init

  init() throws {
    let verifierValue = try SecureRandom.base64URLString(byteCount: 32)
    verifier = Secret(verifierValue)
    challenge = SHA256Hasher.base64URLDigest(of: verifierValue)
  }
}
