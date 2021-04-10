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
                    let cell = Cell(
                        value: nil,
                        formula: nil,
                        error: "error unknown value, reference or formula")
                    jobAnswer.data[yIndex][xIndex] = cell
                }
                xIndex += 1
            }
            yIndex += 1
        }
        return jobAnswer
    }

    func calculateAnswer(cell: Cell, referenceDictionary: [String: Value]) -> Cell? {
        if cell.value != nil {
            return cell
        }
        if let columnValue = cell.formula {
            return calculateFormula(formula: columnValue, referenceDictionary: referenceDictionary)
        }
        return nil
    }
    
    func calculateFormula(formula: Formula, referenceDictionary: [String: Value]) -> Cell? {
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
    
    private func calculateReference(value: String, referenceDictionary: [String: Value])  -> Cell? {
        let answer = Cell(
            value: referenceDictionary[value],
            formula: nil
        )
        guard answer.value != nil else { return nil }
        return answer
    }
    
    // MARK: - Calculate Sum
    
    private func calculateSum(formula: [Formula], referenceDictionary: [String: Value])  -> Cell? {
        var answer: Double = 0
        for reference in formula {
            let cell = Cell(value: reference.value, formula: reference, error: nil)
            let calculation = calculateAnswer(cell: cell, referenceDictionary: referenceDictionary)
            guard let value = calculation?.value?.number else { return nil }
            answer += value
        }
        let value = Value(number: answer, boolean: nil, text: nil)
        return Cell(value: value, formula: nil)
    }
    
    // MARK: - Calculate Is Greater
    
    private func calculateIsGreater(formula: [Formula], referenceDictionary: [String: Value]) ->  Cell? {
        var firstNumber: Double?
        var answer: Bool?
        for reference in formula {
            let cell = Cell(value: reference.value, formula: reference, error: nil)
            let calculation = calculateAnswer(cell: cell, referenceDictionary: referenceDictionary)
            guard let value = calculation?.value?.number else { return nil }
            if let first = firstNumber {
                answer = first > value
            } else {
                firstNumber = value
            }
        }
        let value = Value(number: nil, boolean: answer, text: nil)
        return Cell(value: value, formula: nil)
    }
    
    // MARK: - Calculate Multiplication

    private func calculateMultiplication(formula: [Formula], referenceDictionary: [String: Value]) -> Cell? {
        var answer: Double = 1
        for reference in formula {
            let cell = Cell(value: reference.value, formula: reference, error: nil)
            let calculation = calculateAnswer(cell: cell, referenceDictionary: referenceDictionary)
            guard let value = calculation?.value?.number else { return nil }
            answer *= value
        }
        let value = Value(number: answer, boolean: nil, text: nil)
        return Cell(value: value, formula: nil)
    }

    // MARK: - Calculate Division

    private func calculateDivision(formula: [Formula], referenceDictionary: [String: Value]) -> Cell? {
        var firstNumber: Double?
        var answer: Double?
        for reference in formula {
            let cell = Cell(value: reference.value, formula: reference, error: nil)
            let calculation = calculateAnswer(cell: cell, referenceDictionary: referenceDictionary)
            guard let value = calculation?.value?.number else { return nil }
            if let firstNumber = firstNumber  {
                answer = firstNumber/value
            } else {
                firstNumber = value
            }
        }
        let value = Value(number: answer, boolean: nil, text: nil)
        return Cell(value: value,formula: nil)
    }

    // MARK: - Calculate is Equal

    private func calculateIsEqual(formula: [Formula], referenceDictionary: [String: Value]) -> Cell? {
        var firstNumber: Double?
        var answer: Bool = false
        for reference in formula {
            let cell = Cell(value: reference.value, formula: reference, error: nil)
            let calculation = calculateAnswer(cell: cell, referenceDictionary: referenceDictionary)
            guard let value = calculation?.value?.number else { return nil }
            if let firstNumber = firstNumber  {
                answer = firstNumber == value
            } else {
                firstNumber = value
            }
        }
        let value = Value(number: nil, boolean: answer, text: nil)
        return Cell(value: value, formula: nil)
    }

    // MARK: - Calculate Not

    private func calculateNot(formula: Formula, referenceDictionary: [String: Value]) -> Cell? {
        var answer: Bool?
        let cell = Cell(value: formula.value, formula: formula, error: nil)
        let calculation = calculateAnswer(cell: cell, referenceDictionary: referenceDictionary)
        guard let valuee = calculation?.value?.boolean else { return nil }
        answer = !valuee
        let value = Value(number: nil, boolean: answer, text: nil)
        return Cell(value: value, formula: nil)
    }

    // MARK: - Calculate And

    private func calculateAnd(formula: [Formula], referenceDictionary: [String: Value]) -> Cell? {
        var firstAnswer: Bool?
        var finalAnswer = Cell(value: nil, formula: nil, error: nil)
        for reference in formula {
            let cell = Cell(value: reference.value, formula: reference, error: nil)
            let calculation = calculateAnswer(cell: cell, referenceDictionary: referenceDictionary)
            guard let value = calculation?.value?.boolean else { return nil }
            if let firstAnswer = firstAnswer {
                let answer = firstAnswer && value
                finalAnswer.value = Value(number: nil, boolean: answer, text: nil)
            } else {
                firstAnswer = value
            }
        }
        return finalAnswer
    }

    // MARK: - Calculate Or

    private func calculateOr(formula: [Formula], referenceDictionary: [String: Value]) -> Cell? {
        var firstAnswer: Bool?
        var finalAnswer = Cell(value: nil, formula: nil, error: nil)
        for reference in formula {
            let cell = Cell(value: reference.value, formula: reference, error: nil)
            let calculation = calculateAnswer(cell: cell, referenceDictionary: referenceDictionary)
            guard let value = calculation?.value?.boolean else { return nil }
            if let firstAnswer = firstAnswer {
                let answer = firstAnswer || value
                finalAnswer.value = Value(number: nil, boolean: answer, text: nil)
            } else {
                firstAnswer = value
            }
        }
        return finalAnswer
    }

    // MARK: - Calculate If

    private func calculateIf(formula: [Formula], referenceDictionary: [String: Value]) -> Cell? {
        var finalAnswer = Cell(value: nil, formula: nil, error: nil)
        var answer: Bool?
        let cell = Cell(value: nil, formula: formula[0], error: nil)
        let calculation = calculateAnswer(cell: cell, referenceDictionary: referenceDictionary)
        guard let value = calculation?.value?.boolean else { return nil }
        answer = value
        
        if answer == true {
            guard let reference = formula[1].reference else { return nil }
            let value = referenceDictionary[reference]?.number
            finalAnswer.value = Value(number: value, boolean: nil, text: nil)
        }

        if answer == false {
            guard let reference = formula[2].reference else { return nil }
            let value = referenceDictionary[reference]?.number
            finalAnswer.value = Value(number: value, boolean: nil, text: nil)
        }
        return finalAnswer
    }

    // MARK: - Calculate Concat

    private func calculateConcat(formula: [Formula], referenceDictionary: [String: Value]) -> Cell? {
        var text = ""
        for reference in formula {
            let cell = Cell(value: reference.value, formula: reference, error: nil)
            let calculation = calculateAnswer(cell: cell, referenceDictionary: referenceDictionary)
            guard let value = calculation?.value?.text else { return nil }
            text += value
        }
        var answerValue = Value(number: nil, boolean: nil, text: nil)
        answerValue.text = text
        var jobAnswer = Cell(value: nil, formula: nil, error: nil)
        jobAnswer.value = answerValue
        return jobAnswer
    }


    // MARK: - Helpers
    
    private func checkReferencesInReverseOrder(jobData: inout[[Cell]], referenceDictionary: inout[String: Value]) {
        var yIndex = jobData.count - 1
        for row in jobData.reversed() {
            var xIndex = row.count - 1
            for column in row.reversed() {
                if let columnValue = column.formula?.reference {
                    let answer = Cell(
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
    
    private func updateReferenceDictionary(jobData: [[Cell?]], referenceDictionary: inout[String: Value]) {
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
