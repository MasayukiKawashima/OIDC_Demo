//
//  GoogleDiscoveryClient.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/23.
//

import Foundation

/// Discovery ドキュメントを取得し、確認済みのエンドポイント（GoogleEndpoints）を返す。
nonisolated struct GoogleDiscoveryClient: GoogleDiscoveryClientProtocol {

  // サインインのたびに Discovery ドキュメントを取得するため、キャッシュを使わないようにする
  private let session: URLSession = {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.urlCache = nil
    return URLSession(configuration: configuration)
  }()

  private let DiscoveryURL = URL(string: "https://accounts.google.com/.well-known/openid-configuration")!

  func fetchEndpoints() async throws -> GoogleEndpoints {

    let request = URLRequest(url: DiscoveryURL)

    let data: Data
    let response: URLResponse

    do {
      (data, response) = try await session.data(for: request)
    } catch {
      print("[Discovery] 失敗（通信エラー：\(type(of: error))）")
      throw GoogleDiscoveryError.network
    }
    // この後：ステータスの確認 → デコード → issuer と https の確認 → GoogleEndpoints を返す
  }
}
