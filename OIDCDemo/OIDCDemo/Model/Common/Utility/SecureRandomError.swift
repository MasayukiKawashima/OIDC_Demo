//
//  SecureRandomError.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/25.
//

import Foundation

/// 乱数の生成に失敗したときのエラー。
nonisolated enum SecureRandomError: Error {
  case failed(OSStatus)
}
