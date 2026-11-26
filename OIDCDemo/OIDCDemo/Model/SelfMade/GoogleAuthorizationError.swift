//
//  GoogleAuthorizationError.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/26.
//

import Foundation

nonisolated enum GoogleAuthorizationError: Error {
  case invalidAuthorizationURL
  case invalidRedirectURI
  case noPresentationAnchor
  case alreadyStarted
  case cannotStart
  case missingCallbackURL
}
