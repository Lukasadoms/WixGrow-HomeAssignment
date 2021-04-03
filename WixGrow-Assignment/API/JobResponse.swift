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
    var data: [[JobData?]]?
}

// MARK: - JobData

struct JobData: Codable {
    let value: Value?
    let formula: Formula?
}

// MARK: - Value

struct Value: Codable {
    let number: Double?
    let boolean: Bool?
    let text: String?
}

// MARK: - Formula

struct Formula: Codable {
    let reference: String?
    let sum, multiply, divide, isGreater: [Reference]?
    let isEqual: [Reference]?
    let not: Reference?
    let and, or: [Reference]?
    let formulaIf: [If]?
    let concat: [Concat]?

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
    let reference: String
}

// MARK: - Concat

struct Concat: Codable {
    let value: ConcatValue
}

// MARK: - ConcatValue

struct ConcatValue: Codable {
    let text: String
}

// MARK: - If

struct If: Codable {
    let isGreater: [Reference]?
    let reference: String?

    enum CodingKeys: String, CodingKey {
        case isGreater = "is_greater"
        case reference
    }
}
