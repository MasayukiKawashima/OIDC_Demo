//
//  GoogleTokenProvider.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/15.
//

import Foundation


/// Google からトークンを得る部分。自前実装（フェーズ3）と AppAuth版（フェーズ5）で違うのはここだけ。
/// ASWebAuthenticationSession など、画面に関わる処理を使うため MainActor にする。
@MainActor
protocol GoogleTokenProvider {
    /// Google でサインインし、確認済み（iss・aud・exp・nonce）の IDトークンとアクセストークンを返す。
    func fetchVerifiedTokens() async throws -> GoogleTokens
}
