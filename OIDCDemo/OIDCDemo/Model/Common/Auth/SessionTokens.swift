//
//  SessionTokens.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/03.
//

import Foundation

/// 自社のトークン一式（バックエンド＝モックが発行したもの）
nonisolated struct SessionTokens: Sendable {

    let accessToken: Secret
    let refreshToken: Secret
    /// アクセストークンの有効期限（絶対時刻）。expires_in から計算して保存する
    let expiresAt: Date
}
