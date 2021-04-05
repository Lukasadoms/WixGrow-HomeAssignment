//
//  DictionaryManager.swift
//  WixGrow-Assignment
//
//  Created by Lukas Adomavicius on 4/5/21.
//

import Foundation

struct DictionaryManager {
    
    func updateDictionary(jobData: [[JobData?]], referenceDictionary: inout[String: Value]){
        let notationArray = (97...122).map({Character(UnicodeScalar($0))}).map { $0.uppercased()}
        for (Aindex, row) in jobData.enumerated() {
            for (Bindex, column) in row.enumerated() {
                referenceDictionary["\(notationArray[Bindex])\(Aindex+1)"] = column?.value
            }
        }
    }
}
