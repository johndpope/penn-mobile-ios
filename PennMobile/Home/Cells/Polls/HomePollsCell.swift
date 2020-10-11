//
//  HomePollsCell.swift
//  PennMobile
//
//  Created by Lucy Yuewei Yuan on 9/19/20.
//  Copyright © 2020 PennLabs. All rights reserved.
//

import Foundation
import UIKit

final class HomePollsCell: UITableViewCell, HomeCellConformable {
    var delegate: ModularTableViewCellDelegate!
    static var identifier: String = "pollsCell"
    
    var item: ModularTableViewItem! {
        didSet {
            guard let item = item as? HomePollsCellItem else { return }
            setupCell(with: item)
        }
    }
    
    static func getCellHeight(for item: ModularTableViewItem) -> CGFloat {
        guard let item = item as? HomePollsCellItem else { return 0.0 }
        let numPolls = CGFloat(item.pollQuestion.options?.count ?? 0)
        let pollHeight = numPolls * PollOptionCell.cellHeight
        return (pollHeight + HomeCellHeader.height + (Padding.pad * 3))
    }
    
    var pollQuestion: PollQuestion!
    
    // MARK: - UI Elements
    var cardView: UIView! = UIView()
    fileprivate var safeArea: HomeCellSafeArea = HomeCellSafeArea()
    fileprivate var header: HomeCellHeader = HomeCellHeader()
    fileprivate var responsesTableView: UITableView!
    
    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        prepareHomeCell()
        prepareUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Setup UI Elements
extension HomePollsCell {
    fileprivate func setupCell(with item: HomePollsCellItem) {
        pollQuestion = item.pollQuestion
        responsesTableView.reloadData()
        header.secondaryTitleLabel.text = "Poll FROM \(pollQuestion.source ?? "some source")"
        header.primaryTitleLabel.text = item.pollQuestion.title
    }
}



// MARK: - Initialize & Layout UI Elements
extension HomePollsCell {
    fileprivate func prepareUI() {
        prepareSafeArea()
        prepareHeader()
        prepareTableView()
    }
    
    // MARK: Safe Area and Header
    fileprivate func prepareSafeArea() {
        cardView.addSubview(safeArea)
        safeArea.prepare()
    }
    
    fileprivate func prepareHeader() {
        safeArea.addSubview(header)
        header.prepare()
    }

    // MARK: TableView
    fileprivate func prepareTableView() {
        responsesTableView = getTableView()
        cardView.addSubview(responsesTableView)
        responsesTableView.snp.makeConstraints { (make) in
            make.leading.equalTo(cardView)
            make.top.equalTo(header.snp.bottom).offset(pad)
            make.trailing.equalTo(cardView)
            make.bottom.equalTo(cardView).offset(-pad)
        }
    }
}

extension HomePollsCell: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? PollOptionCell {
            cell.question = Array((pollQuestion.options?.keys)!)[indexPath.row]
            cell.responseRate = Array((pollQuestion.options?.values)!)[indexPath.row]
            cell.answered = pollQuestion.userChosen == -1 ? false : true
            cell.chosen = pollQuestion.userChosen == indexPath.row ? true : false
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 110
    }
}


extension HomePollsCell: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pollQuestion?.options?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PollOptionCell.identifier, for: indexPath) as! PollOptionCell
        
        return cell
    }
}

extension HomePollsCell {
    fileprivate func getTableView() -> UITableView {
        let tableView = UITableView()
        tableView.backgroundColor = .clear
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.register(PollOptionCell.self, forCellReuseIdentifier: PollOptionCell.identifier)
        return tableView
    }
}
