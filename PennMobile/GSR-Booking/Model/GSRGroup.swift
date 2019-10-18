//
//  GSRGroup.swift
//  PennMobile
//
//  Created by Josh Doman on 4/6/19.
//  Copyright © 2019 PennLabs. All rights reserved.
//

import Foundation

struct GSRGroup {
    let id: String
    let name: String
    let imgURL: String
    let color: String
    let owners: [GSRGroupMember]
    let members: [GSRGroupMember]
    let createdAt: Date
    let isActive: Bool
    let reservations: [String] //array of reservationID's
}

struct GSRGroupMember {
    let accountID: String
    let pennKey: String
    let first: String
    let last: String
    let email: String?
    let isBookingEnabled: Bool
    let isAdmin: Bool
}
