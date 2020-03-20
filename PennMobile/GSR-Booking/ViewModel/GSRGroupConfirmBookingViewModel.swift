//
//  GSRGroupConfirmBookingViewModel.swift
//  PennMobile
//
//  Created by Rehaan Furniturewala on 3/13/20.
//  Copyright © 2020 PennLabs. All rights reserved.
//

import UIKit

class GSRGroupConfirmBookingViewModel: NSObject {
    fileprivate var groupBooking: GSRGroupBooking!
    init(groupBooking: GSRGroupBooking) {
        self.groupBooking = groupBooking
    }
}

// MARK: - UITableViewDataSource
extension GSRGroupConfirmBookingViewModel: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return GroupBookingConfirmationCell.getCellHeight(for: groupBooking.bookings[indexPath.row])
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupBooking.bookings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: GroupBookingConfirmationCell.identifier) as! GroupBookingConfirmationCell
        cell.setupCell(with: groupBooking.bookings[indexPath.row])
        return cell
    }
    
}

// MARK: - UITableViewDelegate
extension GSRGroupConfirmBookingViewModel: UITableViewDelegate {
    
}

// MARK: - Networking
extension GSRGroupConfirmBookingViewModel {
    func submitBooking() {
        GSRGroupNetworkManager.instance.submitBooking(booking: groupBooking, completion: { (groupBookingResponse, error)  in
            print(groupBookingResponse)
        })
    }
}
