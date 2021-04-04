//
//  SubmitResponse.swift
//  WixGrow-Assignment
//
//  Created by Lukas Adomavicius on 4/2/21.
//

import Foundation

struct SubmitAnswerRequest: Codable {
    let email: String = "lukasadoms@gmail.com"
    var results: [JobResult?]
}

struct JobResult: Codable {
    let id: String
    var data: [[JobData]]
}