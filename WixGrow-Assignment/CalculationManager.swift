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
        var yIndex = 0
        for row in jobAnswer.data {
            var xIndex = 0
            for column in row {
                updateReferenceDictionary(jobData: jobAnswer.data, referenceDictionary: &referenceDictionary)
                
                let answer = calculateAnswer(column: column, referenceDictionary: referenceDictionary)
                if let answer = answer {
                    jobAnswer.data[yIndex][xIndex] = answer
                } else {
                    jobAnswer.data[yIndex][xIndex] = JobData(value: nil, formula: nil, error: "error unkown value or formula")
                }
                checkReferencesInReverseOrder(jobData: &jobAnswer.data, referenceDictionary: &referenceDictionary)
                xIndex += 1
            }
            yIndex += 1
        }
        
        return jobAnswer
    }

    func calculateAnswer(column: JobData, referenceDictionary: [String: Value]) -> JobData? {
        if (column.formula?.reference) != nil {
            return calculateReference(value: column.formula! , referenceDictionary: referenceDictionary)
        }
        if column.value != nil {
            return column
        }
        if let columnValue = column.formula {
            return calculateFormula(formula: columnValue, referenceDictionary: referenceDictionary)
        }
        return nil
    }
    
    func calculateFormula(formula: Formula, referenceDictionary: [String: Value]) -> JobData? {
        if let formula = formula.sum {
            return calculateSum(formula: formula, referenceDictionary: referenceDictionary)
        }
        if let columnValue = formula.multiply {
            return calculateMultiplication(formula: columnValue, referenceDictionary: referenceDictionary)
        }
        if let columnValue = formula.divide {
            return calculateDivision(formula: columnValue, referenceDictionary: referenceDictionary)
        }
        if let columnValue = formula.isGreater {
            let result = calculateIsGreater(formula: columnValue, referenceDictionary: referenceDictionary)
            let answer = Value(number: nil, boolean: result, text: nil)
            return JobData(value: answer, formula: nil)
        }
        if let columnValue = formula.isEqual {
            return calculateIsEqual(formula: columnValue, referenceDictionary: referenceDictionary)
        }
        if let columnValue = formula.not {
            return calculateNot(formula: columnValue, referenceDictionary: referenceDictionary)
        }
        if let columnValue = formula.and {
            return calculateAnd(formula: columnValue, referenceDictionary: referenceDictionary)
        }
        if let columnValue = formula.or {
            return calculateOr(formula: columnValue, referenceDictionary: referenceDictionary)
        }
        if let columnValue = formula.formulaIf {
            return calculateIf(formula: columnValue, referenceDictionary: referenceDictionary)
        }
        if let columnValue = formula.concat {
            return calculateConcat(formula: columnValue, referenceDictionary: referenceDictionary)
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
    
    private func calculateSum(formula: [Reference], referenceDictionary: [String: Value]) -> JobData? {
        var answer: Double = 0
        for reference in formula {
            if let reference = reference.reference {
                guard let value = referenceDictionary[reference]?.number else { return nil }
                answer += value
            }
            if let reference = reference.formula {
                guard let value = calculateFormula(formula: reference, referenceDictionary: referenceDictionary)?.value?.number else { return nil }
                answer += value
            }
            if let value = reference.value?.number {
                answer += value
            }
        }
        let value = Value(number: answer, boolean: nil, text: nil)
        return JobData(value: value, formula: nil)
    }
    
    // MARK: - Calculate Is Greater
    
    private func calculateIsGreater(formula: [Reference], referenceDictionary: [String: Value]) -> Bool? {
        var firstNumber: Double?
        var answer: Bool?
        for reference in formula {
            if let reference = reference.reference {
                guard let value = referenceDictionary[reference]?.number else { return nil }
                if let first = firstNumber {
                    answer = first > value
                } else {
                    firstNumber = value
                }
            }
            if let reference = reference.formula {
                guard let value = calculateFormula(formula: reference, referenceDictionary: referenceDictionary)?.value?.number else { return nil }
                if let first = firstNumber {
                    answer = first > value
                } else {
                    firstNumber = value
                }
            }
            if let reference = reference.value {
                guard let value = reference.number  else { return nil }
                if let first = firstNumber {
                    answer = first > value
                } else {
                    firstNumber = value
                }
            }
        }
        return answer
    }
    
    // MARK: - Calculate Multiplication
    
    private func calculateMultiplication(formula: [Reference], referenceDictionary: [String: Value]) -> JobData? {
        var answer: Double = 1
        for reference in formula {
            if let reference = reference.reference {
                guard let value = referenceDictionary[reference]?.number else { return nil }
                answer *= value
            }
            if let reference = reference.formula {
                guard let value = calculateFormula(formula: reference, referenceDictionary: referenceDictionary)?.value?.number else { return nil }
                answer *= value
            }
            if let reference = reference.value {
                guard let value = reference.number  else { return nil }
                answer *= value
            }
        }
        let value = Value(number: answer, boolean: nil, text: nil)
        return JobData(value: value, formula: nil)
    }
    
    // MARK: - Calculate Division
    
    private func calculateDivision(formula: [Reference], referenceDictionary: [String: Value]) -> JobData? {
        var firstNumber: Double?
        var answer: Double?
        for reference in formula {
            if let reference = reference.reference {
                guard let value = referenceDictionary[reference]?.number else { return nil }
                if let firstNumber = firstNumber  {
                    answer = firstNumber/value
                } else {
                    firstNumber = value
                }
            }
            if let reference = reference.formula {
                guard let value = calculateFormula(formula: reference, referenceDictionary: referenceDictionary)?.value?.number else { return nil }
                if let firstNumber = firstNumber  {
                    answer = firstNumber/value
                } else {
                    firstNumber = value
                }
            }
            if let reference = reference.value {
                guard let value = reference.number  else { return nil }
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
    
    private func calculateIsEqual(formula: [Reference], referenceDictionary: [String: Value]) -> JobData? {
        var firstNumber: Double = 0
        var answer: Bool = false
        for reference in formula {
            if let reference = reference.reference {
                guard let value = referenceDictionary[reference]?.number else { return nil }
                if firstNumber != 0  {
                    answer = firstNumber == value
                } else {
                    firstNumber = value
                }
            }
            if let reference = reference.formula {
                guard let value = calculateFormula(formula: reference, referenceDictionary: referenceDictionary)?.value?.number else { return nil }
                if firstNumber != 0  {
                    answer = firstNumber == value
                } else {
                    firstNumber = value
                }
            }
            if let reference = reference.value {
                guard let value = reference.number  else { return nil }
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
    
    private func calculateNot(formula: Reference, referenceDictionary: [String: Value]) -> JobData? {
        var answer: Bool?
        if let reference = formula.reference {
            guard let value = referenceDictionary[reference]?.boolean else { return nil }
            answer = !value
        }
        if let reference = formula.formula {
            guard let value = calculateFormula(formula: reference, referenceDictionary: referenceDictionary)?.value?.boolean else { return nil }
            answer = !value
        }
        if let reference = formula.value {
            guard let value = reference.boolean else { return nil }
            answer = !value
        }
        let value = Value(number: nil, boolean: answer, text: nil)
        return JobData(value: value, formula: nil)
    }
    
    // MARK: - Calculate And
    
    private func calculateAnd(formula: [Reference], referenceDictionary: [String: Value]) -> JobData? {
        var answer: Bool?
        var finalAnswer = JobData(value: nil, formula: nil, error: nil)
        for reference in formula {
            if let reference = reference.reference {
                guard let value = referenceDictionary[reference]?.boolean else { return nil }
                if let answerr = answer {
                    answer = answerr && value
                    finalAnswer.value = Value(number: nil, boolean: answer, text: nil)
                } else {
                    answer = value
                }
            }
            if let reference = reference.formula {
                guard let value = calculateFormula(formula: reference, referenceDictionary: referenceDictionary)?.value?.boolean else { return nil }
                if let answerr = answer {
                    answer = answerr && value
                    finalAnswer.value = Value(number: nil, boolean: answer, text: nil)
                } else {
                    answer = value
                }
            }
            if let reference = reference.value {
                guard let value = reference.boolean  else { return nil }
                if let answerr = answer {
                    answer = answerr && value
                    finalAnswer.value = Value(number: nil, boolean: answer, text: nil)
                } else {
                    answer = value
                }
            }
        }
        return finalAnswer
    }
    
    // MARK: - Calculate Or
    
    private func calculateOr(formula: [Reference], referenceDictionary: [String: Value]) -> JobData? {
        var answer: Bool?
        var finalAnswer = JobData(value: nil, formula: nil, error: nil)
        for reference in formula {
            if let reference = reference.reference {
                guard let value = referenceDictionary[reference]?.boolean else { return nil }
                if let answerr = answer {
                    answer = answerr || value
                    finalAnswer.value = Value(number: nil, boolean: answer, text: nil)
                } else {
                    answer = value
                }
            }
            if let reference = reference.formula {
                guard let value = calculateFormula(formula: reference, referenceDictionary: referenceDictionary)?.value?.boolean else { return nil }
                if let answerr = answer {
                    answer = answerr || value
                    finalAnswer.value = Value(number: nil, boolean: answer, text: nil)
                } else {
                    answer = value
                }
            }
            if let reference = reference.value {
                guard let value = reference.boolean  else { return nil }
                if let answerr = answer {
                    answer = answerr || value
                    finalAnswer.value = Value(number: nil, boolean: answer, text: nil)
                } else {
                    answer = value
                }
            }
        }
        return finalAnswer
    }
    
    // MARK: - Calculate If
    
    private func calculateIf(formula: [Reference], referenceDictionary: [String: Value]) -> JobData? {
        var finalAnswer = JobData(value: nil, formula: nil, error: nil)
        if let reference = formula[0].reference {
            guard let value = referenceDictionary[reference]?.boolean else { return nil }
            if value {
                guard let value = referenceDictionary[formula[1].reference!] else { return nil }
                finalAnswer.value = value
            } else {
                guard let value = referenceDictionary[formula[2].reference!] else { return nil }
                finalAnswer.value = value
            }
        }
        if let reference = formula[0].formula {
            guard let value = calculateFormula(formula: reference, referenceDictionary: referenceDictionary)?.value?.boolean else { return nil }
            if value {
                guard let value = referenceDictionary[formula[1].reference!] else { return nil }
                finalAnswer.value = value
            } else {
                guard let value = referenceDictionary[formula[2].reference!] else { return nil }
                finalAnswer.value = value
            }
        }
        if let reference = formula[0].value {
            guard let value = reference.boolean else { return nil }
            if value {
                guard let value = referenceDictionary[formula[1].reference!] else { return nil }
                finalAnswer.value = value
            } else {
                guard let value = referenceDictionary[formula[2].reference!] else { return nil }
                finalAnswer.value = value
            }
        }
        return finalAnswer
    }
    
    // MARK: - Calculate Concat
    
    private func calculateConcat(formula: [Reference], referenceDictionary: [String: Value]) -> JobData? {
        var jobAnswer = JobData(value: nil, formula: nil, error: nil)
        let answerValue = Value(number: nil, boolean: nil, text: nil)
        var text = ""
        for reference in formula {
            text += (reference.value?.text)!
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
                    updateReferenceDictionary(jobData: jobData, referenceDictionary: &referenceDictionary)
                }
                xIndex -= 1
            }
            yIndex -= 1
        }
    }
    
    private func updateReferenceDictionary(jobData: [[JobData?]], referenceDictionary: inout[String: Value]) {
        let notationArray = (97...122).map({Character(UnicodeScalar($0))}).map { $0.uppercased()}
        for (Aindex, row) in jobData.enumerated() {
            for (Bindex, column) in row.enumerated() {
                referenceDictionary["\(notationArray[Bindex])\(Aindex+1)"] = column?.value
            }
        }
    }
}
