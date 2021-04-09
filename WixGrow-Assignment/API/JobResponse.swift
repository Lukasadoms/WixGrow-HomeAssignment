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
    var data: [[JobData]]
}

// MARK: - JobData

struct JobData: Codable {
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

class Formula: Codable {
    let reference: String?
    let sum, multiply, divide, isGreater, isEqual, and, or, formulaIf, concat: [Reference]?
    let not: Reference?

    enum CodingKeys: String, CodingKey {
        case reference, sum, multiply, divide
        case isGreater = "is_greater"
        case isEqual = "is_equal"
        case not, and, or
        case formulaIf = "if"
        case concat
    }
}

// MARK: - Reference

struct Reference: Codable {
    let reference: String?
    let value: Value?
    let formula: Formula?
    let isGreater: [Reference]?
    
    enum CodingKeys: String, CodingKey {
        case reference, value, formula
        case isGreater = "is_greater"
    }
}
