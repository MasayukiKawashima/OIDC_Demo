//
//  SessionTokenStore.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/03.
//
import Foundation


// MARK: - SessionTokenStore

/// 自社のトークン一式を、Keychain の1項目（JSON）として保存・読み出し・削除する
nonisolated struct SessionTokenStore: Sendable {

  private let keychain: KeychainGenericPasswordStore
  private static let account = "session_tokens"

  init(service: KeychainService) {
    keychain = KeychainGenericPasswordStore(service: service)
  }

  // MARK: - 保存

  /// アクセス、リフレッシュトークン、期限をPayload構造体にまとめ、JSONにエンコードして保存
  func save(_ tokens: SessionTokens) throws {

    let payload = Payload(
      accessToken: tokens.accessToken.reveal(),
      refreshToken: tokens.refreshToken.reveal(),
      expiresAt: tokens.expiresAt
    )

    let data = try JSONEncoder().encode(payload)
    try keychain.save(data, account: Self.account)
  }

  // MARK: - 読み込み

  func load() throws -> SessionTokens? {

    guard let data = try keychain.load(account: Self.account) else { return nil }
    let payload = try JSONDecoder().decode(Payload.self, from: data)
    // 読み出したらすぐに Secret で包む
    return SessionTokens(
      accessToken: Secret(payload.accessToken),
      refreshToken: Secret(payload.refreshToken),
      expiresAt: payload.expiresAt
    )
  }

  // MARK: - 削除

  func delete() throws {
    try keychain.delete(account: Self.account)
  }


  // MARK: - Payload
  /// Keychain との変換にだけ使う、値をそのまま持つ型
  /// SessionTokenStore以外ではそれぞれの値をSecretに包むため、この型はSessionTokenStore内でのみ利用可能にするために、
  /// ネストしてプライベートな型にする
  nonisolated private struct Payload: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
  }
}
