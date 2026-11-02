//
//  KeychainGenericPasswordStore.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/02.
//

import Foundation
import Security


// MARK: - KeychainGenericPasswordStore

/// - Keychain の generic password を、service ごとに保存・読み出し・削除するモデル
/// - SessionTokenStoreやモックへのデータ保存で利用する
nonisolated struct KeychainGenericPasswordStore: Sendable {

  // 保存する値が属するサービス
  // サービスはselfMade（自前実装）、appAuth、mockの三つ
  let service: KeychainService

  /// この部品で保存する項目の保護レベル。
  /// AfterFirstUnlock：再起動後、最初にロックを解除するまでは読めない。一度解除すれば、画面ロック中でも読める
  /// ThisDeviceOnly：この端末でだけ使える。バックアップから別の端末に復元しても移らない
  private static let accessibility = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

  init(service: KeychainService) {
    self.service = service
  }


  // MARK: - 保存

  func save(_ data: Data, account: String) throws {

    // クエリの作成
    var addQuery = genericPasswordItemQuery(account: account)
    addQuery[kSecValueData as String] = data
    addQuery[kSecAttrAccessible as String] = Self.accessibility

    // 保存実行
    let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
    switch addStatus {
      // 初回保存時には特に何もしない
    case errSecSuccess:
      return
    case errSecDuplicateItem:
      // すでにある場合は、値と保護レベルを更新する
      // 保護レベルは現在（2026.11)の実装だとkSecAttrAccessibleAfterFirstUnlockThisDeviceOnly以外は設定されないが、
      // 将来の仕様変更に備え、このメソッドがよばれるたびにkSecAttrAccessibleAfterFirstUnlockThisDeviceOnlyに設定されるようにする
      let attributes: [String: Any] = [
        kSecValueData as String: data,
        kSecAttrAccessible as String: Self.accessibility,
      ]
      let updateStatus = SecItemUpdate(genericPasswordItemQuery(account: account) as CFDictionary,
                                       attributes as CFDictionary)
      guard updateStatus == errSecSuccess else {
        throw KeychainError.unexpectedStatus(updateStatus)
      }
    default:
      throw KeychainError.unexpectedStatus(addStatus)
    }
  }


  // MARK: - 読み込み

  func load(account: String) throws -> Data? {

    // クエリの作成
    var query = genericPasswordItemQuery(account: account)
    // 検索結果に実際のデータを含めるかどうかの設定
    query[kSecReturnData as String] = true
    // 取得するのはヒットした結果の最初の一件のみ
    query[kSecMatchLimit as String] = kSecMatchLimitOne

    var result: CFTypeRef?

    // クエリの条件に合うデータの検索
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    switch status {
      // 条件に合うデータが見つかった場合
    case errSecSuccess:
      guard let data = result as? Data else { throw KeychainError.unexpectedData }
      return data

    case errSecItemNotFound:
      return nil
    default:
      throw KeychainError.unexpectedStatus(status)
    }
  }


  // MARK: - 単データ削除

  func delete(account: String) throws {
    let status = SecItemDelete(genericPasswordItemQuery(account: account) as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw KeychainError.unexpectedStatus(status)
    }
  }


  // MARK: - 指定サービス内の全データの削除

  func deleteAll() throws {
    let status = SecItemDelete(genericPasswordServiceQuery() as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw KeychainError.unexpectedStatus(status)
    }
  }


  // MARK: - HelperMethods

  /// generic password の1項目（service と account で特定）を指すクエリの作成メソッド
  private func genericPasswordItemQuery(account: String) -> [String: Any] {
    [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service.name,
      kSecAttrAccount as String: account,
    ]
  }

  /// この service の generic password の全項目を指すクエリの作成メソッド
  private func genericPasswordServiceQuery() -> [String: Any] {
    [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service.name,
    ]
  }
}
