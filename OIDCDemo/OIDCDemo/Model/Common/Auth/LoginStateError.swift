//
//  LoginStateError.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/09.
//

import Foundation

nonisolated enum LoginStateError: Error {
    /// ログインしていない（トークンがない）
    case notSignedIn
    /// セッションが無効になった（リフレッシュに失敗した）。トークンは削除済みで、ログインし直しが必要
    case sessionExpired
    /// バックエンドがログインを受け付けなかった（IDトークンの検証に失敗した）
    case loginRejected
}
