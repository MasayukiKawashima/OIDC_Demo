//
//  GoogleTokenRevocationClientProtocol.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/19.
//

import Foundation

nonisolated protocol GoogleTokenRevocationClientProtocol: Sendable {
  /// Google のトークンを失効させる。
  /// アクセストークンを渡すと、対応するリフレッシュトークンもあわせて無効になる。
  func revoke(token: Secret) async throws
}
