//
//  GoogleTokens.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/15.
//

import Foundation

/// Google から得た、確認済みの IDトークンとアクセストークン。
nonisolated struct GoogleTokens: Sendable {
  let idToken: Secret
  let accessToken: Secret
}
