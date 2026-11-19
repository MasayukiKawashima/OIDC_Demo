//
//  GoogleProfileClientProtocol.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/15.
//

import Foundation

nonisolated protocol GoogleProfileClientProtocol: Sendable {
    /// Google のアクセストークンで、本人の表示名を取得する。
    func fetchDisplayName(accessToken: Secret) async throws -> String
}
