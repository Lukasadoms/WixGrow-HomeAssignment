//
//  JobResponse.swift
//  WixGrow-Assignment
//
//  Created by Lukas Adomavicius on 3/31/21.
//

import Foundation

struct JobResponse: Codable {

    let submissionURL: String
    let jobs: [Job]

    enum CodingKeys: String, CodingKey {
        case submissionURL = "submissionUrl"
        case jobs
    }
}

// MARK: - Job

struct Job: Codable {
    let id: String
    var data: [[Cell]]
}

// MARK: - JobData

struct Cell: Codable {
    var value: Value?
    let formula: Formula?
    var error: String?
}

// MARK: - Value

struct Value: Codable {
    var number: Double?
    var boolean: Bool?
    var text: String?
}

// MARK: - Formula

class Formula: Codable, Loopable {
    let reference: String?
    let sum, multiply, divide, isGreater, isEqual, and, or, formulaIf, concat, not: [Formula]?
    let value: Value?

    enum CodingKeys: String, CodingKey {
        case reference, sum, multiply, divide
        case isGreater = "is_greater"
        case isEqual = "is_equal"
        case not, and, or
        case formulaIf = "if"
        case concat
        case value
    }
}
