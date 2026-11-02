//
//  AllKeychainItemsEraser.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/03.
//

import Foundation
import Security

/// このアプリの Keychain の項目を、種類（generic password、鍵、証明書など）を問わずすべて削除する。
/// - 全消去専用。保存先（service）や項目（account）単位の削除は、KeychainGenericPasswordStore などの各部品で行う
/// - 再インストール後の初回起動や、「Keychainのデータを削除」ボタンで使う
/// - 注意：アクセスグループを指定しないため、Keychain Sharing を設定した場合は、
///   共有しているアクセスグループの項目も削除対象になる
nonisolated enum AllKeychainItemsEraser {

    /// Keychain項目の全種類を指定
    private static let allClasses: [CFString] = [
        kSecClassGenericPassword,
        kSecClassInternetPassword,
        kSecClassCertificate,
        kSecClassKey,
        kSecClassIdentity,
    ]

    /// すべての種類の項目を削除する。項目がなくても成功として扱う。
    /// 途中で失敗しても残りの種類の削除は続け、最初に起きたエラーを最後に投げる。
    static func erase() throws {
        var firstError: KeychainError?
        for itemClass in allClasses {
            let query: [String: Any] = [kSecClass as String: itemClass]
            let status = SecItemDelete(query as CFDictionary)
            if status != errSecSuccess && status != errSecItemNotFound && firstError == nil {
                firstError = .unexpectedStatus(status)
            }
        }
        if let firstError {
            throw firstError
        }
    }
}
