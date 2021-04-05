//
//  SubmitResponse.swift
//  WixGrow-Assignment
//
//  Created by Lukas Adomavicius on 4/2/21.
//

import Foundation

struct SubmitAnswerRequest: Codable {
    var email: String = "lukasadoms@gmail.com"
    var results: [Job]
}
