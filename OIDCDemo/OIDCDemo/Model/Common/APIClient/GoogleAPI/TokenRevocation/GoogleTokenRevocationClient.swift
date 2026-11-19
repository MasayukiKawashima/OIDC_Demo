//
//  GoogleTokenRevocationClient.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/19.
//

import Foundation

nonisolated struct GoogleTokenRevocationClient: GoogleTokenRevocationClientProtocol {

  // リクエストにトークンが含まれるため、キャッシュなどを残さない .ephemeral にする
  private let session = URLSession(configuration: .ephemeral)

  /// トークン失効のエンドポイント。
  private static let endpoint = URL(string: "https://oauth2.googleapis.com/revoke")!

  func revoke(token: Secret) async throws {
    // トークンを URL に入れないため、クエリではなくフォーム形式のボディで送る
    var request = URLRequest(url: Self.endpoint)
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

    // JSONではなくapplication/x-www-form-urlencoded 形式にする
    request.httpBody = FormURLEncoding.encode([("token", token.reveal())])

    let response: URLResponse
    do {
      (_, response) = try await session.data(for: request)
    } catch {
      print("[Revoke] 失敗（通信エラー：\(type(of: error))）")
      throw GoogleTokenRevocationError.network
    }

    guard let http = response as? HTTPURLResponse else {
      throw GoogleTokenRevocationError.invalidResponse
    }
    guard http.statusCode == 200 else {
      print("[Revoke] 失敗（\(http.statusCode)）")
      throw GoogleTokenRevocationError.unexpectedStatus(http.statusCode)
    }
    print("[Revoke] 成功")
  }
}
