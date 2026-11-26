//
//  GoogleDiscoveryClientProtocol.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/23.
//

import Foundation

protocol GoogleDiscoveryClientProtocol {

  func fetchEndpoints() async throws -> GoogleEndpoints
}
