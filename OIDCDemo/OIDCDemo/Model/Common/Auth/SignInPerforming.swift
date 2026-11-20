//
//  SignInPerforming.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/20.
//

import Foundation

/// サインイン機能を有している画面が依存するプロトコル。
@MainActor
protocol SignInPerforming {
  func signIn() async throws
}
