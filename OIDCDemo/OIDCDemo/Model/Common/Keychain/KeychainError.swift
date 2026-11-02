//
//  KeychainError.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/02.
//

import Foundation

/// Keychain の操作に失敗したときのエラー。値そのものは含めない。
nonisolated enum KeychainError: Error {
  case unexpectedStatus(OSStatus)
  case unexpectedData
}
