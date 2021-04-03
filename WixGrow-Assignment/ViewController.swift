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
        
        for i in 0..<jobResponse.jobs.count - 17 {
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
        
        for (Aindex, row) in jobData.enumerated() {
            for (Bindex, column) in row.enumerated() {
                referenceDictionary["\(notationArray[Bindex])\(Aindex+1)"] = column?.value
            }
        }
        print(referenceDictionary)
        
        copyValues(jobData: jobData, data: &data)
        calculateFormula(jobData: jobData, data: &data, referenceDictionary: referenceDictionary)
        
        jobAnswer.data = data
        
        return jobAnswer
    }
    
    func copyValues(jobData: [[JobData?]], data: inout[[JobData]] ) {
        for row in jobData {
            for column in row {
                if let columnValue = column?.value {
                    let jobData = JobData(value: columnValue, formula: nil)
                    data[0].append(jobData)
                }
            }
        }
    }
    
    func calculateFormula(
        jobData: [[JobData?]],
        data: inout[[JobData]],
        referenceDictionary: [String: Value]
    ) {
        for row in jobData {
            for column in row {
                if let columnValue = column?.formula {
                    if let reference = columnValue.reference {
                        let jobData = JobData(
                            value: referenceDictionary[reference],
                            formula: nil
                        )
                        data[0].append(jobData)
                    }
                    if let sum = columnValue.sum {
                        var answer: Double = 0
                        for reference in sum {
                            guard let value = referenceDictionary[reference.reference]?.number else { return }
                            answer += value
                        }
                        data[0].append(JobData(
                                        value: Value(number: answer, boolean: nil, text: nil),
                                        formula: nil))
                    }
                }
            }
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
}

