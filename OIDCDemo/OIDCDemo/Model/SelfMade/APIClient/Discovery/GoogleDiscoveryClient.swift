//
//  GoogleDiscoveryClient.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/23.
//

import Foundation

/// Discovery ドキュメントを取得し、確認済みのエンドポイント（GoogleEndpoints）を返す。
nonisolated struct GoogleDiscoveryClient: GoogleDiscoveryClientProtocol {

  // MARK: - Properties

  // サインインのたびに Discovery ドキュメントを取得するため、キャッシュを使わないようにする
  private let session: URLSession = {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.urlCache = nil
    return URLSession(configuration: configuration)
  }()

  private let discoveryURL = URL(string: "https://accounts.google.com/.well-known/openid-configuration")!
  private let expectedIssuer = "https://accounts.google.com"

  // MARK: - fetchEndpoints

  func fetchEndpoints() async throws -> GoogleEndpoints {

    let request = URLRequest(url: discoveryURL)

    let data: Data
    let response: URLResponse

    do {
      (data, response) = try await session.data(for: request)
    } catch {
      print("[Discovery] 失敗（通信エラー：\(type(of: error))）")
      throw GoogleDiscoveryError.network
    }
    // この後：ステータスの確認 → デコード → issuer と https の確認 → GoogleEndpoints を返す
    // ステータス確認
    guard let http = response as? HTTPURLResponse else {
      throw GoogleDiscoveryError.invalidResponse
    }

    switch http.statusCode {
    case 200:
      break
    default:
      print("[Discovery] 失敗（\(http.statusCode)）")
      throw GoogleDiscoveryError.unexpectedStatus(http.statusCode)
    }
    // DiscoveryDocumentへのデコード
    let document: DiscoveryDocument
    do {
      document = try JSONDecoder().decode(DiscoveryDocument.self, from: data)
    } catch {
      print("[Discovery] 失敗（レスポンスを読めない）")
      throw GoogleDiscoveryError.invalidResponse
    }

    // ドキュメント内容の検証
    try validateIssuer(of: document)
    let urls = try validateEndpoints(of: document)
    //GoogleEndpointsへの変換とreturn
    print("[Discovery] GoogleEndpointsの取得成功")
    return GoogleEndpoints(authorizationEndpoint: urls.authorizationEndpoint, tokenEndpoint: urls.tokenEndpoint)
  }

  // MARK: - HelperMethods

  // issuer が期待した値と完全に一致することを確認する。
  private func validateIssuer(of document: DiscoveryDocument) throws {
    guard document.issuer == expectedIssuer else {
      print("[Discovery] issuer: 一致しない")
      throw GoogleDiscoveryError.invalidIssuer
    }
  }
  // 各エンドポイントが https の URL であることを確認し、変換済みの URL を返す。
  private func validateEndpoints(of document: DiscoveryDocument) throws -> (authorizationEndpoint: URL, tokenEndpoint: URL) {
    let authorizationEndpoint = try httpsURL(from: document.authorizationEndpoint, name: "authorization_endpoint")
    let tokenEndpoint = try httpsURL(from: document.tokenEndpoint, name: "token_endpoint")
    return (authorizationEndpoint, tokenEndpoint)
  }

  // 文字列を URL に変換し、https でホストがあることを確認する。
  private func httpsURL(from string: String, name: String) throws -> URL {
    guard let url = URL(string: string),
          url.scheme?.lowercased() == "https",
          url.host() != nil else {
      print("[Discovery] \(name): https の URL ではない")
      throw GoogleDiscoveryError.invalidEndpoint
    }
    return url
  }
}
