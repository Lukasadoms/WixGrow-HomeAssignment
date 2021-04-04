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
    let notationArray = ["A", "B", "C", "D", "E", "F", "G", "H", "I"]
    let xs = (97...122).map({Character(UnicodeScalar($0))})
    //let name = "\(xs[0])1"

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
        //calculateResults()
        guard let jobResponse = jobResponse else { return }

        var submitAnswerRequest = SubmitAnswerRequest(results: [])
        
        for i in 0..<jobResponse.jobs.count - 0 {
            let result = calculateJob(job: jobResponse.jobs[i])
            submitAnswerRequest.results.append(result)
        }
        postAnswers(submitAnswerRequest: submitAnswerRequest, submitUrl: jobResponse.submissionURL)
    }
    
    
    func calculateJob(job: Job) -> JobResult? {
        var jobAnswer = JobResult(id: job.id, data: [[]])
        var data: [[JobData]] = [[]]
        var referenceDictionary: [String: Value] = [:]
        
        guard let jobData = job.data else { return nil }
        
        if jobData.isEmpty {
            return JobResult(id: job.id, data: [])
        }
        updateDictionary(jobData: jobData, referenceDictionary: &referenceDictionary)
//        for (Aindex, row) in jobData.enumerated() {
//            for (Bindex, column) in row.enumerated() {
//                referenceDictionary["\(notationArray[Bindex])\(Aindex+1)"] = column?.value
//            }
//        }
        print(referenceDictionary)
        
        copyValues(jobData: jobData, data: &data, referenceDictionary: referenceDictionary)
        calculateFormula(jobData: jobData, data: &data, referenceDictionary: &referenceDictionary)
        
        jobAnswer.data = data
        
        return jobAnswer
    }
    
    func copyValues(jobData: [[JobData?]], data: inout[[JobData]], referenceDictionary: [String: Value] ){
        var index = 0
        
        for row in jobData {
            for column in row {
                if let columnValue = column?.value {
                    let jobData = JobData(value: columnValue, formula: nil)
                    if data.indices.contains(index) {
                        data[index].append(jobData)
                    } else {
                        data.append([])
                        data[index].append(jobData)
                    }
                }
            }
            index += 1
        }
    }
    
    func calculateFormula(
        jobData: [[JobData?]],
        data: inout[[JobData]],
        referenceDictionary: inout[String: Value]
    ) {
        var index = 0
        for row in jobData {
            for column in row {
                if let columnValue = column?.formula {
                    if let reference = columnValue.reference {
                        let jobDataa = JobData(
                            value: referenceDictionary[reference],
                            formula: nil
                        )
                        if data.indices.contains(index) {
                            data[index].append(jobDataa)
                        } else {
                            data.append([])
                            data[index].append(jobDataa)
                        }
                        updateDictionary(jobData: data, referenceDictionary: &referenceDictionary)
                    }
                    if let sum = columnValue.sum {
                        var answer: Double = 0
                        for reference in sum {
                            guard let value = referenceDictionary[reference.reference]?.number else { return }
                            answer += value
                        }
                        data[index].append(JobData(
                                        value: Value(number: answer, boolean: nil, text: nil),
                                        formula: nil))
                    }
                    if let multiplication = columnValue.multiply {
                        var answer: Double = 1
                        for reference in multiplication {
                            guard let value = referenceDictionary[reference.reference]?.number else { return }
                            answer *= value
                        }
                        data[index].append(JobData(
                                        value: Value(number: answer, boolean: nil, text: nil),
                                        formula: nil))
                    }
                    
                    if let divide = columnValue.divide {
                        var firstNumber: Double = 0
                        var answer: Double = 1
                        for reference in divide {
                            guard let value = referenceDictionary[reference.reference]?.number else { return }
                            if firstNumber != 0  {
                                answer = firstNumber/value
                            } else {
                                firstNumber = value
                            }
                        }
                        data[index].append(JobData(
                                        value: Value(number: answer, boolean: nil, text: nil),
                                        formula: nil))
                    }
                    
                    if let function = columnValue.isGreater {
                        let result = calculateIsGreater(function: function, referenceDictionary: referenceDictionary)
                        let answer = Value(number: nil, boolean: result, text: nil)
                        data[index].append(JobData(value: answer, formula: nil) )
                    }
                    
                    if let isEqual = columnValue.isEqual{
                        var firstNumber: Double = 0
                        var answer: Bool = false
                        for reference in isEqual {
                            guard let value = referenceDictionary[reference.reference]?.number else { return }
                            if firstNumber != 0  {
                                answer = firstNumber == value
                            } else {
                                firstNumber = value
                            }
                        }
                        data[index].append(JobData(
                                        value: Value(number: nil, boolean: answer, text: nil),
                                        formula: nil))
                    }
                    
                    if let not = columnValue.not {
                        var answer: Bool = false
                        guard let value = referenceDictionary[not.reference]?.boolean else { return }
                        answer = !value
                        data[index].append(JobData(
                                        value: Value(number: nil, boolean: answer, text: nil),
                                        formula: nil))
                    }
                    
                    if let and = columnValue.and {
                        var answer: Bool?
                        var finalAnswer = JobData(value: nil, formula: nil, error: nil)
                        for reference in and {
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
                        data[index].append(finalAnswer)
                    }
                    
                    if let or = columnValue.or {
                        var answer: Bool?
                        var finalAnswer = JobData(value: nil, formula: nil, error: nil)
                        for reference in or {
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
                        data[index].append(finalAnswer)
                    }
                    
                    if let function = columnValue.formulaIf {
                        var answer: Bool?
                        var finalAnswer = JobData(value: nil, formula: nil, error: nil)
                        for reference in function {
                            if let isGreater = reference.isGreater {
                                answer = calculateIsGreater(function: isGreater, referenceDictionary: referenceDictionary)
                            }
                        }
                        guard let answerr = answer else { return }
                        if answerr {
                            let value = referenceDictionary[function[1].reference!]?.number
                            finalAnswer.value = Value(number: value, boolean: nil, text: nil)
                        } else {
                            let value = referenceDictionary[function[2].reference!]?.number
                            finalAnswer.value = Value(number: value, boolean: nil, text: nil)
                        }
                        data[index].append(finalAnswer)
                    }
                    
                    if let function = columnValue.concat {
                        var jobAnswer = JobData(value: nil, formula: nil, error: nil)
                        var answerValue = Value(number: nil, boolean: nil, text: nil)
                        var text = ""
                        for value in function {
                            text += value.value.text
                        }
                        answerValue.text = text
                        jobAnswer.value = answerValue
                        data[index].append(jobAnswer)
                    }
                }
            }
            index += 1
        }
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
    
    func calculateIsGreater(function: [Reference], referenceDictionary: [String: Value]) -> Bool? {
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
    
    func updateDictionary(jobData: [[JobData?]], referenceDictionary: inout[String: Value]){
        for (Aindex, row) in jobData.enumerated() {
            for (Bindex, column) in row.enumerated() {
                referenceDictionary["\(notationArray[Bindex])\(Aindex+1)"] = column?.value
            }
        }
    }
}

