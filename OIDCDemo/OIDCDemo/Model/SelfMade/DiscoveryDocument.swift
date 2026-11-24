//
//  DiscoveryDocument.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/23.
//

import Foundation

struct DiscoveryDocument: Decodable {
  let issuer: String
  let authorizationEndpoint: String
  let tokenEndpoint: String
  
  private enum CodingKeys: String, CodingKey {
    case issuer
    case authorizationEndpoint = "authorization_endpoint"
    case tokenEndpoint = "token_endpoint"
  }
}
