//
//  ItemAddingViewController.swift
//  AxReminder
//
//  Created by devedbox on 2017/7/18.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

extension ItemAddingViewController {
    class var preferedHeight: CGFloat { return 637.0 }
}

class ItemAddingViewController: TableViewController {
    @IBOutlet fileprivate weak var _mapView: MKMapView!
    @IBOutlet fileprivate weak var _mapFilterView: ItemAddingMapFilterView!
    @IBOutlet fileprivate var _textViews: [TextView]!
    
    public var imageAdding: (() -> Void)?
    private var _isViewDidAppear: Bool = false
    
    fileprivate lazy var _locationManager: CLLocationManager = { () -> CLLocationManager in 
        let manager = CLLocationManager()
        manager.distanceFilter = 5.0
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        return manager
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        _locationManager.delegate = self
        _mapFilterView.delegate = self
    }
    
    override func viewDidLoadSetup() {
        super.viewDidLoadSetup()
        
        _initializeCurrentLocation()
        _setupMapView()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44.0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if animated && !_isViewDidAppear {
            _showContentViews(animated)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        _isViewDidAppear = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

// MARK: - Actions.

extension ItemAddingViewController {
    @IBAction
    fileprivate func _handleToggleSegmentedControl(_ sender: UISegmentedControl) {
        _mapFilterView.drawingMode = sender.selectedSegmentIndex == 0 ? .outside : .inside
    }
    
    @IBAction
    fileprivate func _handleRequestLocation(_ sender: UIButton) {
        let region = _mapView.regionThatFits(MKCoordinateRegion(center: _mapView.centerCoordinate, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)))
        _mapView.setRegion(region, animated: true)
        _mapView.setCenter(_mapView.userLocation.coordinate, animated: true)
        _locationManager.requestLocation()
    }
    
    @IBAction
    fileprivate func _handleAddingImage(_ sender: UIButton) {
        imageAdding?()
    }
}

// MARK: - MKMapViewDelegate.

extension ItemAddingViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        /* if annotation is MKUserLocation {
            var pinnedView: MKPinAnnotationView
            let reusedIdentifier = "_UserPinnedAnnotationView"
            if let pin = mapView.dequeueReusableAnnotationView(withIdentifier: reusedIdentifier) {
                pinnedView = pin as! MKPinAnnotationView
            } else {
                pinnedView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reusedIdentifier)
            }
            return pinnedView
        } */
        return nil
    }
}

// MARK: - CLLocationManagerDelegate.

extension ItemAddingViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let alert = UIAlertController(title: NSLocalizedString("Notice", comment: "Notice"), message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard !locations.isEmpty else {
            return
        }
        let location = locations.first!
        UserDefaults.standard.setValue([UserDefaultsKey.LastUserLocation.coordinateLatitudeKey: location.coordinate.latitude, UserDefaultsKey.LastUserLocation.coordinateLongitudeKey: location.coordinate.longitude], forKey: UserDefaultsKey.LastUserLocation.key)
        UserDefaults.standard.synchronize()
        
        let region = _mapView.regionThatFits(MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)))
        _mapView.setRegion(region, animated: false)
        _mapView.setCenter(_mapView.userLocation.coordinate, animated: true)
        
        _locationManager.stopUpdatingLocation()
    }
}

// MARK: - ItemAddingMapFilterViewDelegate.

extension ItemAddingViewController: ItemAddingMapFilterViewDelegate {
    func mapFilterViewWillBeginUpdatingRadius(_ mapFilterView: ItemAddingMapFilterView) {
    }
    
    func mapFilterView(_ mapFilterView: ItemAddingMapFilterView, updatingRadius radius: CGFloat) {
        let center = mapFilterView.center
        let radiusPoint = CGPoint(x: center.x + radius, y: center.y)
        let centerCoordinate = _mapView.centerCoordinate
        let radiusCoordinate = _mapView.convert(radiusPoint, toCoordinateFrom: mapFilterView)
        
        let centerLocation = CLLocation(latitude: centerCoordinate.latitude, longitude: centerCoordinate.longitude)
        let radiusLocation = CLLocation(latitude: radiusCoordinate.latitude, longitude: radiusCoordinate.longitude)
        // Meters.
        let distance = centerLocation.distance(from: radiusLocation)
        _mapFilterView.distance = distance
    }
    
    func mapFilterViewDidEndUpdatingRadius(_ mapFilterView: ItemAddingMapFilterView) {
        let radius = mapFilterView.radius
        let scale = DefaultMapViewFilterRadius / radius
        
        let span = _mapView.region.span
        _mapView.setRegion(MKCoordinateRegion(center: _mapView.region.center, span: MKCoordinateSpan(latitudeDelta: span.latitudeDelta / Double(scale), longitudeDelta: span.longitudeDelta / Double(scale))), animated: false)
        
        mapFilterView.radius = radius * scale
    }
}

// MARK: - Private.

extension ItemAddingViewController {
    fileprivate func _showContentViews(_ animated: Bool) {
        guard animated else {
            return
        }
        
        let contentOffset = CGPoint(x: 0.0, y: -tableView.contentInset.top)
        let visibleCells = tableView.visibleCells
        for (index, cell) in visibleCells.enumerated() {
            cell.transform = CGAffineTransform(translationX: 0.0, y: tableView.bounds.height)
            UIView.animate(withDuration: 0.5, delay: 0.05 * Double(index), usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: [], animations: { [unowned self] in
                cell.transform = .identity
                self.tableView.contentOffset = contentOffset
                }, completion: nil)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05 * Double(visibleCells.count) / 2.0) { [unowned self] in
            self._textViews.first?.becomeFirstResponder()
        }
    }
    
    fileprivate func _initializeCurrentLocation() {
        _locationManager.delegate = self
        
        guard CLLocationManager.locationServicesEnabled() else {
            let alert = UIAlertController(title: NSLocalizedString("Notice", comment: "notice"), message: NSLocalizedString("InvalidLocation", comment: "InvalidLocation"), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Confirm", comment: "Confirm"), style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        // Ensure the status of authorization.
        let status = CLLocationManager.authorizationStatus()
        guard status == .authorizedWhenInUse else {
            _locationManager.requestWhenInUseAuthorization()
            return
        }
        _locationManager.requestLocation()
    }
    
    fileprivate func _setupMapView() {
        _mapView.userTrackingMode = .none
        
        let BeiJing = CLLocationCoordinate2D(latitude: 39.9, longitude: 116.4)
        var location: CLLocationCoordinate2D
        var spanDelta: CLLocationDegrees
        if let lastUserLocation = UserDefaults.standard.dictionary(forKey: UserDefaultsKey.LastUserLocation.key) as? [String: CGFloat] {
            location = CLLocationCoordinate2D(latitude: CLLocationDegrees(lastUserLocation[UserDefaultsKey.LastUserLocation.coordinateLatitudeKey]!), longitude: CLLocationDegrees(lastUserLocation[UserDefaultsKey.LastUserLocation.coordinateLongitudeKey]!))
            spanDelta = 0.005
        } else {
            location = BeiJing
            spanDelta = 0.1
        }
        
        _mapView.setRegion(MKCoordinateRegion(center: location, span: MKCoordinateSpan(latitudeDelta: spanDelta, longitudeDelta: spanDelta)), animated: false)
        _mapView.setCenter(location, animated: false)
    }
}

// MARK: - Storyboard Supporting.

extension ItemAddingViewController {
    public class var storyboardId: String {
        return "_ItemAddingViewController"
    }
}

extension ItemAddingViewController: StoryboardLoadable {
    public class func instance(from storyboard: UIStoryboard) -> Self? {
        return _instanceViewControllerFromStoryboard(storyboard)
    }
    // Private hooks.
    private class func _instanceViewControllerFromStoryboard<T>(_ storyboard: UIStoryboard) -> T? {
        return storyboard.instantiateViewController(withIdentifier: storyboardId) as? T
    }
}
