//
//  SHA256Hasher.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/08.
//

import CryptoKit
import Foundation

/// モックのトークン・sub の記録や、PKCE の code_challenge の計算に使う
nonisolated enum SHA256Hasher {
  /// 文字列（UTF-8）の SHA-256 ハッシュ値を、base64url の文字列で返す。
  /// Digest = ハッシュ化された値（ハッシュ値）
  static func base64URLDigest(of string: String) -> String {
    let digest = SHA256.hash(data: Data(string.utf8))
    return Base64URL.encode(Data(digest))
  }
}
