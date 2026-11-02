//
//  Secret.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/01.
//

import Foundation

/// トークン類・認可コード・code_verifier など、出力してはいけない値を隠すためにラップする型。
/// ログ出力、文字列補間(トークン: \(token))みたいな文字列中に埋め込むやつ）、dump、デバッガーの po（ブレークポイントで止めているときに、その時点の変数の値を表示するやつ）のいずれでも <redacted> になる。
/// 意図的に付けていないプロトコル:
/// - Codable: 自動合成するとエンコード時に値がそのまま出る。保存時は reveal() で明示的に取り出す
/// - Equatable / Hashable: 必要になったら理由とともに検討する
///
nonisolated struct Secret: Sendable, CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    private let value: String

    init(_ value: String) { self.value = value }

    /// 実際の値が必要な箇所（Authorizationヘッダー、Keychain保存、モックへの受け渡し）でだけ呼ぶ。
    func reveal() -> String { value }

    var description: String { "<redacted>" }
    var debugDescription: String { "<redacted>" }
    var customMirror: Mirror { Mirror(self, children: []) }
}
