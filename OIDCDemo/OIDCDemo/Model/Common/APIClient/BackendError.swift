//
//  BackendError.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/04.
//

import Foundation

nonisolated enum BackendError: Error {
  
    case invalidIDToken
    /// 会員情報など：アクセストークンが無効（期限切れなど）。HTTP の 401 に当たる
    case unauthorized
    /// リフレッシュ：リフレッシュトークンが無効（期限切れ、失効済みなど）。ログインし直しが必要
    case invalidRefreshToken
}
