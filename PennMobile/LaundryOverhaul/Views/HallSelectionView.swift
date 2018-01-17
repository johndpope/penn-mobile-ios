//
//  HallSelectionView.swift
//  PennMobile
//
//  Created by Josh Doman on 11/12/17.
//  Copyright © 2017 PennLabs. All rights reserved.
//

protocol HallSelectionViewDelegate: class {
    func updateSelectedHalls(for halls: [LaundryHall])
    func handleFailureToLoadDictionary()
}

class HallSelectionView: UIView, IndicatorEnabled {
    
    // delegating function to pass value to LaundryOverhaulViewController
    weak var delegate: HallSelectionViewDelegate?
    
    let maxNumHalls = 3
    
    public fileprivate(set) var chosenHalls = [LaundryHall]()
    
    // buildings and currentResult to update TableView
    fileprivate var buildings = [String: [LaundryHall]]()
    fileprivate var currentResults = [String: [LaundryHall]]()
    
    // current sort for the headers
    fileprivate var currentSort: [String]!
    
    // Views
    fileprivate var tableView: UITableView = UITableView()
    fileprivate lazy var searchBar = UISearchBar()
    fileprivate let emptyView: EmptyView = {
        let ev = EmptyView()
        ev.isHidden = true
        return ev
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // delegation
        searchBar.delegate = self
        self.tableView.delegate = self
        self.tableView.dataSource = self        
    }
    
    public func prepare(with halls: [LaundryHall]?) {
        if let chosenHalls = halls {
            self.chosenHalls = chosenHalls
        }
        // set up view and gesture recognizer
        setUpView()
        setupDictionaries()
        setupCurrentSort()
        selectChosenHalls()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// Mark: - Setup
extension HallSelectionView {
    fileprivate func setUpView() {
        self.backgroundColor = UIColor.white
        addSubview(searchBar)
        addSubview(tableView)
        addSubview(emptyView)
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        setUpSearchBar()
        setUpTableView()
        setUpEmptyView()
    }
    
    fileprivate func setUpSearchBar() {
        searchBar.searchBarStyle = UISearchBarStyle.prominent
        searchBar.placeholder = "Search..."
        searchBar.sizeToFit()
        searchBar.isTranslucent = false
        searchBar.backgroundImage = UIImage()
        searchBar.delegate = self
        searchBar.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
        searchBar.leftAnchor.constraint(equalTo: leftAnchor, constant: 0).isActive = true
        searchBar.rightAnchor.constraint(equalTo: rightAnchor, constant: 0).isActive = true
        searchBar.heightAnchor.constraint(equalToConstant: 60).isActive = true
    }
    
    fileprivate func setUpTableView() {
        self.tableView.rowHeight = 50
        _ = tableView.anchor(searchBar.bottomAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, topConstant: 0, leftConstant: 0, bottomConstant: 0, rightConstant: 0, widthConstant: 0, heightConstant: 0)
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.tableView.allowsMultipleSelection = true
    }
    
    fileprivate func setUpEmptyView() {
        _ = emptyView.anchor(tableView.topAnchor, left: tableView.leftAnchor, bottom: tableView.bottomAnchor, right: tableView.rightAnchor, topConstant: 0, leftConstant: 0, bottomConstant: 0, rightConstant: 0, widthConstant: 0, heightConstant: 0)
    }
    
    fileprivate func setupCurrentSort() {
        self.currentSort = sortHeaders(for: Array(buildings.keys))
    }
}

// Mark: - Sorting
extension HallSelectionView {
    fileprivate func sortHeaders(for headers: [String]) -> [String] {
        return headers.sorted {
            let count1 = buildings[$0]!.filter({ (hall) -> Bool in
                return chosenHalls.contains(hall)
            }).count
            
            let count2 = buildings[$1]!.filter({ (hall) -> Bool in
                return chosenHalls.contains(hall)
            }).count
            
            if count1 == count2 {
                return $0 == "Quad" // By default, make the quad appear first
            }
            
            return count1 > count2
        }
    }
    
    fileprivate func setupDictionaries() {
        guard let hallsDict: [Int: LaundryHall] = LaundryAPIService.instance.idToHalls else {
            attemptToLoadDictionary()
            return
        }
        
        for (_, hall) in hallsDict {
            let building = hall.building
            if building != "Unknown" {
                if buildings[building] == nil {
                    var hallsForBuilding = [LaundryHall]()
                    hallsForBuilding.append(hall)
                    buildings[building] = hallsForBuilding
                } else {
                    buildings[building]!.append(hall)
                }
            }
        }
        
        for (building, halls) in buildings {
            buildings[building] = halls.sorted(by: { (hall1, hall2) -> Bool in
                return hall1.id < hall2.id
            })
        }
        
        for hall in chosenHalls.reversed() {
            var arr = buildings[hall.building]
            if let index = arr?.index(of: hall) {
                arr?.remove(at: index)
            }
            arr?.insert(hall, at: 0)
            buildings[hall.building] = arr
        }
        
        currentResults = buildings
    }
}

// Mark: - Hall Selection
extension HallSelectionView {
    public func selectChosenHalls() {
        for hall in chosenHalls {
            if let index = getCurrentIndex(for: hall) {
                tableView.selectRow(at: index, animated: false, scrollPosition: .none)
            }
        }
    }
    
    private func getCurrentIndex(for hall: LaundryHall) -> IndexPath? {
        if let section = currentSort.index(where: { (building) -> Bool in
            return building == hall.building
        }), let halls = currentResults[hall.building] {
            if let row = halls.index(of: hall) {
                return IndexPath(row: row, section: section)
            }
        }
        return nil
    }
    
    fileprivate func attemptToLoadDictionary() {
        showActivity()
        LaundryAPIService.instance.loadIds { (success) in
            DispatchQueue.main.async {
                self.hideActivity()
                if !success {
                    self.delegate?.handleFailureToLoadDictionary()
                    return
                }
                
                self.setupDictionaries()
                self.setupCurrentSort()
                self.tableView.reloadData()
            }
        }
    }
}

// Mark: Functions implementing TableView
extension HallSelectionView: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return currentResults.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let key = currentSort[section]
        return currentResults[key]!.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return currentSort[section]
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath as IndexPath)
        let key = currentSort[indexPath.section]
        let hall = currentResults[key]![indexPath.row]
        cell.textLabel?.text = hall.name
        cell.accessoryType = cell.isSelected ? .checkmark : .none
        cell.selectionStyle = .none
        if chosenHalls.contains(hall) {
            cell.accessoryType = .checkmark
            cell.textLabel?.textColor = .black
        } else {
            cell.textLabel?.textColor = chosenHalls.count == maxNumHalls ? UIColor.lightGray : UIColor.black
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return chosenHalls.count < maxNumHalls ? indexPath : nil
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let key = currentSort[indexPath.section]
        let hall = currentResults[key]![indexPath.row]
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        chosenHalls.append(hall)
        
        if chosenHalls.count == maxNumHalls {
            tableView.reloadData()
            selectChosenHalls()
        }
        
        delegate?.updateSelectedHalls(for: chosenHalls)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let key = currentSort[indexPath.section]
        let hall = currentResults[key]![indexPath.row]
        if let index = chosenHalls.index(of: hall) {
            chosenHalls.remove(at: index)
            tableView.cellForRow(at: indexPath)?.accessoryType = .none
        }
        
        if chosenHalls.count == maxNumHalls - 1 {
            tableView.reloadData()
            selectChosenHalls()
        }
        delegate?.updateSelectedHalls(for: chosenHalls)
    }
    
    // Resigns the keyboard if up once the user starts to scroll through the listings
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if searchBar.isFirstResponder {
            searchBar.resignFirstResponder()
        }
    }
}

// Mark: Functions implementing SearchBar
extension HallSelectionView: UISearchBarDelegate, UISearchDisplayDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            currentResults = buildings
            currentSort = sortHeaders(for: Array(buildings.keys))
            self.showEmptyViewIfNeeded()
            tableView.reloadData()
            selectChosenHalls()
            return
        }
        
        currentResults = [String: [LaundryHall]]()
        for (building, laundryHalls) in buildings {
            if building.lowercased().contains(searchText.lowercased()) {
                currentResults[building] = laundryHalls
            } else {
                var toAdd:[LaundryHall]  = []
                for hall in laundryHalls {
                    if hall.name.lowercased().contains(searchText.lowercased()) {
                        toAdd.append(hall)
                    }
                }
                if !toAdd.isEmpty {
                    currentResults[building] = toAdd
                }
            }
        }
        currentSort = sortHeaders(for: Array(currentResults.keys))
        self.showEmptyViewIfNeeded()
        tableView.reloadData()
        selectChosenHalls()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if searchBar.isFirstResponder {
            searchBar.resignFirstResponder()
        }
    }
    
}

// Mark: Functions implementing EmptyView
extension HallSelectionView {
    internal func showEmptyViewIfNeeded() {
        emptyView.isHidden = !currentResults.isEmpty
        tableView.isHidden = currentResults.isEmpty
    }
}

extension HallSelectionView {
    override func resignFirstResponder() -> Bool {
        return searchBar.resignFirstResponder()
    }
}
