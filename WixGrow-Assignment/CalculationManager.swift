//
//  CalculationManager.swift
//  WixGrow-Assignment
//
//  Created by Lukas Adomavicius on 4/5/21.
//

import Foundation

class CalculationManager {
    
    func makeAnswerRequest(jobResponse: JobResponse) -> SubmitAnswerRequest {
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
            for cell in row {
                updateReferenceDictionary(jobData: jobAnswer.data, referenceDictionary: &referenceDictionary)
                checkReferencesInReverseOrder(jobData: &jobAnswer.data, referenceDictionary: &referenceDictionary)
                let answer = calculateAnswer(cell: cell, referenceDictionary: referenceDictionary)
                if let answer = answer {
                    jobAnswer.data[yIndex][xIndex] = answer
                } else {
                    jobAnswer.data[yIndex][xIndex] = JobData(value: nil,
                                                             formula: nil,
                                                             error: "error unknown value, reference or formula"
                    )
                }
                xIndex += 1
            }
            yIndex += 1
        }
        return jobAnswer
    }

    func calculateAnswer(cell: JobData, referenceDictionary: [String: Value]) -> JobData? {
        if cell.value != nil {
            return cell
        }
        if let columnValue = cell.formula {
            return calculateFormula(formula: columnValue, referenceDictionary: referenceDictionary)
        }
        return nil
    }
    
    func calculateFormula(formula: Formula, referenceDictionary: [String: Value]) -> JobData? {
        if let formula = formula.reference {
            return calculateReference(value: formula , referenceDictionary: referenceDictionary)
        }
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
            return calculateIsGreater(formula: columnValue, referenceDictionary: referenceDictionary)
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
    
    private func calculateReference(value: String, referenceDictionary: [String: Value]) -> JobData? {
        let answer = JobData(
            value: referenceDictionary[value],
            formula: nil
        )
        guard answer.value != nil else { return nil }
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
                let calculation = calculateFormula(formula: reference, referenceDictionary: referenceDictionary)
                guard let value = calculation?.value?.number else { return nil }
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
    
    private func calculateIsGreater(formula: [Reference], referenceDictionary: [String: Value]) -> JobData? {
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
                let calculation = calculateFormula(formula: reference, referenceDictionary: referenceDictionary)
                guard let value = calculation?.value?.number else { return nil }
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
        let value = Value(number: nil, boolean: answer, text: nil)
        return JobData(value: value, formula: nil)
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
                let calculation = calculateFormula(formula: reference, referenceDictionary: referenceDictionary)
                guard let value = calculation?.value?.number else { return nil }
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
                let calculation = calculateFormula(formula: reference, referenceDictionary: referenceDictionary)
                guard let value = calculation?.value?.number else { return nil }
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
        var firstNumber: Double?
        var answer: Bool = false
        for reference in formula {
            if let reference = reference.reference {
                guard let value = referenceDictionary[reference]?.number else { return nil }
                if let firstNumber = firstNumber  {
                    answer = firstNumber == value
                } else {
                    firstNumber = value
                }
            }
            if let reference = reference.formula {
                let calculation = calculateFormula(formula: reference, referenceDictionary: referenceDictionary)
                guard let value = calculation?.value?.number else { return nil }
                if let firstNumber = firstNumber  {
                    answer = firstNumber == value
                } else {
                    firstNumber = value
                }
            }
            if let reference = reference.value {
                guard let value = reference.number  else { return nil }
                if let firstNumber = firstNumber  {
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
            let calculation = calculateFormula(formula: reference, referenceDictionary: referenceDictionary)
            guard let value = calculation?.value?.boolean else { return nil }
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
        var firstAnswer: Bool?
        var finalAnswer = JobData(value: nil, formula: nil, error: nil)
        for reference in formula {
            if let reference = reference.reference {
                guard let value = referenceDictionary[reference]?.boolean else { return nil }
                if let firstAnswer = firstAnswer {
                    let answer = firstAnswer && value
                    finalAnswer.value = Value(number: nil, boolean: answer, text: nil)
                } else {
                    firstAnswer = value
                }
            }
            if let reference = reference.formula {
                let calculation = calculateFormula(formula: reference, referenceDictionary: referenceDictionary)
                guard let value = calculation?.value?.boolean else { return nil }
                if let firstAnswer = firstAnswer {
                    let answer = firstAnswer && value
                    finalAnswer.value = Value(number: nil, boolean: answer, text: nil)
                } else {
                    firstAnswer = value
                }
            }
            if let reference = reference.value {
                guard let value = reference.boolean  else { return nil }
                if let firstAnswer = firstAnswer {
                    let answer = firstAnswer && value
                    finalAnswer.value = Value(number: nil, boolean: answer, text: nil)
                } else {
                    firstAnswer = value
                }
            }
        }
        return finalAnswer
    }
    
    // MARK: - Calculate Or
    
    private func calculateOr(formula: [Reference], referenceDictionary: [String: Value]) -> JobData? {
        var firstAnswer: Bool?
        var finalAnswer = JobData(value: nil, formula: nil, error: nil)
        for reference in formula {
            if let reference = reference.reference {
                guard let value = referenceDictionary[reference]?.boolean else { return nil }
                if let firstAnswer = firstAnswer {
                    let answer = firstAnswer || value
                    finalAnswer.value = Value(number: nil, boolean: answer, text: nil)
                } else {
                    firstAnswer = value
                }
            }
            if let reference = reference.formula {
                let calculation = calculateFormula(formula: reference, referenceDictionary: referenceDictionary)
                guard let value = calculation?.value?.boolean else { return nil }
                if let firstAnswer = firstAnswer {
                    let answer = firstAnswer || value
                    finalAnswer.value = Value(number: nil, boolean: answer, text: nil)
                } else {
                    firstAnswer = value
                }
            }
            if let reference = reference.value {
                guard let value = reference.boolean  else { return nil }
                if let firstAnswer = firstAnswer {
                    let answer = firstAnswer || value
                    finalAnswer.value = Value(number: nil, boolean: answer, text: nil)
                } else {
                    firstAnswer = value
                }
            }
        }
        return finalAnswer
    }
    
    // MARK: - Calculate If
    
    private func calculateIf(formula: [Reference], referenceDictionary: [String: Value]) -> JobData? {
        var finalAnswer = JobData(value: nil, formula: nil, error: nil)
        var answer: Bool?
        for reference in formula {
            if let isGreater = reference.isGreater {
                answer = calculateIsGreater(formula: isGreater, referenceDictionary: referenceDictionary)?.value?.boolean
            }
        }
        if answer == true {
            let value = referenceDictionary[formula[1].reference!]?.number
            finalAnswer.value = Value(number: value, boolean: nil, text: nil)
        }
        
        if answer == false {
            let value = referenceDictionary[formula[2].reference!]?.number
            finalAnswer.value = Value(number: value, boolean: nil, text: nil)
        }
        
        if answer == nil {
            return nil
        }
        return finalAnswer
    }
    
    // MARK: - Calculate Concat
    
    private func calculateConcat(formula: [Reference], referenceDictionary: [String: Value]) -> JobData? {
        var text = ""
        for reference in formula {
            if let reference = reference.reference {
                guard let value = referenceDictionary[reference]?.text else { return nil }
                text += value
            }
            if let reference = reference.formula {
                let calculation = calculateFormula(formula: reference, referenceDictionary: referenceDictionary)
                guard let value = calculation?.value?.text else { return nil }
                text += value
            }
            if let reference = reference.value {
                guard let value = reference.text  else { return nil }
                text += value
            }
        }
        var answerValue = Value(number: nil, boolean: nil, text: nil)
        answerValue.text = text
        var jobAnswer = JobData(value: nil, formula: nil, error: nil)
        jobAnswer.value = answerValue
        return jobAnswer
    }
    
    // MARK: - Helpers
    
    private func checkReferencesInReverseOrder(jobData: inout[[JobData]], referenceDictionary: inout[String: Value]) {
        var yIndex = jobData.count - 1
        for row in jobData.reversed() {
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
                if let value = column?.value {
                    referenceDictionary["\(notationArray[Bindex])\(Aindex+1)"] = value
                }
            }
        }
    }
}
