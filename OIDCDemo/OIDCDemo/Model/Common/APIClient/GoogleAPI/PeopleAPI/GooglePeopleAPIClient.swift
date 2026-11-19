//
//  GooglePeopleAPIClient.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/15.
//

import Foundation

nonisolated struct GooglePeopleAPIClient: GoogleProfileClientProtocol {

  // レスポンスのキャッシュを残さないために.ephemeralに設定
  private let session = URLSession(configuration: .ephemeral)

  // 名前の取得
  func fetchDisplayName(accessToken: Secret) async throws -> String {

    // リクエスト組み立て
    var components = URLComponents(string: "https://people.googleapis.com/v1/people/me")!
    components.queryItems = [URLQueryItem(name: "personFields", value: "names")]

    var request = URLRequest(url: components.url!)
    let authorization = "Bearer " + accessToken.reveal()
    request.setValue(authorization, forHTTPHeaderField: "Authorization")

    let data: Data
    let response: URLResponse

    // 実行
    do {
      (data, response) = try await session.data(for: request)
    } catch {
      print("[People] names: 失敗（通信エラー：\(type(of: error))）")
      throw GoogleProfileError.network
    }

    // ステータスコード解析とハンドリング
    guard let http = response as? HTTPURLResponse else {
      throw GoogleProfileError.invalidResponse
    }
    switch http.statusCode {
    case 200:
      break
    case 401:
      print("[People] names: 失敗（401）")
      throw GoogleProfileError.unauthorized
    case 403:
      print("[People] names: 失敗（403）")
      throw GoogleProfileError.forbidden
    default:
      print("[People] names: 失敗（\(http.statusCode)）")
      throw GoogleProfileError.unexpectedStatus(http.statusCode)
    }

    // 成功したらレスポンスデータ解析
    guard let person = try? JSONDecoder().decode(Person.self, from: data) else {
      print("[People] names: 失敗（レスポンスを読めない）")
      throw GoogleProfileError.invalidResponse
    }

    // PeopleAPIの使用に合わせて改正
    let profileName = person.names?.first {
      $0.metadata?.primary == true && $0.metadata?.source?.type == "PROFILE"
    }
    guard let name = profileName?.displayName, !name.isEmpty else {
      print("[People] names: 失敗（名前なし）")
      throw GoogleProfileError.nameNotFound
    }
    print("[People] names: 取得できた")

    // 最終的にString型のnameを返す
    return name
  }

  private struct Person: Decodable {
    let names: [Name]?
  }
  private struct Name: Decodable {
    let displayName: String?
    let metadata: Metadata?
  }
  private struct Metadata: Decodable {
    let primary: Bool?
    let source: Source?
  }
  private struct Source: Decodable {
    let type: String?
  }
}
