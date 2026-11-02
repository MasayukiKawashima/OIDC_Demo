//
//  KeychainService.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/02.
//

import Foundation

nonisolated enum KeychainService: Sendable {

  /// このプロジェクトではKeychainを使用して、selfMade、appAuth、mockの三つの保存先（サービス名として分類）にデータを保存する
  /// 例えばOIDCの自前実装版では自社トークンをselfMadeというサービス内に保存する
  /// appAuth版ではappAuthというサービス内に保存する
  /// このように実装の種類やデータの性質によって保存先（サービス）を分けて保存する

  /// 自前実装の自社トークンを保存する保存先
  case selfMade
  /// AppAuth版実装の自社トークンの保存先
  case appAuth
  /// モック（バックエンド役）に保存する表示データの保存先
  /// ここには画面に表示するデータを保存する
  /// 今回のプロジェクトではデータベースを含むバックエンドを作らないので、この保存先をバックエンドのデータベースとみたてている
  case mock

#if DEBUG
  /// 動作確認用の一時的な保存先
  /// 処理の確認時などに上記三つのサービスに保存されているデータに影響がいないように専用の保存先を作っている
  case check(String)
#endif

  /// Keychain の kSecAttrService に渡す文字列（例：<バンドルID>.selfmade）
  var name: String {
    let base = Bundle.main.bundleIdentifier ?? "oidcdemo"
    return "\(base).\(suffix)"
  }

  private var suffix: String {
    switch self {
    case .selfMade: return "selfmade"
    case .appAuth: return "appauth"
    case .mock: return "mock"
#if DEBUG
    case .check(let label): return "check-\(label)"
#endif
    }
  }
}
