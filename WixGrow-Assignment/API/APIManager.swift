//
//  APIManager.swift
//  WixGrow-Assignment
//
//  Created by Lukas Adomavicius on 3/31/21.
//

import Foundation

struct APIManager {
    
    enum APIHTTPMethod {
        static let post = "POST"
    }
    
    private var session: URLSession {
        let configuration = URLSessionConfiguration.default
        return URLSession(configuration: configuration)
    }
    
    // MARK: - Get All Jobs
    
    func getJobs(_ completion: @escaping (Result<JobResponse, APIError>) -> Void) {

        guard let url = APIEndpoint.jobs.url
        else {
            completion(.failure(.failedURLCreation))
            return
        }

        session.dataTask(with: url) { data, response, error in
            guard let data = data
            else {
                completion(.failure(.failedRequest))
                return
            }

            guard let jobsResponse = try? JSONDecoder().decode(JobResponse.self, from: data)
            else {
                completion(.failure(.unexpectedDataFormat))
                return
            }
            completion(.success(jobsResponse))
        }.resume()
    }
    
    // MARK: - Post Answers
    
    func postAnswers(
        submitAnswerRequest: SubmitAnswerRequest,
        submitUrl: String,
        _ completion: @escaping (Result<PostAnswersResponse, APIError>) -> Void
    ) {
        guard let url = URL(string: submitUrl)
        else {
            completion(.failure(.failedURLCreation))
            return
        }
        
        guard let requestJSON = try? JSONEncoder().encode(submitAnswerRequest)
        else {
            completion(.failure(.unexpectedDataFormat))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = APIHTTPMethod.post
        request.httpBody = requestJSON
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        session.dataTask(with: request) { data, response, error in
            guard let data = data
            else {
                completion(.failure(.failedRequest))
                return
            }

            guard let postResponse = try? JSONDecoder().decode(PostAnswersResponse.self, from: data)
            else {
                completion(.failure(.unexpectedDataFormat))
                return
            }
            completion(.success(postResponse))
        }.resume()
    }
}
