//
//  ViewController.swift
//  WixGrow-Assignment
//
//  Created by Lukas Adomavicius on 3/31/21.
//

import UIKit

class ViewController: UIViewController {
    
    var apiManager = APIManager()
    var jobResponse: JobResponse?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getJobs()
    }
    
    func getJobs() {
        apiManager.getJobs ({ result in
            switch result {
            case .success (let jobs):
                DispatchQueue.main.async {
                    self.jobResponse = jobs
                }
            case .failure(let error):
                print(error)
            }
        })
    }
    
    @IBAction func calculateButtonPressed(_ sender: Any) {
        
        guard let jobResponse = jobResponse else { return }
        var submitAnswerRequest = SubmitAnswerRequest(results: [])
        for job in jobResponse.jobs {
            let result = calculateJob(job: job)
            submitAnswerRequest.results.append(result)
        }
        postAnswers(submitAnswerRequest: submitAnswerRequest, submitUrl: jobResponse.submissionURL)
    }
    
    
    func calculateJob(job: Job) -> Job {
        var referenceDictionary: [String: Value] = [:]
        var jobAnswer = job
        if jobAnswer.data.isEmpty {
            return Job(id: job.id, data: [])
        }
        updateDictionary(jobData: jobAnswer.data, referenceDictionary: &referenceDictionary)
        calculateFormula(jobData: &jobAnswer.data, referenceDictionary: &referenceDictionary)
        print(jobAnswer)
        return jobAnswer
    }
    
    func calculateFormula(
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
                    updateDictionary(jobData: jobData, referenceDictionary: &referenceDictionary)
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
                    
                if let columnValue = column.formula?.isEqual{
                    var firstNumber: Double = 0
                    var answer: Bool = false
                    for reference in columnValue {
                        guard let value = referenceDictionary[reference.reference]?.number else { return }
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
                    
                if let columnValue = column.formula?.not {
                    var answer: Bool = false
                    guard let value = referenceDictionary[columnValue.reference]?.boolean else { return }
                    answer = !value
                    jobData[yIndex][xIndex] = JobData(
                        value: Value(number: nil, boolean: answer, text: nil),
                        formula: nil)
                }
                    
                if let columnValue = column.formula?.and {
                    var answer: Bool?
                    var finalAnswer = JobData(value: nil, formula: nil, error: nil)
                    for reference in columnValue {
                        guard let value = referenceDictionary[reference.reference] else { return }
                        if let bool = value.boolean as? Bool {
                            if let answerr = answer {
                                answer = answerr && bool
                                finalAnswer.value = Value(number: nil, boolean: answer, text: nil)
                            } else {
                                answer = bool
                            }
                        } else {
                            finalAnswer.error = "error"
                        }
                    }
                    jobData[yIndex][xIndex] = finalAnswer
                }
                    
                if let columnValue = column.formula?.or {
                    var answer: Bool?
                    var finalAnswer = JobData(value: nil, formula: nil, error: nil)
                    for reference in columnValue {
                        guard let value = referenceDictionary[reference.reference] else { return }
                        if let bool = value.boolean as? Bool {
                            if let answerr = answer {
                                answer = answerr || bool
                                finalAnswer.value = Value(number: nil, boolean: answer, text: nil)
                            } else {
                                answer = bool
                            }
                        } else {
                            finalAnswer.error = "error"
                        }
                    }
                    jobData[yIndex][xIndex] = finalAnswer
                }
                    
                if let columnValue = column.formula?.formulaIf {
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
                    
                if let columnValue = column.formula?.concat {
                    var jobAnswer = JobData(value: nil, formula: nil, error: nil)
                    var answerValue = Value(number: nil, boolean: nil, text: nil)
                    var text = ""
                    for value in columnValue {
                        text += value.value.text
                    }
                    answerValue.text = text
                    jobAnswer.value = answerValue
                    jobData[yIndex][xIndex] = jobAnswer
                }
                xIndex += 1
            }
            yIndex += 1
        }
        checkReferencesInReverseOrder(jobData: &jobData, referenceDictionary: &referenceDictionary)
        
    }
    
    func postAnswers(submitAnswerRequest: SubmitAnswerRequest, submitUrl: String ) {
        apiManager.postAnswers(
            submitAnswerRequest: submitAnswerRequest,
            submitUrl: submitUrl
        ) { result in
            switch result {
            case .success(let response):
                DispatchQueue.main.async {
                    print(response)
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    print(error)
                }
            }
            
        }
    }
    
    func calculateReference(reference: String,
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
    
    func calculateSum(columnValue: [Reference],
                      referenceDictionary: [String: Value],
                      yIndex: Int,
                      xIndex: Int,
                      data: inout[[JobData]]
    ) {
        var answer: Double = 0
        for reference in columnValue {
            guard let value = referenceDictionary[reference.reference]?.number else { return }
            answer += value
        }
        let value = Value(number: answer, boolean: nil, text: nil)
        data[yIndex][xIndex] = JobData(value: value,
                                       formula: nil)
    }
    
    
    func calculateIsGreater(function: [Reference],
                            referenceDictionary: [String: Value]
    ) -> Bool? {
        var firstNumber: Double?
        var answer: Bool?
        for reference in function {
            guard let value = referenceDictionary[reference.reference] else { return nil }
            if let first = firstNumber {
                answer = first > value.number!
            } else {
                firstNumber = value.number!
            }
        }
        return answer
    }
    
    func calculateMultiplication(columnValue: [Reference],
                                 referenceDictionary: [String: Value],
                                 yIndex: Int,
                                 xIndex: Int,
                                 jobData: inout[[JobData]]
    ) {
        var answer: Double = 1
        for reference in columnValue {
            guard let value = referenceDictionary[reference.reference]?.number else { return }
            answer *= value
        }
        let value = Value(number: answer, boolean: nil, text: nil)
        jobData[yIndex][xIndex] = JobData(value: value,
                                       formula: nil)
    }
    
    func calculateDivision(columnValue: [Reference],
                           referenceDictionary: [String: Value],
                           yIndex: Int,
                           xIndex: Int,
                           data: inout[[JobData]]
    ) {
        var firstNumber: Double?
        var answer: Double?
        for reference in columnValue {
            guard let value = referenceDictionary[reference.reference]?.number else { return }
            if let firstNumber = firstNumber  {
                answer = firstNumber/value
            } else {
                firstNumber = value
            }
        }
        let value = Value(number: answer, boolean: nil, text: nil)
        data[yIndex][xIndex] = JobData(value: value,formula: nil)
    }
    
    func calculateIsEqual(columnValue: [Reference],
                          referenceDictionary: [String: Value],
                          yIndex: Int,
                          xIndex: Int,
                          jobData: inout[[JobData]]
   ) {
        var firstNumber: Double = 0
        var answer: Bool = false
        for reference in columnValue {
            guard let value = referenceDictionary[reference.reference]?.number else { return }
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
    
    func updateDictionary(jobData: [[JobData?]], referenceDictionary: inout[String: Value]){
        let notationArray = (97...122).map({Character(UnicodeScalar($0))}).map { $0.uppercased()}
        for (Aindex, row) in jobData.enumerated() {
            for (Bindex, column) in row.enumerated() {
                referenceDictionary["\(notationArray[Bindex])\(Aindex+1)"] = column?.value
            }
        }
    }
    
    func checkReferencesInReverseOrder(jobData: inout[[JobData]], referenceDictionary: inout[String: Value]) {
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
                        updateDictionary(jobData: jobData, referenceDictionary: &referenceDictionary)
                    }
                }
                xIndex -= 1
            }
            yIndex -= 1
        }
    }
    
    private func showAlert(error: String) {
        let alert = UIAlertController(title: error, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true, completion: nil)
    }
}

