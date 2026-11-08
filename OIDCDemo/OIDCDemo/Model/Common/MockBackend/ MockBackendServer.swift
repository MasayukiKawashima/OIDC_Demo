//
//   MockBackendServer.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/08.
//

import Foundation

/// モックのバックエンド（サーバー側の処理の代役）。
/// 本物の構成ではサーバーで行う処理を、端末内で簡易的に再現する。
/// - IDトークン：クレーム（iss・aud・exp）だけを確認する。署名は検証しない
/// - 会員：sub のハッシュ値で見分ける（sub そのものは保存しない）
/// - 自社トークン：発行したトークンのハッシュ値だけを記録し、送られてきたトークンと照合する
/// - セッションは1つだけ。ログインのたびに置き換える
/// 署名を検証しないため、本番に含めると偽の IDトークンでログインできてしまう。
actor MockBackendServer {
    private let storage: KeychainGenericPasswordStore
    private let membersAccount = "members"
    private let sessionAccount = "session"

    /// IDトークンの aud として受け付ける値（アプリの client_id）。公開してはいけない値なので出力しない
    private let expectedAudience: String
    /// IDトークンの iss として受け付ける値。Google は2種類の値を使うため、この2つだけを許可する
    private let allowedIssuers: Set<String> = ["https://accounts.google.com", "accounts.google.com"]
    /// 発行するアクセストークンの有効期間（秒）
    private let accessTokenLifetime: TimeInterval

    /// - Parameters:
    ///   - expectedAudience: IDトークンの aud として受け付ける値（アプリの client_id）
    ///   - service: 記録の保存先。通常は .mock（動作確認では .check(...) を渡す）
    ///   - accessTokenLifetime: 発行するアクセストークンの有効期間（秒）
    init(expectedAudience: String,
         service: KeychainService = .mock,
         accessTokenLifetime: TimeInterval = 3600) {
        self.expectedAudience = expectedAudience
        self.storage = KeychainGenericPasswordStore(service: service)
        self.accessTokenLifetime = accessTokenLifetime
    }

    // MARK: - API の処理（本物ならサーバーの各エンドポイントに当たる）

    /// ログイン：IDトークンを確認し、会員を見分けて、新しいセッションを発行する。
    func handleLogin(idToken: Secret) throws -> LoginResult {
        let claims = try verifiedClaims(of: idToken)

        // sub のハッシュ値で会員を見分ける（sub そのものは保存しない）
        let memberKey = SHA256Hasher.base64URLDigest(of: claims.sub)
        var members = try loadMembers()
        let isExisting = members[memberKey] != nil
        members[memberKey] = MockMemberRecord(name: claims.name ?? "（名前なし）", loggedInAt: Date())
        // 会員の記録を先に保存し、セッションはその後に作る（セッションが存在しない会員を指すことがないように）
        try saveMembers(members)

        // 新しいセッションを発行し、前のセッションと置き換える
        let (response, session) = try issueSession(memberKey: memberKey, previousRefreshTokenHash: nil)
        try saveSession(session)

        print("[MockServer] login: 成功（\(isExisting ? "既存会員" : "新規登録")）")
        return LoginResult(tokens: response, memberStatus: isExisting ? .existing : .newlyRegistered)
    }

    /// リフレッシュ：リフレッシュトークンを照合し、新しいトークン一式を発行する（ローテーション）。
    func handleRefresh(refreshToken: Secret) throws -> BackendTokenResponse {
        let presentedHash = SHA256Hasher.base64URLDigest(of: refreshToken.reveal())
        guard let session = try loadSession() else {
            print("[MockServer] refresh: 失敗（セッションがない）")
            throw BackendError.invalidRefreshToken
        }

        if presentedHash == session.refreshTokenHash {
            // ローテーション：新しいトークン一式を発行し、今のリフレッシュトークンは使用済みにする
            let (response, newSession) = try issueSession(memberKey: session.memberKey,
                                                          previousRefreshTokenHash: session.refreshTokenHash)
            try saveSession(newSession)
            print("[MockServer] refresh: 成功（新しいトークン一式を発行）")
            return response
        }

        if presentedHash == session.previousRefreshTokenHash {
            // 再利用の検知：使用済みのリフレッシュトークンが送られてきた。
            // 盗まれて攻撃者と本人の両方が使っている可能性があるため、セッションを無効にする
            try storage.delete(account: sessionAccount)
            print("[MockServer] refresh: 失敗（使用済みのリフレッシュトークン。セッションを無効にした）")
            throw BackendError.invalidRefreshToken
        }

        print("[MockServer] refresh: 失敗（リフレッシュトークンが一致しない）")
        throw BackendError.invalidRefreshToken
    }

    /// 会員情報：アクセストークンを照合し、会員の名前とログイン日時を返す。
    func handleMemberInfo(accessToken: Secret) throws -> MemberInfo {
        let presentedHash = SHA256Hasher.base64URLDigest(of: accessToken.reveal())
        guard let session = try loadSession(), presentedHash == session.accessTokenHash else {
            print("[MockServer] memberInfo: 401（アクセストークンが一致しない）")
            throw BackendError.unauthorized
        }
        guard Date() < session.accessTokenExpiresAt else {
            print("[MockServer] memberInfo: 401（アクセストークンの期限切れ）")
            throw BackendError.unauthorized
        }
        guard let record = try loadMembers()[session.memberKey] else {
            // 会員の記録はセッションより先に保存するため、通常は起こらない。
            // 万一食い違った場合は、壊れたセッションとして無効にし、401 を返す
            //（アプリはリフレッシュに失敗し、ログインし直しになる）
            try storage.delete(account: sessionAccount)
            print("[MockServer] memberInfo: 401（セッションの会員の記録がない。セッションを無効にした）")
            throw BackendError.unauthorized
        }

        print("[MockServer] memberInfo: 成功（会員情報を返した）")
        return MemberInfo(name: record.name, loggedInAt: record.loggedInAt)
    }

    /// ログアウト：リフレッシュトークンが一致すれば、セッションを無効にする。
    func handleLogout(refreshToken: Secret) throws {
        let presentedHash = SHA256Hasher.base64URLDigest(of: refreshToken.reveal())
        if let session = try loadSession(), presentedHash == session.refreshTokenHash {
            // セッションを無効にする。会員の記録は消さない（本物もログアウトで会員情報を消さない）
            try storage.delete(account: sessionAccount)
            print("[MockServer] logout: 成功（セッションを無効にした）")
        } else {
            // すでに無効なトークンでも、ログアウトの目的は果たされているので成功を返す
            print("[MockServer] logout: 成功（対象のセッションなし）")
        }
    }

    // MARK: - IDトークンの確認

    /// IDトークンのクレームを確認し、通れば中身を返す。通らなければ invalidIDToken を投げる。
    /// 注意：署名を検証せずに中身を使っている。本物のバックエンドは、JWKS の公開鍵で署名を検証してから中身を使う。
    private func verifiedClaims(of idToken: Secret) throws -> MockIDTokenClaims {
        // モックへの受け渡し（方針で reveal() を認めている場面）
        let raw = idToken.reveal()
        let parts = raw.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3,
              let payload = Base64URL.decode(String(parts[1])),
              let claims = try? JSONDecoder().decode(MockIDTokenClaims.self, from: payload)
        else {
            print("[MockServer] login: 失敗（IDトークンを読めない）")
            throw BackendError.invalidIDToken
        }
        guard allowedIssuers.contains(claims.iss) else {
            print("[MockServer] login: 失敗（iss: NG）")
            throw BackendError.invalidIDToken
        }
        guard claims.aud == expectedAudience else {
            print("[MockServer] login: 失敗（aud: NG）")
            throw BackendError.invalidIDToken
        }
        guard Date() < Date(timeIntervalSince1970: claims.exp) else {
            print("[MockServer] login: 失敗（exp: NG）")
            throw BackendError.invalidIDToken
        }
        return claims
    }

    // MARK: - トークンの発行

    /// ランダムな自社トークン一式を発行し、記録用のセッション（ハッシュ値だけ）と一緒に返す。
    private func issueSession(memberKey: String,
                              previousRefreshTokenHash: String?) throws -> (BackendTokenResponse, MockSessionRecord) {
        let accessToken = Secret(try SecureRandom.base64URLString(byteCount: 32))
        let refreshToken = Secret(try SecureRandom.base64URLString(byteCount: 32))
        let session = MockSessionRecord(
            memberKey: memberKey,
            accessTokenHash: SHA256Hasher.base64URLDigest(of: accessToken.reveal()),
            accessTokenExpiresAt: Date().addingTimeInterval(accessTokenLifetime),
            refreshTokenHash: SHA256Hasher.base64URLDigest(of: refreshToken.reveal()),
            previousRefreshTokenHash: previousRefreshTokenHash
        )
        let response = BackendTokenResponse(accessToken: accessToken,
                                            refreshToken: refreshToken,
                                            expiresIn: accessTokenLifetime)
        return (response, session)
    }

    // MARK: - 記録の読み書き（本物ならデータベース）

    private func loadMembers() throws -> [String: MockMemberRecord] {
        guard let data = try storage.load(account: membersAccount) else { return [:] }
        return try JSONDecoder().decode([String: MockMemberRecord].self, from: data)
    }

    private func saveMembers(_ members: [String: MockMemberRecord]) throws {
        try storage.save(JSONEncoder().encode(members), account: membersAccount)
    }

    private func loadSession() throws -> MockSessionRecord? {
        guard let data = try storage.load(account: sessionAccount) else { return nil }
        return try JSONDecoder().decode(MockSessionRecord.self, from: data)
    }

    private func saveSession(_ session: MockSessionRecord) throws {
        try storage.save(JSONEncoder().encode(session), account: sessionAccount)
    }
}

// MARK: - 記録の形

/// 会員の記録（sub のハッシュ値ごとに1件）。名前とログイン日時だけを持つ。
nonisolated private struct MockMemberRecord: Codable {
    let name: String
    let loggedInAt: Date
}

/// セッションの記録。トークンそのものではなく、ハッシュ値だけを持つ。
nonisolated private struct MockSessionRecord: Codable {
    /// どの会員のセッションか（sub のハッシュ値）
    let memberKey: String
    let accessTokenHash: String
    let accessTokenExpiresAt: Date
    let refreshTokenHash: String
    /// ローテーションで使用済みになった1つ前のリフレッシュトークン（再利用の検知に使う）
    let previousRefreshTokenHash: String?
}

/// IDトークンのペイロードのうち、モックが確認・使用する部分。
/// aud は複数の値（配列）になることもあるが、Google の IDトークンでは文字列なので文字列として扱う。
nonisolated private struct MockIDTokenClaims: Decodable {
    let iss: String
    let aud: String
    /// 有効期限（1970年1月1日からの秒数）
    let exp: TimeInterval
    let sub: String
    let name: String?
}
