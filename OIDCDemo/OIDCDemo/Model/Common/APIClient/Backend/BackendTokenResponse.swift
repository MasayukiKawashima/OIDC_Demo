//
//  BackendTokenResponse.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/04.
//

import Foundation

/// バックエンドが発行した自社のトークン一式（レスポンスの形のまま）。
/// 有効期限は発行時点からの秒数なので、保存するときは sessionTokens(issuedAt:) で SessionTokens に変換する。
///バックエンドから返された有効故期限は「発行してから後何秒有効か」だが、このままKeychainに保存すると「いつから数えた秒数か」が分からなくなるので、受け取った時点で絶対時刻に変えて保存する。
nonisolated struct BackendTokenResponse: Sendable {
    let accessToken: Secret
    let refreshToken: Secret
    /// アクセストークンの有効期間（秒）。バックエンドは「あと何秒有効か」を返す
    let expiresIn: TimeInterval

    func sessionTokens(issuedAt: Date = Date()) -> SessionTokens {
        SessionTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
            // ここで絶対時刻に変換する
            // issuedAt（発行時間）にexpiresIn（後何秒有効か）を足して（addingTimeInterval）、
            // いつまで有効か（expiresAt）を求める
            expiresAt: issuedAt.addingTimeInterval(expiresIn)
        )
    }
}
