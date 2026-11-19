//
//  FormURLEncoding.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/19.
//

import Foundation
/// Googleに POSTでデータを送るときにリクエストボディを生成するモジュール
/// application/x-www-form-urlencoded 形式のボディを作る（トークン交換、失効などで使用）。
/// application/x-www-form-urlencoded はOAuthで定められている認可サーバーにPOSTするときの形式。
///
/// ⚫︎変換サンプル
/// FormURLEncoding.encode([("redirect_uri", "com.example.app:/oauth2redirect"),("code", "ab/cd+ef"),])
/// ↓ mapで各値を=付き変換をする
/// redirect_uri=com.example.app%3A%2Foauth2redirect
/// code=ab%2Fcd%2Bef
/// ↓joinedで各値を繋げる
/// redirect_uri=com.example.app%3A%2Foauth2redirect&code=ab%2Fcd%2Bef
nonisolated enum FormURLEncoding {

  /// エンコードしない文字（非予約文字。英数字と -._~ だけ）。
  /// urlQueryAllowed は / や + をそのまま通すため使わない。
  private static let unreserved = CharacterSet(
    charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
  )

  /// 名前と値の組を、順番どおりに name=value&name=value の形にして Data で返す。
  /// 辞書ではなく配列で受け取るのは、送る順番を呼び出し側で決められるようにするため。
  static func encode(_ fields: [(name: String, value: String)]) -> Data {
    let body = fields
      .map { "\(escape($0.name))=\(escape($0.value))" }
      .joined(separator: "&")
    return Data(body.utf8)
  }

  private static func escape(_ string: String) -> String {
    // addingPercentEncoding が nil を返すのは、文字列が UTF-8 に変換できない場合だけ（Swift の String では起きない）
    guard let escaped = string.addingPercentEncoding(withAllowedCharacters: unreserved) else {
      preconditionFailure("フォームの値をエンコードできない")
    }
    return escaped
  }
}
