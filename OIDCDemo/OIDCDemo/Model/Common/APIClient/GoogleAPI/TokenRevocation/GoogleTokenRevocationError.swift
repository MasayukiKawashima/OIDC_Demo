//
//  GoogleTokenRevocationError.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/19.
//

import Foundation

/// 失効に失敗したときのエラー。トークンやレスポンスのボディは含めない。
nonisolated enum GoogleTokenRevocationError: Error {
  case network
  case invalidResponse
  /// 200 以外（400 は、トークンが無効か失効済みの場合に返る）
  case unexpectedStatus(Int)
}
