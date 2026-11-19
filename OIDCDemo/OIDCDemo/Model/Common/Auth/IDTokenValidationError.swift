//
//  IDTokenValidationError.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/19.
//

import Foundation

/// IDトークンの確認に失敗したときのエラー。期待した値や実際の値は含めない。
nonisolated enum IDTokenValidationError: Error {
  /// 3つに分かれていない、ペイロードを読めない、必要なクレームがない
  case malformed
  case invalidIssuer
  case invalidAudience
  case expired
  /// nonce がない、または一致しない
  case nonceMismatch
}
