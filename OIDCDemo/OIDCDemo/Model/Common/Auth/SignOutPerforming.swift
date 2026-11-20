//
//  SignOutPerforming.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/20.
//

import Foundation

/// サインアウト機能を有している画面が依存するプロコトル。
@MainActor
protocol SignOutPerforming {
  func signOut() async
}
