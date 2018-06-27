//
//  BuildingFoodMenuCell.swift
//  PennMobile
//
//  Created by dominic on 6/26/18.
//  Copyright © 2018 PennLabs. All rights reserved.
//

import UIKit

struct DiningMenuItem {
    var name: String!
    var details: String?
    var specialties: [DiningMenuItemType]
}

enum DiningMenuItemType {
    case vegan, lowGluten, seafood, vegetarian, jain
}

class BuildingFoodMenuCell: BuildingCell {
    
    static let identifier = "BuildingFoodMenuCell"
    static let cellHeight: CGFloat = 250
    
    override var venue: DiningVenue! {
        didSet {
            let tempMenu = [
                DiningMenuItem(name: "Corn", details: "some corn", specialties: [.vegan, .vegetarian]),
                DiningMenuItem(name: "Spaghettigeddon", details: "by clint", specialties: [.jain, .lowGluten]),
                DiningMenuItem(name: "Grilled Magicarp", details: "*struggles*", specialties: [.seafood]),
                DiningMenuItem(name: "Mystery Meat", details: "sold by a traveling salesman", specialties: []),
            ]
            setupCell(with: venue, menu: tempMenu)
        }
    }
    
    fileprivate var menu: [DiningMenuItem?]? {
        didSet {
            menuTableView.reloadData()
        }
    }
    
    fileprivate let safeInsetValue: CGFloat = 14
    fileprivate var safeArea: UIView!
    
    fileprivate var menuTableView: UITableView!
    
    // MARK: - Init
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        prepareUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Setup Cell
extension BuildingFoodMenuCell {
    
    fileprivate func setupCell(with venue: DiningVenue, menu: [DiningMenuItem?]) {
        self.menu = menu
        menuTableView.reloadData()
    }
}

// MARK: - Menu Table View Datasource
extension BuildingFoodMenuCell: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menu?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: DiningMenuItemCell.identifier) as? DiningMenuItemCell else { return UITableViewCell() }
        guard let menu = menu, menu.count > indexPath.row else { return UITableViewCell() }
        
        if let item = menu[indexPath.row] {
            cell.menuItem = item
        }
        return cell
    }
}

// MARK: - Menu Table View Delegate
extension BuildingFoodMenuCell: UITableViewDelegate {
    
}

// MARK: - Initialize and Prepare UI
extension BuildingFoodMenuCell {
    
    fileprivate func prepareUI() {
        prepareSafeArea()

        layoutTableView()
    }
    
    // MARK: Safe Area
    fileprivate func prepareSafeArea() {
        safeArea = getSafeAreaView()
        addSubview(safeArea)
        NSLayoutConstraint.activate([
            safeArea.leadingAnchor.constraint(equalTo: leadingAnchor, constant: safeInsetValue),
            safeArea.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -safeInsetValue),
            safeArea.topAnchor.constraint(equalTo: topAnchor, constant: safeInsetValue),
            safeArea.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -safeInsetValue)
            ])
    }
    
    // MARK: Layout Labels
    fileprivate func layoutTableView() {
        
        menuTableView = getTableView()
        addSubview(menuTableView)
        
        _ = menuTableView.anchor(safeArea.topAnchor, left: safeArea.leftAnchor, bottom: safeArea.bottomAnchor, right: safeArea.rightAnchor)
    }
    
    fileprivate func getTableView() -> UITableView {
        let tableView = UITableView()
        tableView.register(DiningMenuItemCell.self, forCellReuseIdentifier: DiningMenuItemCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }
    
    fileprivate func getDayLabel() -> UILabel {
        let label = UILabel()
        label.font = .interiorTitleFont
        label.textColor = UIColor.informationYellow
        label.textAlignment = .left
        label.text = "Day"
        return label
    }
    
    fileprivate func getHourLabel() -> UILabel{
        let label = UILabel()
        label.font = .interiorTitleFont
        label.textColor = UIColor.informationYellow
        label.textAlignment = .right
        label.text = "Hour"
        return label
    }
    
    fileprivate func getSafeAreaView() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }
}
