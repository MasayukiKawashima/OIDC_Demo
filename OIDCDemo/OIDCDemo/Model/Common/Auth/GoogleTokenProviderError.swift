//
//  GoogleTokenProviderError.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/19.
//

import Foundation

/// GoogleTokenProvider の実装（自前実装・AppAuth版）に共通する失敗。
/// 実装ごとの失敗（Discovery の失敗など）は、各実装のエラー型で表し、ここには入れない。
nonisolated enum GoogleTokenProviderError: Error {
  /// ユーザーが Google のサインイン画面を閉じた。
  /// 失敗ではないため、画面は何も表示せずにサインイン前に戻す。
  case canceled
}
