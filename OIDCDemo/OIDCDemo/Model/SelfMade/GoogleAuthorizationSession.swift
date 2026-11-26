//
//  GoogleAuthorizationSession.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/26.
//

import Foundation

/// 認可リクエストを行うクラス
final class GoogleAuthorizationSession: NSObject {

  // MARK: - Properties

  private let authorizationEndpoint: URL
  private let redirectURI: String
  private let state: String
  private let nonce: String
  private let codeChallenge: String
  private let codeChallengeMethod: String
  private let prefersEphemeral: Bool

  private var continuation: CheckedContinuation<URL, any Error>?
  private var anchor: ASPresentationAnchor?

    // MARK: - Init

  init(
    authorizationEndpoint: URL,
    redirectURI: String,
    state: String,
    nonce: String,
    codeChallenge: String,
    codeChallengeMethod: String,
    prefersEphemeral: Bool = false
  ) {
    self.authorizationEndpoint = authorizationEndpoint
    self.redirectURI = redirectURI
    self.state = state
    self.nonce = nonce
    self.codeChallenge = codeChallenge
    self.codeChallengeMethod = codeChallengeMethod
    self.prefersEphemeral = prefersEphemeral
  }

  // MARK: - Methods

  /// リクエスト組み立て
  private func authorizationRequestURL() throws -> URL {
    // ベース
    guard var urlComponents = URLComponents(url: authorizationEndpoint, resolvingAgainstBaseURL: false) else {
      throw GoogleAuthorizationError.invalidAuthorizationURL
    }

    // パラメータ
    let parameters = [
      URLQueryItem(name: "client_id", value: AppConfig.googleClientID),
      URLQueryItem(name: "redirect_uri", value: redirectURI),
      URLQueryItem(name: "response_type", value: "code"),
      URLQueryItem(name: "scope", value: "openid profile"),
      URLQueryItem(name: "state", value: state),
      URLQueryItem(name: "nonce", value: nonce),
      URLQueryItem(name: "code_challenge", value: codeChallenge),
      URLQueryItem(name: "code_challenge_method", value: codeChallengeMethod),
    ]

    // パラメータ埋め込み
    urlComponents.queryItems = (urlComponents.queryItems ?? []) + parameters

    guard let url = urlComponents.url else {
      throw GoogleAuthorizationError.invalidAuthorizationURL
    }
    return url
  }
}
