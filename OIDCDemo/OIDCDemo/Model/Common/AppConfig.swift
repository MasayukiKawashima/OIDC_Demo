//
//  AppConfig.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/09.
//

import Foundation

/// アプリの設定値（Info.plist から読む）。Info.plist を読むのはこの型だけにする。
nonisolated enum AppConfig {
    /// Google の OAuth クライアントの client_id（Info.plist の GoogleClientID）
    static let googleClientID: String = readRequired("GoogleClientID")

    /// Info.plist から必須の値を読む。正しく設定されていなければ、起動時に止める。
    /// - 値がない：Info.plist にキーがない
    /// - 空：Config.xcconfig に値がない
    /// - "$(" で始まる：プロジェクトに Config.xcconfig が指定されておらず、変数が展開されていない
    private static func readRequired(_ key: String) -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
              !value.isEmpty,
              !value.hasPrefix("$(")
        else {
            preconditionFailure("\(key) が設定されていません。Config.xcconfig を確認してください")
        }
        return value
    }
}
