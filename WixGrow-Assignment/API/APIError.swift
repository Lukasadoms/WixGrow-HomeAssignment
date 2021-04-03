//
//  APIError.swift
//  WixGrow-Assignment
//
//  Created by Lukas Adomavicius on 3/31/21.
//

import Foundation

enum APIError: Error {
    case failedRequest
    case unexpectedDataFormat
    case failedResponse
    case failedURLCreation
    
    var errorDescription: String {
        switch self {
        case .failedRequest:
            return "Failed making URL request!"
        case .unexpectedDataFormat:
            return "Unexpected data format!"
        case .failedResponse:
            return "Failed getting URL response!"
        case .failedURLCreation:
            return "Failed making URL!"
        }
    }
}
