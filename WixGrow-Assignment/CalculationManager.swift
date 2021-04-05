//
//  CalculationManager.swift
//  WixGrow-Assignment
//
//  Created by Lukas Adomavicius on 4/5/21.
//

import Foundation

class CalculationManager {
    
    private var dictionaryManager = DictionaryManager()
    
    init(dictionaryManager: DictionaryManager) {
        self.dictionaryManager = DictionaryManager()
    }
    
    func calculateJob(job: Job) -> Job {
        var referenceDictionary: [String: Value] = [:]
        var jobAnswer = job
        dictionaryManager.updateDictionary(jobData: jobAnswer.data, referenceDictionary: &referenceDictionary)
        calculateAnswer(jobData: &jobAnswer.data, referenceDictionary: &referenceDictionary)
        return jobAnswer
    }
    
    private func calculateAnswer(
        jobData: inout[[JobData]],
        referenceDictionary: inout[String: Value]
    ) {
        var yIndex = 0
        for row in jobData {
            var xIndex = 0
            for column in row {
                if let columnValue = column.formula?.reference {
                    calculateReference(reference: columnValue,
                                       referenceDictionary: referenceDictionary,
                                       yIndex: yIndex,
                                       xIndex: xIndex,
                                       jobData: &jobData
                    )
                    dictionaryManager.updateDictionary(jobData: jobData, referenceDictionary: &referenceDictionary)
                }
                if let columnValue = column.formula?.sum {
                    calculateSum(columnValue: columnValue,
                                 referenceDictionary: referenceDictionary,
                                 yIndex: yIndex,
                                 xIndex: xIndex,
                                 data: &jobData
                    )
                }
                if let columnValue = column.formula?.multiply {
                    calculateMultiplication(columnValue: columnValue,
                                            referenceDictionary: referenceDictionary,
                                            yIndex: yIndex,
                                            xIndex: xIndex,
                                            jobData: &jobData
                    )
                }
                if let columnValue = column.formula?.divide {
                    calculateDivision(columnValue: columnValue,
                                      referenceDictionary: referenceDictionary,
                                      yIndex: yIndex,
                                      xIndex: xIndex,
                                      data: &jobData
                    )
                }
                if let columnValue = column.formula?.isGreater {
                    let result = calculateIsGreater(function: columnValue, referenceDictionary: referenceDictionary)
                    let answer = Value(number: nil, boolean: result, text: nil)
                    jobData[yIndex][xIndex] = JobData(value: answer, formula: nil)
                }
                if let columnValue = column.formula?.isEqual {
                    calculateIsEqual(columnValue: columnValue,
                                     referenceDictionary: referenceDictionary,
                                     yIndex: yIndex,
                                     xIndex: xIndex,
                                     jobData: &jobData
                    )
                }
                if let columnValue = column.formula?.not {
                    calculateNot(columnValue: columnValue,
                                 referenceDictionary: referenceDictionary,
                                 yIndex: yIndex,
                                 xIndex: xIndex,
                                 jobData: &jobData
                    )
                }
                if let columnValue = column.formula?.and {
                    calculateAnd(columnValue: columnValue,
                                 referenceDictionary: referenceDictionary,
                                 yIndex: yIndex,
                                 xIndex: xIndex,
                                 jobData: &jobData
                    )
                }
                if let columnValue = column.formula?.or {
                    calculateOr(columnValue: columnValue,
                                referenceDictionary: referenceDictionary,
                                yIndex: yIndex,
                                xIndex: xIndex,
                                jobData: &jobData
                    )
                }
                if let columnValue = column.formula?.formulaIf {
                    calculateIf(columnValue: columnValue,
                                referenceDictionary: referenceDictionary,
                                yIndex: yIndex,
                                xIndex: xIndex,
                                jobData: &jobData
                    )
                }
                if let columnValue = column.formula?.concat {
                    calculateConcat(columnValue: columnValue, referenceDictionary: referenceDictionary, yIndex: yIndex, xIndex: xIndex, jobData: &jobData)
                }
                xIndex += 1
            }
            yIndex += 1
        }
        checkReferencesInReverseOrder(jobData: &jobData, referenceDictionary: &referenceDictionary)
    }
    
    // MARK: - Calculate Reference
    
    private func calculateReference(reference: String,
                                    referenceDictionary: [String: Value],
                                    yIndex: Int, xIndex: Int,
                                    jobData: inout[[JobData]]
    ) {
        let answer = JobData(
            value: referenceDictionary[reference],
            formula: nil
        )
        if answer.value != nil {
            jobData[yIndex][xIndex] = answer
        }
    }
    
    // MARK: - Calculate Sum
    
    private func calculateSum(columnValue: [Reference],
                              referenceDictionary: [String: Value],
                              yIndex: Int,
                              xIndex: Int,
                              data: inout[[JobData]]
    ) {
        var answer: Double = 0
        for reference in columnValue {
            guard let value = referenceDictionary[reference.string]?.number else { return }
            answer += value
        }
        let value = Value(number: answer, boolean: nil, text: nil)
        data[yIndex][xIndex] = JobData(value: value,
                                       formula: nil)
    }
    
    // MARK: - Calculate Is Greater
    
    
    private func calculateIsGreater(function: [Reference],
                                    referenceDictionary: [String: Value]
    ) -> Bool? {
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
    
    private func calculateMultiplication(columnValue: [Reference],
                                         referenceDictionary: [String: Value],
                                         yIndex: Int,
                                         xIndex: Int,
                                         jobData: inout[[JobData]]
    ) {
        var answer: Double = 1
        for reference in columnValue {
            guard let value = referenceDictionary[reference.string]?.number else { return }
            answer *= value
        }
        let value = Value(number: answer, boolean: nil, text: nil)
        jobData[yIndex][xIndex] = JobData(value: value,
                                          formula: nil)
    }
    
    // MARK: - Calculate Division
    
    private func calculateDivision(columnValue: [Reference],
                                   referenceDictionary: [String: Value],
                                   yIndex: Int,
                                   xIndex: Int,
                                   data: inout[[JobData]]
    ) {
        var firstNumber: Double?
        var answer: Double?
        for reference in columnValue {
            guard let value = referenceDictionary[reference.string]?.number else { return }
            if let firstNumber = firstNumber  {
                answer = firstNumber/value
            } else {
                firstNumber = value
            }
        }
        let value = Value(number: answer, boolean: nil, text: nil)
        data[yIndex][xIndex] = JobData(value: value,formula: nil)
    }
    
    // MARK: - Calculate is Equal
    
    private func calculateIsEqual(columnValue: [Reference],
                                  referenceDictionary: [String: Value],
                                  yIndex: Int,
                                  xIndex: Int,
                                  jobData: inout[[JobData]]
    ) {
        var firstNumber: Double = 0
        var answer: Bool = false
        for reference in columnValue {
            guard let value = referenceDictionary[reference.string]?.number else { return }
            if firstNumber != 0  {
                answer = firstNumber == value
            } else {
                firstNumber = value
            }
        }
        jobData[yIndex][xIndex] = JobData(
            value: Value(number: nil, boolean: answer, text: nil),
            formula: nil)
    }
    
    // MARK: - Calculate Not
    
    private func calculateNot(columnValue: Reference,
                              referenceDictionary: [String: Value],
                              yIndex: Int,
                              xIndex: Int,
                              jobData: inout[[JobData]]
    ) {
        var answer: Bool = false
        guard let value = referenceDictionary[columnValue.string]?.boolean else { return }
        answer = !value
        jobData[yIndex][xIndex] = JobData(
            value: Value(number: nil, boolean: answer, text: nil),
            formula: nil)
    }
    
    // MARK: - Calculate And
    
    private func calculateAnd(columnValue: [Reference],
                              referenceDictionary: [String: Value],
                              yIndex: Int,
                              xIndex: Int,
                              jobData: inout[[JobData]]
    ) {
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
        jobData[yIndex][xIndex] = finalAnswer
    }
    
    // MARK: - Calculate Or
    
    private func calculateOr(columnValue: [Reference],
                             referenceDictionary: [String: Value],
                             yIndex: Int,
                             xIndex: Int,
                             jobData: inout[[JobData]]
    ) {
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
        jobData[yIndex][xIndex] = finalAnswer
    }
    
    // MARK: - Calculate If
    
    private func calculateIf(columnValue: [If],
                             referenceDictionary: [String: Value],
                             yIndex: Int,
                             xIndex: Int,
                             jobData: inout[[JobData]]
    ) {
        var answer: Bool?
        var finalAnswer = JobData(value: nil, formula: nil, error: nil)
        for reference in columnValue {
            if let isGreater = reference.isGreater {
                answer = calculateIsGreater(function: isGreater, referenceDictionary: referenceDictionary)
            }
        }
        guard let answerr = answer else { return }
        if answerr {
            let value = referenceDictionary[columnValue[1].reference!]?.number
            finalAnswer.value = Value(number: value, boolean: nil, text: nil)
        } else {
            let value = referenceDictionary[columnValue[2].reference!]?.number
            finalAnswer.value = Value(number: value, boolean: nil, text: nil)
        }
        jobData[yIndex][xIndex] = finalAnswer
    }
    
    // MARK: - Calculate Concat
    
    private func calculateConcat(columnValue: [Concat],
                                 referenceDictionary: [String: Value],
                                 yIndex: Int,
                                 xIndex: Int,
                                 jobData: inout[[JobData]]
    ) {
        var jobAnswer = JobData(value: nil, formula: nil, error: nil)
        var answerValue = Value(number: nil, boolean: nil, text: nil)
        var text = ""
        for reference in columnValue {
            text += reference.value.text
        }
        answerValue.text = text
        jobAnswer.value = answerValue
        jobData[yIndex][xIndex] = jobAnswer
    }
    
    // MARK: - Calculate References In Reverse Order
    
    private func checkReferencesInReverseOrder(jobData: inout[[JobData]], referenceDictionary: inout[String: Value]) {
        var yIndex = jobData.count - 1
        for row in jobData {
            var xIndex = row.count - 1
            for column in row.reversed() {
                if let columnValue = column.formula {
                    if let reference = columnValue.reference {
                        let answer = JobData(
                            value: referenceDictionary[reference],
                            formula: nil
                        )
                        jobData[yIndex][xIndex] = answer
                        dictionaryManager.updateDictionary(jobData: jobData, referenceDictionary: &referenceDictionary)
                    }
                }
                xIndex -= 1
            }
            yIndex -= 1
        }
    }
}
