//
//  CalculationManager.swift
//  WixGrow-Assignment
//
//  Created by Lukas Adomavicius on 4/5/21.
//

import Foundation

class CalculationManager {
    
    func calculateAnswerRequest(jobResponse: JobResponse) -> SubmitAnswerRequest {
        var submitAnswerRequest = SubmitAnswerRequest(results: [])
        for job in jobResponse.jobs {
            let result = calculateJob(job: job)
            submitAnswerRequest.results.append(result)
        }
        return submitAnswerRequest
    }
    
    private func calculateJob(job: Job) -> Job {
        var referenceDictionary: [String: Value] = [:]
        var jobAnswer = job
        calculateJobData(jobData: &jobAnswer.data, referenceDictionary: &referenceDictionary)
        return jobAnswer
    }
    
    private func calculateJobData(
        jobData: inout[[JobData]],
        referenceDictionary: inout[String: Value]
    ) {
        var answer: JobData?
        var yIndex = 0
       
        for row in jobData {
            var xIndex = 0
            for column in row {
                updateDictionary(jobData: jobData, referenceDictionary: &referenceDictionary)
                answer = calculateAnswer(column: column, referenceDictionary: referenceDictionary)
                if let answer = answer {
                    jobData[yIndex][xIndex] = answer
                } else {
                    jobData[yIndex][xIndex] = JobData(value: nil, formula: nil, error: "error unkown value or formula")
                }
                xIndex += 1
            }
            yIndex += 1
        }
        checkReferencesInReverseOrder(jobData: &jobData, referenceDictionary: &referenceDictionary)

    }
    
    func calculateAnswer(column: JobData, referenceDictionary: [String: Value]) -> JobData? {
        if (column.formula?.reference) != nil {
            return calculateReference(value: column.formula! , referenceDictionary: referenceDictionary)
        }
        if let columnValue = column.formula?.sum {
            return calculateSum(columnValue: columnValue, referenceDictionary: referenceDictionary)
        }
        if let columnValue = column.formula?.multiply {
            return calculateMultiplication(columnValue: columnValue, referenceDictionary: referenceDictionary)
        }
        if let columnValue = column.formula?.divide {
            return calculateDivision(columnValue: columnValue, referenceDictionary: referenceDictionary)
        }
        if let columnValue = column.formula?.isGreater {
            let result = calculateIsGreater(function: columnValue, referenceDictionary: referenceDictionary)
            let answer = Value(number: nil, boolean: result, text: nil)
            return JobData(value: answer, formula: nil)
        }
        if let columnValue = column.formula?.isEqual {
            return calculateIsEqual(columnValue: columnValue, referenceDictionary: referenceDictionary)
        }
        if let columnValue = column.formula?.not {
            return calculateNot(columnValue: columnValue, referenceDictionary: referenceDictionary)
        }
        if let columnValue = column.formula?.and {
            return calculateAnd(columnValue: columnValue, referenceDictionary: referenceDictionary)
        }
        if let columnValue = column.formula?.or {
            return calculateOr(columnValue: columnValue, referenceDictionary: referenceDictionary)
        }
        if let columnValue = column.formula?.formulaIf {
            return calculateIf(columnValue: columnValue, referenceDictionary: referenceDictionary)
        }
        if let columnValue = column.formula?.concat {
            return calculateConcat(columnValue: columnValue, referenceDictionary: referenceDictionary)
        }
        if let columnValue = column.value {
            return JobData(value: columnValue, formula: nil, error: nil)
        }
        return nil
    }
    
    // MARK: - Calculate Reference
    
    private func calculateReference(value: Formula, referenceDictionary: [String: Value]) -> JobData? {
        guard let string = value.reference else { return nil }
        let answer = JobData(
            value: referenceDictionary[string],
            formula: nil
        )
        guard answer.value != nil else { return JobData(
            value: nil,
            formula: value,
            error: nil)
            }
        return answer
    }
    
    // MARK: - Calculate Sum
    
    private func calculateSum(columnValue: [Reference],
                              referenceDictionary: [String: Value]) -> JobData? {
        var answer: Double = 0
        for reference in columnValue {
            guard let value = referenceDictionary[reference.string]?.number else { return nil }
            answer += value
        }
        let value = Value(number: answer, boolean: nil, text: nil)
        return JobData(value: value, formula: nil)
    }
    
    // MARK: - Calculate Is Greater
    
    
    private func calculateIsGreater(function: [Reference], referenceDictionary: [String: Value]) -> Bool? {
        var firstNumber: Double?
        var answer: Bool?
        for reference in function {
            guard let value = referenceDictionary[reference.string] else { return nil }
            if let first = firstNumber {
                answer = first > value.number!
            } else {
                firstNumber = value.number!
            }
        }
        return answer
    }
    
    // MARK: - Calculate Multiplication
    
    private func calculateMultiplication(columnValue: [Reference], referenceDictionary: [String: Value]) -> JobData? {
        var answer: Double = 1
        for reference in columnValue {
            if let value = referenceDictionary[reference.string]?.number {
                answer *= value
            }
        }
        let value = Value(number: answer, boolean: nil, text: nil)
        return JobData(value: value, formula: nil)
    }
    
    // MARK: - Calculate Division
    
    private func calculateDivision(columnValue: [Reference], referenceDictionary: [String: Value]) -> JobData? {
        var firstNumber: Double?
        var answer: Double?
        for reference in columnValue {
            if let value = referenceDictionary[reference.string]?.number {
                if let firstNumber = firstNumber  {
                    answer = firstNumber/value
                } else {
                    firstNumber = value
                }
            }
        }
        let value = Value(number: answer, boolean: nil, text: nil)
        return JobData(value: value,formula: nil)
    }
    
    // MARK: - Calculate is Equal
    
    private func calculateIsEqual(columnValue: [Reference], referenceDictionary: [String: Value]) -> JobData? {
        var firstNumber: Double = 0
        var answer: Bool = false
        for reference in columnValue {
            if let value = referenceDictionary[reference.string]?.number {
                if firstNumber != 0  {
                    answer = firstNumber == value
                } else {
                    firstNumber = value
                }
            }
        }
        let value = Value(number: nil, boolean: answer, text: nil)
        return JobData(value: value, formula: nil)
    }
    
    // MARK: - Calculate Not
    
    private func calculateNot(columnValue: Reference, referenceDictionary: [String: Value]) -> JobData? {
        var answer: Bool?
        if let value = referenceDictionary[columnValue.string]?.boolean {
            answer = !value
        }
        let value = Value(number: nil, boolean: answer, text: nil)
        return JobData(value: value, formula: nil)
    }
    
    // MARK: - Calculate And
    
    private func calculateAnd(columnValue: [Reference], referenceDictionary: [String: Value]) -> JobData? {
        var answer: Bool?
        var finalAnswer = JobData(value: nil, formula: nil, error: nil)
        for reference in columnValue {
            if let value = referenceDictionary[reference.string]?.boolean {
                if let answerr = answer {
                    answer = answerr && value
                    finalAnswer.value = Value(number: nil, boolean: answer, text: nil)
                } else {
                    answer = value
                }
            } else {
                finalAnswer.error = "error"
            }
        }
        return finalAnswer
    }
    
    // MARK: - Calculate Or
    
    private func calculateOr(columnValue: [Reference], referenceDictionary: [String: Value]) -> JobData? {
        var answer: Bool?
        var finalAnswer = JobData(value: nil, formula: nil, error: nil)
        for reference in columnValue {
            if let value = referenceDictionary[reference.string]?.boolean {
                if let answerr = answer {
                    answer = answerr || value
                    finalAnswer.value = Value(number: nil, boolean: answer, text: nil)
                } else {
                    answer = value
                }
            } else {
                finalAnswer.error = "error"
            }
        }
        return finalAnswer
    }
    
    // MARK: - Calculate If
    
    private func calculateIf(columnValue: [If], referenceDictionary: [String: Value]) -> JobData? {
        var answer: Bool?
        var finalAnswer = JobData(value: nil, formula: nil, error: nil)
        for reference in columnValue {
            if let isGreater = reference.isGreater {
                answer = calculateIsGreater(function: isGreater, referenceDictionary: referenceDictionary)
            }
        }
        if let answerr = answer {
            if answerr {
                let value = referenceDictionary[columnValue[1].reference!]?.number
                finalAnswer.value = Value(number: value, boolean: nil, text: nil)
            } else {
                let value = referenceDictionary[columnValue[2].reference!]?.number
                finalAnswer.value = Value(number: value, boolean: nil, text: nil)
            }
        }
        return finalAnswer
    }
    
    // MARK: - Calculate Concat
    
    private func calculateConcat(columnValue: [Concat], referenceDictionary: [String: Value]) -> JobData? {
        var jobAnswer = JobData(value: nil, formula: nil, error: nil)
        var answerValue = Value(number: nil, boolean: nil, text: nil)
        var text = ""
        for reference in columnValue {
            text += reference.value.text
        }
        answerValue.text = text
        jobAnswer.value = answerValue
        return jobAnswer
    }
    
    // MARK: - Helpers
    
    private func checkReferencesInReverseOrder(jobData: inout[[JobData]], referenceDictionary: inout[String: Value]) {
        var yIndex = jobData.count - 1
        for row in jobData {
            var xIndex = row.count - 1
            for column in row.reversed() {
                if let columnValue = column.formula?.reference {
                    let answer = JobData(
                        value: referenceDictionary[columnValue],
                        formula: nil
                    )
                    if referenceDictionary[columnValue] != nil {
                        jobData[yIndex][xIndex] = answer
                    } else {
                        jobData[yIndex][xIndex] = column
                    }
                    
                    updateDictionary(jobData: jobData, referenceDictionary: &referenceDictionary)
                }
                xIndex -= 1
            }
            yIndex -= 1
        }
    }
    
    private func updateDictionary(jobData: [[JobData?]], referenceDictionary: inout[String: Value]) {
        let notationArray = (97...122).map({Character(UnicodeScalar($0))}).map { $0.uppercased()}
        for (Aindex, row) in jobData.enumerated() {
            for (Bindex, column) in row.enumerated() {
                referenceDictionary["\(notationArray[Bindex])\(Aindex+1)"] = column?.value
            }
        }
    }
}
