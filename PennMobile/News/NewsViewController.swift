//
//  NewsViewController.swift
//  PennMobile
//
//  Created by Josh Doman on 5/4/17.
//  Copyright © 2017 PennLabs. All rights reserved.
//

import UIKit

class NewsViewController: GenericViewController, HairlineRemovable {
    
    private let urlArray = ["http://thedp.com/", "http://thedp.com/blog/under-the-button/", "http://34st.com/"]
    
    private var webview: GenericWebview!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "News"
        
        setupNavBar()
        setupWebview()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        webview.hideActivity()
    }
    
    override func setupNavBar() {
        //removes hairline from bottom of navbar
        if let navbar = navigationController?.navigationBar {
            removeHairline(from: navbar)
        }
        
        let width = view.frame.width
        
        var headerHeight: CGFloat = 44
        if let headerFrame = navigationController?.navigationBar.frame {
            headerHeight = headerFrame.height + headerFrame.origin.y
        }
        
        let headerToolbar = UIToolbar(frame: CGRect(x: 0, y: 64, width: width, height: headerHeight))
        headerToolbar.backgroundColor = navigationController?.navigationBar.backgroundColor
        
        let newsSwitcher = UISegmentedControl(items: ["theDP", "UTB", "34th Street"])
        newsSwitcher.center = CGPoint(x: width/2, y: 64 + headerToolbar.frame.size.height/2)
        newsSwitcher.tintColor = UIColor.navRed
        newsSwitcher.selectedSegmentIndex = 0
        newsSwitcher.isUserInteractionEnabled = true
        newsSwitcher.addTarget(self, action: #selector(switchNewsSource(_:)), for: .valueChanged)
        
        view.addSubview(headerToolbar)
        view.addSubview(newsSwitcher)
    }
    
    private func setupWebview() {
        
        var headerHeight: CGFloat = 44
        if let headerFrame = navigationController?.navigationBar.frame {
            headerHeight = headerFrame.height + headerFrame.origin.y
        }
        headerHeight += 64
        
        webview = GenericWebview(frame: CGRect(x: 0, y: headerHeight, width: self.view.bounds.width, height: self.view.bounds.height - headerHeight))
        view.addSubview(webview)
        webview.loadRequest(URLRequest(url: URL(string: urlArray[0])!))
    }
    
    @objc internal func switchNewsSource(_ segment: UISegmentedControl) {
        webview.loadRequest(URLRequest(url: URL(string: urlArray[segment.selectedSegmentIndex])!))
    }
}
