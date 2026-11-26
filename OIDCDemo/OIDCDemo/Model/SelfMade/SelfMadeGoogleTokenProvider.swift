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
  // ブラウザで Safari と Cookie を共有しない（エフェメラル）かどうか
  private let prefersEphemeral: Bool

  // MARK: - Init
  init(discoveryClient: any GoogleDiscoveryClientProtocol = GoogleDiscoveryClient(), prefersEphemeral: Bool) {
    self.discoveryClient = discoveryClient
    self.prefersEphemeral = prefersEphemeral
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

    // リダイレクト URI。認可リクエストとトークン交換で使用
    let redirectURI = "\(AppConfig.googleReversedClientID):/oauth2redirect"
    // 認可リクエストを行うための環境構築
    let authorizationSession = GoogleAuthorizationSession(authorizationEndpoint: googleEndpoints.authorizationEndpoint,
                                                          redirectURI: redirectURI,
                                                          state: state,
                                                          nonce: nonce,
                                                          codeChallenge: pkce.challenge,
                                                          codeChallengeMethod: pkce.method,
                                                          prefersEphemeral: prefersEphemeral)
    // 認可リクエスト開始。ブラウザでサインイン・同意してもらい、戻りのURLを受け取る
    let callBackURI = try await authorizationSession.start()


    let idToken = Secret("test")
    let accessToken = Secret("test")
    return GoogleTokens(idToken: idToken, accessToken: accessToken)
  }
}
