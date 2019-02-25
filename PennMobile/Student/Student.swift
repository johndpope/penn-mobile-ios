//
//  Student.swift
//  PennMobile
//
//  Created by Josh Doman on 2/24/19.
//  Copyright © 2019 PennLabs. All rights reserved.
//

import Foundation

class Student: NSObject {
    let firstName: String
    let lastName: String
    let photoUrl: String
    
    var degrees: Set<Degree>?
    var courses: Set<Course>?
    
    init(firstName: String, lastName: String, photoUrl: String) {
        self.firstName = firstName
        self.lastName = lastName
        self.photoUrl = photoUrl
    }
}
