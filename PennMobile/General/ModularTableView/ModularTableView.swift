//
//  ModularTableView.swift
//  PennMobile
//
//  Created by Josh Doman on 3/5/18.
//  Copyright © 2018 PennLabs. All rights reserved.
//

import Foundation

final class ModularTableView: UITableView {
    var model: ModularTableViewModel! {
        didSet {
            self.dataSource = model
            self.delegate = model
            let btn = UIButton()
            backgroundColor = UIColor.yellow
            btn.backgroundColor = UIColor.green
            addSubview(btn)
            _ = btn.anchor(topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, topConstant: 5, leftConstant: 5, bottomConstant: 5, rightConstant: 5, widthConstant: 0, heightConstant: 0)
            btn.addTarget(self, action: #selector(test), for: UIControl.Event.touchUpInside)
        }
    }
    
    func registerTableView(for types: ModularTableViewItemTypes) {
        types.registerCells(for: self)


    }
    @objc func test() {
        print("i hate this")
    }

}
