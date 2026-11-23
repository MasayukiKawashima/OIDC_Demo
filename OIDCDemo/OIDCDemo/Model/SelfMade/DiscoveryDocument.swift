//
//  DiscoveryDocument.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/23.
//

import Foundation

private struct DiscoveryDocument: Decodable {
  let issuer: String
  let authorizationEndpoint: String
  let tokenEndpoint: String
  // CodingKeys でスネークケースのキーに対応させる

  
}
