//
//  MapViewController.swift
//  PennMobile
//
//  Created by Dominic Holmes on 8/3/18.
//  Copyright © 2018 PennLabs. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
    
    fileprivate var mapView: MKMapView?
    
    var searchTerm: String?
    
    var building: BuildingMapDisplayable? {
        didSet {
            guard let building = building else { return }
            self.region = building.getRegion()
            self.annotation = building.getAnnotation()
        }
    }
    
    var venue: DiningVenueName? {
        didSet {
            guard let venue = venue else { return }
            self.region = PennCoordinate.shared.getRegion(for: venue, at: .close)
            self.annotation = PennCoordinate.shared.getAnnotation(for: venue)
        }
    }
    
    var facility: FitnessFacilityName? {
        didSet {
            guard let facility = facility else { return }
            self.region = PennCoordinate.shared.getRegion(for: facility, at: .close)
            self.annotation = PennCoordinate.shared.getAnnotation(for: facility)
        }
    }
    
    var region: MKCoordinateRegion = PennCoordinate.shared.getDefaultRegion(at: .far) {
        didSet {
            if let _ = mapView {
                mapView?.setRegion(region, animated: false)
            }
        }
    }
    var annotation: MKAnnotation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMap()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.title = "Penn Map"
        
        guard let searchTerm = searchTerm else { return }
        self.region = MKCoordinateRegion.init(center: PennCoordinate.shared.getDefault(), latitudinalMeters: PennCoordinateScale.mid.rawValue, longitudinalMeters: PennCoordinateScale.mid.rawValue)
        self.getCoordinates(for: searchTerm) { (coordinates, title) in
            DispatchQueue.main.async {
                if let coordinates = coordinates {
                    self.region = MKCoordinateRegion.init(center: coordinates, latitudinalMeters: PennCoordinateScale.mid.rawValue, longitudinalMeters: PennCoordinateScale.mid.rawValue)
                    if let title = title {
                        let thisAnnotation = MKPointAnnotation()
                        thisAnnotation.coordinate = coordinates
                        thisAnnotation.title = title
                        thisAnnotation.subtitle = title
                        self.annotation = thisAnnotation
                        self.mapView?.addAnnotation(thisAnnotation)
                    }
                } else {
                    self.region = MKCoordinateRegion.init(center: PennCoordinate.shared.getDefault(), latitudinalMeters: PennCoordinateScale.mid.rawValue, longitudinalMeters: PennCoordinateScale.mid.rawValue)
                }
            }
        }
    }
}

extension MapViewController {
    
    fileprivate func setupMap() {
        mapView = getMapView()
        view.addSubview(mapView!)
        NSLayoutConstraint.activate([
            mapView!.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView!.topAnchor.constraint(equalTo: view.topAnchor),
            mapView!.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView!.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
    }
}

extension MapViewController {
    
    fileprivate func getMapView() -> MKMapView {
        let mv = MKMapView(frame: view.frame)
        mv.setRegion(region, animated: false)
        if annotation != nil { mv.addAnnotation(annotation!) }
        mv.translatesAutoresizingMaskIntoConstraints = false
        return mv
    }
}

extension MapViewController {
    func getCoordinates(for searchTerm: String, _ callback: @escaping (_ coordinates: CLLocationCoordinate2D?, _ title: String?) -> Void) {
        let url = URL(string: "https://mobile.apps.upenn.edu/mobile/jsp/fast.do?webService=googleMapsSearch&searchTerm=\(searchTerm)")!
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let data = data, let json = try? JSON(data: data), let locationJSON = json.arrayValue.first {
                if let latitudeStr = locationJSON["latitude"].string, let longitudeStr = locationJSON["longitude"].string, let title = locationJSON["title"].string {
                    if let latitude = Double(latitudeStr), let longitude = Double(longitudeStr) {
                        let coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                        callback(coordinates, title)
                        return
                    }
                }
            }
            callback(nil, nil)
        }
        task.resume()
    }
}
