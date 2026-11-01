//
//  OIDCDemoApp.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/10/30.
//

import SwiftUI

@main
struct OIDCDemoApp: App {

  init() {
#if DEBUG
    runSecretChecks()
#endif
  }
  
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
