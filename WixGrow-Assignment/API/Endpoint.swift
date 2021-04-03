//
//  Endpoint.swift
//  WixGrow-Assignment
//
//  Created by Lukas Adomavicius on 3/31/21.
//

import Foundation

enum APIEndpoint {
    case jobs
    
    var url: URL? {
        switch self {
        case .jobs:
            return makeURL(endpoint: "jobs")
        }
    }
}

// MARK: - Helpers

private extension APIEndpoint {

    var BaseURL: String {
        "https://www.wix.com/_serverless/hiring-task-spreadsheet-evaluator/"
    }

    func makeURL(endpoint: String) -> URL? {
        let urlString = BaseURL + endpoint
        return URL(string: urlString)
    }
}
