//
//  SecureRandom.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/06.
//

import Foundation
import Security

/// 暗号学的に安全な乱数（推測できない乱数）を作る。
/// トークン、PKCE の code_verifier、state、nonce など、推測されてはいけない値に使う。
nonisolated enum SecureRandom {

  /// 指定したバイト数のランダムなデータを作る。
  static func bytes(count: Int) throws -> Data {

    // preconditionとは必ず満たされなければならない条件（事前条件）を検証するメソッド
    // falseの場合アプリをクラッシュさせ、不正なデータで処理を続けさせないためのもの
    precondition(count > 0, "バイト数は1以上にする")

    // countの数の要素数のUInt8配列を作る
    // この時点では各要素は0(0, 0, 0, .....)
    var bytes = [UInt8](repeating: 0, count: count)
    // SecRandomCopyBytes は、OS の安全な乱数を指定した場所に書き込む C 言語の関数
    // - 第1引数：乱数の作り方。標準の kSecRandomDefault を使う（iOS では実質これ一択）
    // - 第2引数：書き込むバイト数。配列の要素数を渡し、配列の外にはみ出して書き込まないようにする
    // - 第3引数：書き込む場所（メモリの位置）。&bytes を渡す
    // &bytesとは
    // & を付けた式は本来 inout 引数に渡す書き方（in-out 式）。
    // 受け取る引数がポインター型のときは、Swift が配列の先頭の場所（ポインター）に自動で変換して渡す。
    // SecRandomCopyBytesはC言語関数なので、第3引数はポインター型を指定する
    // この場所が有効なのは呼び出しの間だけ（Data にはこの変換が使えない）
    let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)

    // 成否判定
    guard status == errSecSuccess else {
      throw SecureRandomError.failed(status)
    }
    // 最後に[UInt8]をDataに変換する
    return Data(bytes)
  }

  /// 指定したバイト数のランダムなデータを、base64url の文字列にして返す。
  static func base64URLString(byteCount: Int) throws -> String {
    Base64URL.encode(try bytes(count: byteCount))
  }
}
