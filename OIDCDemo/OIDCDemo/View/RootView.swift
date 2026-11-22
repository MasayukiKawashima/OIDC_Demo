//
//  RootView.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/20.
//


import SwiftUI

/// サインイン前とサインイン後の画面を切り替える。
/// 状態は SessionStateModel が持ち、この画面は読むだけにする。
struct RootView: View {

  @Environment(SessionStateModel.self) private var sessionState

  var body: some View {
    Group {
      switch sessionState.phase {
      case .restoring:
        ProgressView()
      case .signedOut:
        SignInView(signInPerformer: sessionState)
      case .signedIn(let memberInfo):
        ProfileView(memberInfo: memberInfo, signOutPerformer: sessionState)
      }
    }
  }
}
