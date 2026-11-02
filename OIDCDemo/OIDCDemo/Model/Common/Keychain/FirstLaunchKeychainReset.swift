//
//  FirstLaunchKeychainReset.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/03.
//

import Foundation

/// インストール後の初回起動で、前のインストールの Keychain の項目を削除する。
/// - iOS ではアプリを削除しても Keychain の項目は残るが、UserDefaults は消える。
///   そのため「初回起動済み」フラグがない起動を、インストール直後とみなす
/// - 初回インストールと再インストールは区別しない（初回なら消えるものがないだけ）
nonisolated enum FirstLaunchKeychainReset {
    /// UserDefaults に保存するフラグのキー（UserDefaults はこのフラグにだけ使う）
    private static let launchedKey = "hasCompletedFirstLaunch"

    /// Keychain を読むどの処理よりも先に呼ぶ。
    /// - Returns: 前のインストールのデータが残っていない状態なら true。
    ///   削除に失敗した場合は false（呼び出し側は、Keychain からのログイン状態の復元を行わない）
    @discardableResult
    static func run(defaults: UserDefaults = .standard) -> Bool {
        // いつもの起動：すでに削除済み
        guard !defaults.bool(forKey: launchedKey) else { return true }

        do {
            // 種類を問わず、このアプリの Keychain の項目をすべて削除する
            try AllKeychainItemsEraser.erase()
            // 削除に成功したときだけフラグを立てる（先に立てると、失敗したときに二度と削除されない）
            defaults.set(true, forKey: launchedKey)
            return true
        } catch let error as KeychainError {
            // フラグは立てない（次回の起動でもう一度削除を試みる）
            return false
        } catch {
            return false
        }
    }
}

