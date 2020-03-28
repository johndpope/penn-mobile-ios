//
//  DiningAPI.swift
//  PennMobile
//
//  Created by Josh Doman on 8/5/17.
//  Copyright © 2017 PennLabs. All rights reserved.
//

import SwiftyJSON
import Foundation

class DiningAPI: Requestable {
    
    static let instance = DiningAPI()
    
    let diningUrl = "https://api.pennlabs.org/dining/venues"
    let diningPrefs =  "https://api.pennlabs.org/dining/preferences"
    let diningBalanceUrl = "https://api.pennlabs.org/dining/balance"
    let diningInsightsUrl = "https://studentlife.pennlabs.org/dining/"
    
    private let venuesDataStore: LocalJSONStore<DiningAPIResponse> = LocalJSONStore(storageType: .cache, filename: "venues.json")
    
    private let insightsDataStore: LocalJSONStore<DiningInsightsAPIResponse> = LocalJSONStore(storageType: .cache, filename: "insights.json")
    
    private init() {
        _ = self.getInsights()
    }

    func fetchDiningHours(_ completion: @escaping (_ success: Bool, _ error: Bool) -> Void) {
        
        getRequestData(url: diningUrl) { (data, error, statusCode) in
            if statusCode == nil {
                completion(false, false)
                return
            }
            
            if statusCode != 200 {
                completion(false, true)
                return
            }
            
            guard let data = data else { completion(false, true); return }
            
            if let diningAPIResponse = try? JSONDecoder().decode(DiningAPIResponse.self, from: data) {
                DiningDataStore.shared.store(response: diningAPIResponse)
                completion(true, false)
            } else {
                completion(false, true)
            }
        }
    }

    func fetchDiningInsights(_ completion: @escaping (_ result: Result<DiningInsightsAPIResponse, NetworkingError>) -> Void ) {
        OAuth2NetworkManager.instance.getAccessToken { (token) in
            guard let token = token else {
                completion(.failure(.other))
                return
            }
            
            let url = URL(string: self.diningInsightsUrl)!
            var request = URLRequest(url: url, accessToken: token)
            request.httpMethod = "GET"
            
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                guard let data = data else {
                   if let error = error as? NetworkingError {
                       completion(.failure(error))
                   } else {
                       completion(.failure(.other))
                   }
                   return
                }
                
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                if let diningInsightsAPIResponse = try? decoder.decode(DiningInsightsAPIResponse.self, from: data) {
                    DiningDataStore.shared.saveToCache(insights: diningInsightsAPIResponse)
                    completion(.success(diningInsightsAPIResponse))
                } else {
                    completion(.failure(.parsingError))
                }
            }
            task.resume()
        }
        
        
        
    }
    
    func getCachedDiningInsights() -> DiningInsightsAPIResponse? {
        return DiningDataStore.shared.getInsights()
    }
    
    func fetchDetailPageHTML(for venue: DiningVenue, _ completion: @escaping (_ html: String?) -> Void) {
        DispatchQueue.global(qos: .background).async {
            guard let url = venue.facilityURL else { return }
            let html = try? String(contentsOf: url, encoding: .ascii)
            completion(html)
        }
    }
}

// MARK: - Dining Balance API
extension DiningAPI {
    func fetchDiningBalance(_ completion: @escaping (_ diningBalance: DiningBalance?) -> Void) {
        OAuth2NetworkManager.instance.getAccessToken { (token) in
            guard let token = token else {
                completion(nil)
                return
            }
            
            let url = URL(string: self.diningBalanceUrl)!
            let request = URLRequest(url: url, accessToken: token)
            
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let httpResponse = response as? HTTPURLResponse, let data = data, httpResponse.statusCode == 200 {
                    let json = JSON(data)
                    let balance = json["balance"]
                    if let diningDollars = balance["dining_dollars"].float,
                        let swipes = balance["swipes"].int,
                        let guestSwipes = balance["guest_swipes"].int,
                        let timestamp = balance["timestamp"].string {

                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                        if let lastUpdated = formatter.date(from: timestamp){
                            let balance = DiningBalance(diningDollars: diningDollars, visits: swipes, guestVisits: guestSwipes, lastUpdated: lastUpdated)
                            completion(balance)
                            return
                        }
                    }
                }
                completion(nil)
            }
            task.resume()
        }
    }
}

// Dining Data Storage
extension DiningAPI {
    
    func getVenues() -> [DiningVenue] {
        return venuesDataStore.storedValue?.document.venues ?? []
    }
    
    func getSectionedVenues() -> [DiningVenue.VenueType : [DiningVenue]] {
        var venuesDict = [DiningVenue.VenueType : [DiningVenue]]()
        for type in DiningVenue.VenueType.allCases {
            venuesDict[type] = getVenues().filter({ $0.venueType == type })
        }
        return venuesDict
    }
    
    func getVenues(with ids: Set<Int>) -> [DiningVenue] {
        return getVenues().filter({ ids.contains($0.id) })
    }
    
    func getInsights() -> DiningInsightsAPIResponse? {
        return insightsDataStore.storedValue
    }
    
    func saveToCache(insights: DiningInsightsAPIResponse) {
        insightsDataStore.save(insights)
    }
    
}
