//
//  FitnessFacilityData.swift
//  PennMobile
//
//  Created by dominic on 7/19/18.
//  Copyright © 2018 PennLabs. All rights reserved.
//

import Foundation

class FitnessFacilityData {
    
    static let shared = FitnessFacilityData()
    
    fileprivate var schedules = Dictionary<FitnessFacilityName, FitnessSchedule>()
    
    func load(inputSchedules: FitnessSchedules) {
        schedules = Dictionary<FitnessFacilityName, FitnessSchedule>()
        guard inputSchedules.schedules != nil else { return }
        for schedule in inputSchedules.schedules! {
            if schedule != nil {
                schedules[schedule!.name] = schedule
            }
        }
    }
    
    func getSchedule(for venue: FitnessFacilityName) -> FitnessSchedule? {
        dump(schedules)
        guard schedules.keys.contains(venue) else { return nil }
        return schedules[venue]
    }
    
    func clearMenus() {
        schedules = Dictionary<FitnessFacilityName, FitnessSchedule>()
    }
}