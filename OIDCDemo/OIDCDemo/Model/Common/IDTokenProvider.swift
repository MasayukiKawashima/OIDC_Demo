//
//  GoogleTokenProvider.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/14.
//

import Foundation

/// Google から確認済みの IDトークンを得る部分。自前実装（フェーズ3）と AppAuth版（フェーズ5）で違うのはここだけ。
/// ASWebAuthenticationSession など、画面に関わる処理を使うため MainActor にする。
@MainActor
protocol GoogleTokenProvider {
    /// Google でログインし、確認済み（iss・aud・exp・nonce）の IDトークンを返す。
    /// Google のアクセストークンなどは返さず、この中で破棄する。
    func fetchVerifiedIDToken() async throws -> Secret
}
