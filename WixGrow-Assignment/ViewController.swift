//
//  ViewController.swift
//  WixGrow-Assignment
//
//  Created by Lukas Adomavicius on 3/31/21.
//

import UIKit

class ViewController: UIViewController {
    
    var apiManager = APIManager()
    var calculationManager = CalculationManager(dictionaryManager: DictionaryManager())
    var jobResponse: JobResponse?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getJobs()
    }
    
    private func getJobs() {
        apiManager.getJobs ({ result in
            switch result {
            case .success (let jobs):
                DispatchQueue.main.async {
                    self.jobResponse = jobs
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.showAlert(error: error.errorDescription)
                }
            }
        })
    }
    
    @IBAction func calculateButtonPressed(_ sender: Any) {
        
        guard let jobResponse = jobResponse else { return }
        var submitAnswerRequest = SubmitAnswerRequest(results: [])
        for job in jobResponse.jobs {
            let result = calculationManager.calculateJob(job: job)
            submitAnswerRequest.results.append(result)
        }
        postAnswers(submitAnswerRequest: submitAnswerRequest, submitUrl: jobResponse.submissionURL)
    }
    
    private func postAnswers(submitAnswerRequest: SubmitAnswerRequest, submitUrl: String ) {
        apiManager.postAnswers(
            submitAnswerRequest: submitAnswerRequest,
            submitUrl: submitUrl
        ) { result in
            switch result {
            case .success(let response):
                DispatchQueue.main.async {
                    if let message = response.message {
                        self.showAlert(error: message)
                    }
                    if let error = response.error {
                        self.showAlert(error: error)
                    }
                    
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.showAlert(error: error.errorDescription)
                }
            }
            
        }
    }
    
    private func showAlert(error: String) {
        let alert = UIAlertController(title: error, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true, completion: nil)
    }
}

