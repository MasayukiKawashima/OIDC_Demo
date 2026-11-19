//
//  IDTokenValidator.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/19.
//

import Foundation

/// IDトークンのクレーム（iss・aud・exp・nonce）を確認する。自前実装と AppAuth版で共通に使う。
/// 署名の検証と JWKS の取得は行わない（バックエンドが行う想定。本プロジェクトのモックも署名は検証しない）。
nonisolated struct IDTokenValidator: Sendable {

  /// Google の IDトークンの iss として受け付ける値（Google のドキュメントで2種類とされている）
  private static let allowedIssuers: Set<String> = ["https://accounts.google.com", "accounts.google.com"]

  /// aud として受け付ける値（アプリの client_id）
  private let expectedAudience: String

  /// - Parameter expectedAudience: アプリの client_id。呼び出し側で AppConfig.googleClientID を渡す
  init(expectedAudience: String) {
    self.expectedAudience = expectedAudience
  }

  /// IDトークンを確認する。1つでも通らなければエラーを投げる。
  /// - Parameters:
  ///   - idToken: トークン交換で受け取った IDトークン
  ///   - expectedNonce: 認可リクエストで送った nonce（サインインのたびに作る値）
  func validate(_ idToken: Secret, expectedNonce: String) throws {
    let claims = try decodeClaims(of: idToken)

    guard Self.allowedIssuers.contains(claims.iss) else {
      print("[IDToken] iss: NG")
      throw IDTokenValidationError.invalidIssuer
    }
    print("[IDToken] iss: OK")

    guard claims.aud == expectedAudience else {
      print("[IDToken] aud: NG")
      throw IDTokenValidationError.invalidAudience
    }
    print("[IDToken] aud: OK")

    guard Date() < Date(timeIntervalSince1970: claims.exp) else {
      print("[IDToken] exp: NG")
      throw IDTokenValidationError.expired
    }
    print("[IDToken] exp: OK")

    // nonce は、攻撃者が比較にかかる時間を繰り返し測れる場所で照合するものではないため、== で比べる
    guard let nonce = claims.nonce, nonce == expectedNonce else {
      print("[IDToken] nonce: NG")
      throw IDTokenValidationError.nonceMismatch
    }
    print("[IDToken] nonce: OK")
  }

  /// IDトークン（ヘッダー.ペイロード.署名）からペイロードを取り出してデコードする。
  private func decodeClaims(of idToken: Secret) throws -> Claims {
    let parts = idToken.reveal().split(separator: ".", omittingEmptySubsequences: false)
    guard parts.count == 3,
          let payload = Base64URL.decode(String(parts[1])),
          let claims = try? JSONDecoder().decode(Claims.self, from: payload)
    else {
      print("[IDToken] 読み取り: NG")
      throw IDTokenValidationError.malformed
    }
    return claims
  }

  /// 確認に使うクレームだけを定義する（sub や name は読まない）。
  private struct Claims: Decodable {
    let iss: String
    /// 仕様上は配列のこともあるが、Google の IDトークンでは文字列。配列だった場合はデコードに失敗し、malformed になる
    let aud: String
    /// 有効期限（1970年1月1日からの秒数）
    let exp: TimeInterval
    /// nonce がない場合も失敗にするため、ここでは Optional にして validate で確かめる
    let nonce: String?
  }
}
