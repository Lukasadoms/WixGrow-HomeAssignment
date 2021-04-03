//
//  PostAnswersResponse.swift
//  WixGrow-Assignment
//
//  Created by Lukas Adomavicius on 4/3/21.
//

import Foundation

struct PostAnswersResponse: Codable {
    let error: String?
    let help: String?
    let message: String?
    let errorCode: Int?
}
