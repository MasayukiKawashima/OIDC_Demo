//
//  BackendClient.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/08.
//

import Foundation

/// 本物のアプリで URLSession を使ってサーバーに要求を送る部分と同じ立場で、
/// 要求を MockBackendServer に渡し、結果を受け取って返す。
actor BackendClient: BackendClientProtocol {
    /// 要求を送る先（本物ならサーバーの URL）
    private let server: MockBackendServer
    /// 通信を模した待ち時間
    private let latency: Duration

    /// - Parameters:
    ///   - server: 要求を送る先のモックのバックエンド
    ///   - latency: 通信を模した待ち時間
    init(server: MockBackendServer, latency: Duration = .milliseconds(300)) {
        self.server = server
        self.latency = latency
    }

    func login(idToken: Secret) async throws -> LoginResult {
        try await simulateLatency()
        return try await server.handleLogin(idToken: idToken)
    }

    func refresh(refreshToken: Secret) async throws -> BackendTokenResponse {
        try await simulateLatency()
        return try await server.handleRefresh(refreshToken: refreshToken)
    }

    func fetchMemberInfo(accessToken: Secret) async throws -> MemberInfo {
        try await simulateLatency()
        return try await server.handleMemberInfo(accessToken: accessToken)
    }

    func logout(refreshToken: Secret) async throws {
        try await simulateLatency()
        try await server.handleLogout(refreshToken: refreshToken)
    }

    /// 通信を模した待ち時間を入れる。
    private func simulateLatency() async throws {
        if latency > .zero {
            try await Task.sleep(for: latency)
        }
    }
}
