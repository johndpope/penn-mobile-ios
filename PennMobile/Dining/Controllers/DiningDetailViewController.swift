//
//  DiningDetailViewController.swift
//  PennMobile
//
//  Created by Josh Doman on 3/31/17.
//  Copyright © 2017 PennLabs. All rights reserved.
//

import UIKit

class DiningDetailViewController: UITableViewController {
    
    var venue: DiningVenue! {
        didSet {
            updateUI(with: venue)
            self.tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerHeadersAndCells(for: self.tableView)
        self.view.backgroundColor = .yellow
    }
}

// MARK: - Setup and Update UI
extension DiningDetailViewController {

    fileprivate func updateUI(with venue: DiningVenue) {

    }
}

// MARK: - UITableViewDataSource
extension DiningDetailViewController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0: return BuildingHeaderCell.cellHeight
        case 1: return BuildingImageCell.cellHeight
        case 2: return BuildingMapCell.cellHeight
        default: return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : BuildingCell
        switch indexPath.row {
        case 0: cell = tableView.dequeueReusableCell(withIdentifier: BuildingHeaderCell.identifier, for: indexPath) as! BuildingHeaderCell
        case 1: cell = tableView.dequeueReusableCell(withIdentifier: BuildingImageCell.identifier, for: indexPath) as! BuildingImageCell
        case 2: cell = tableView.dequeueReusableCell(withIdentifier: BuildingMapCell.identifier, for: indexPath) as! BuildingMapCell
        default: cell = BuildingCell()
        }
        cell.venue = self.venue
        return cell
    }
    
    func registerHeadersAndCells(for tableView: UITableView) {
        tableView.register(BuildingHeaderCell.self, forCellReuseIdentifier: BuildingHeaderCell.identifier)
        tableView.register(BuildingImageCell.self, forCellReuseIdentifier: BuildingImageCell.identifier)
        tableView.register(BuildingMapCell.self, forCellReuseIdentifier: BuildingMapCell.identifier)
    }
}

// MARK: - UITableViewDelegate
extension DiningDetailViewController {
    /*override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: BuildingHeaderView.identifier) as! BuildingHeaderView
        view.venue = self.venue
        return view
    }*/
    
    /*override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return BuildingHeaderView.headerHeight
    }*/

}
