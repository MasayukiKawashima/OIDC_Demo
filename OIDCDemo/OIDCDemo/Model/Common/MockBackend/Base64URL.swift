//
//  Base64URL.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/06.
//

import Foundation

nonisolated enum Base64URL {
    /// Data を base64に変換し、さらにbase64URLに変換
    static func encode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .trimmingCharacters(in: CharacterSet(charactersIn: "="))
    }

    /// base64url の文字列を Data に戻す。形式が正しくなければ nil を返す。
    static func decode(_ string: String) -> Data? {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        // 省略された「=」を補い、長さを4の倍数にする

      // Data(base64Encoded:) は、文字数が4の倍数でないと変換に失敗する
      // なのでまずbase64.count % 4であまりをもとめる
      //　次に４からそのあまりの数を引いて補うべき=の数を求めてbase64に足す
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }
        return Data(base64Encoded: base64)
    }
}
