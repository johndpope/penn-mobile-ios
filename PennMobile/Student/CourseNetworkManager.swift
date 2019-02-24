//
//  StudentNetworkManager.swift
//  PennMobile
//
//  Created by Josh Doman on 2/24/19.
//  Copyright © 2019 PennLabs. All rights reserved.
//

import Foundation
import SwiftSoup

class CourseNetworkManager: NSObject {
    
    static let instance = CourseNetworkManager()
    
    private let baseURL = "https://pennintouch.apps.upenn.edu/pennInTouch/jsp/fast2.do"
    private let courseURL = "https://pennintouch.apps.upenn.edu/pennInTouch/jsp/fast2.do?fastStart=mobileSchedule"
    
    func getCourses(request: URLRequest, cookies: [HTTPCookie], callback: @escaping ((_ courses: Set<Course>?) -> Void)) {
        var mutableRequest: URLRequest = request
        let cookieStr = cookies.map {"\($0.name)=\($0.value);"}.joined()
        mutableRequest.addValue(cookieStr, forHTTPHeaderField: "Cookie")
        
        let task = URLSession.shared.dataTask(with: mutableRequest, completionHandler: { (data, response, error) in
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    let setCookieStr = httpResponse.allHeaderFields["Set-Cookie"] as? String
                    let sessionID: String = setCookieStr?.getMatches(for: "=(.*?);").first ?? ""
                    let newCookieStr = cookieStr.removingRegexMatches(pattern: "JSESSIONID=(.*?);", replaceWith: "JSESSIONID=\(sessionID);")
                    mutableRequest.url = URL(string: self.courseURL)
                    self.getCourses(cookieStr: newCookieStr, callback: callback)
                    return
                }
            }
            callback(nil)
        })
        task.resume()
    }
    
    fileprivate func getCourses(cookieStr: String, terms: [String]? = nil, courses: Set<Course>? = nil, callback: @escaping ((_ courses: Set<Course>?) -> Void)) {
        if terms != nil && terms!.isEmpty {
            callback(courses)
            return
        }
        
        let url = URL(string: terms == nil ? courseURL: baseURL)!
        var request = URLRequest(url: url)
        request.httpMethod = terms == nil ? "GET" : "POST"
        request.addValue(cookieStr, forHTTPHeaderField: "Cookie")
        
        if let terms = terms {
            let params = [
                "fastStart": "mobileChangeStudentScheduleTermData",
                "term": terms[0],
                ]
            request.httpBody = params.stringFromHttpParameters().data(using: String.Encoding.utf8)
        }
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    if let data = data, let html = NSString(data: data, encoding: String.Encoding.utf8.rawValue) as String? {
                        do {
                            var newTerms = terms
                            if terms == nil {
                                newTerms = try self.parseTerms(from: html)
                            }
                            
                            var newCourses: Set<Course>? = nil
                            if let currentTerm = newTerms?.first {
                                newCourses = try self.parseCourses(from: html, term: currentTerm)
                            }
                            
                            if let oldCourses = courses {
                                newCourses?.formUnion(oldCourses)
                            }
                            
                            newTerms = Array(newTerms?.dropFirst() ?? [])
                            self.getCourses(cookieStr: cookieStr, terms: newTerms, courses: newCourses, callback: callback)
                            return
                        } catch {
                        }
                    }
                }
            }
            callback(nil)
        })
        task.resume()
    }
}

// MARK: - Course Parsing
extension CourseNetworkManager {
    fileprivate func parseCourses(from html: String, term: String) throws -> Set<Course> {
        let doc: Document = try SwiftSoup.parse(html)
        let element: Element = try doc.select("li").filter { $0.id() == "fullClassesDiv" }.first!
        var subHtml = try element.html()
        subHtml.append("<") // For edge case where instructor is at EOF
        let instructors: [String] = subHtml.getMatches(for: "Instructor\\(s\\): (.*?)\\s*<")
        let nameCodes: [String] = try element.select("b").map { try $0.text() }
        var courses = [Course]()
        for i in 0..<instructors.count {
            let courseInstructors = instructors[i].split(separator: ",").map { String($0) }
            let name = nameCodes[2*i]
            let fullCode = nameCodes[2*i+1].replacingOccurrences(of: " ", with: "")
            let codePieces = fullCode.split(separator: "-")
            let courseCode = "\(codePieces[0])-\(codePieces[1])"
            let section = String(codePieces[2])
            courses.append(Course(name: name, term: term, code: courseCode, section: section, instructors: courseInstructors))
        }
        return Set(courses)
    }
    
    fileprivate func parseTerms(from html: String) throws -> [String] {
        let doc: Document = try SwiftSoup.parse(html)
        let terms: [String] = try doc.select("option").map { try $0.val() }
        return terms
    }
}
