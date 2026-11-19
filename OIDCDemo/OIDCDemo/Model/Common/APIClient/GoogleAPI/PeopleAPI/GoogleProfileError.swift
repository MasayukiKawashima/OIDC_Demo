//
//  GoogleProfileError.swift
//  OIDCDemo
//
//  Created by 川島真之 on 2026/11/15.
//

import Foundation

nonisolated enum GoogleProfileError: Error {
    case network
    case unauthorized
    case forbidden
    case unexpectedStatus(Int)
    case invalidResponse
    case nameNotFound
}
