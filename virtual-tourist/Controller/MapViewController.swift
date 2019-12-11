//
//  ViewController.swift
//  virtual-tourist
//
//  Created by Hernand Azevedo on 12/11/19.
//  Copyright © 2019 Hernand Azevedo. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    var dataController: DataController!
    var locationFetchedResultController: NSFetchedResultsController<Location>!
    var pinsFetchedResultsController: NSFetchedResultsController<Pin>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        setupLocationFetchRequest()
        configuraCenteredLocation()
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleHolddown))
        longPressGesture.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longPressGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupPinFetchResults()
        loadSavedAnnotations()
        deselectPins()
    }
    
    fileprivate func deselectPins() {
        if mapView.selectedAnnotations.count > 0 {
            mapView.deselectAnnotation(mapView.selectedAnnotations[0], animated: true)
        }
    }
    
    func configuraCenteredLocation() {
        let center = CLLocationCoordinate2D(latitude: locationFetchedResultController.fetchedObjects?.first?.latitude ?? 30.33182, longitude: locationFetchedResultController.fetchedObjects?.first?.longitude ?? -120.03118)
        let span = MKCoordinateSpan(latitudeDelta: locationFetchedResultController.fetchedObjects?.first?.latitudeDelta ?? 0.02, longitudeDelta: locationFetchedResultController.fetchedObjects?.first?.longitudeDelta ?? 0.02)
        let region = MKCoordinateRegion(center: center, span: span)
        mapView.setRegion(region, animated: true)
    }
    
    @objc func handleHolddown(uiLongPressGestureRecognizer: UILongPressGestureRecognizer) {
        if uiLongPressGestureRecognizer.state == .ended {
            let point = uiLongPressGestureRecognizer.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)

            addCoordinate(coordinate: coordinate)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        locationFetchedResultController = nil
        pinsFetchedResultsController = nil
    }
    
    fileprivate func getSelectedPin() -> Pin? {
//        setupPinFetchResults()
        if let pins = pinsFetchedResultsController.fetchedObjects {
            let annotation = mapView.selectedAnnotations[0]
            guard let indexPath = pins.firstIndex(where: { (pin) -> Bool in
                pin.latitude == annotation.coordinate.latitude && pin.longitude == annotation.coordinate.longitude
            }) else {
                return nil
            }
            return pins[indexPath]
        }
        return nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let detailViewController = segue.destination as? DetailViewController {
            guard let pin = getSelectedPin() else {
                showErrorMessage("Error getting selected pin")
                return
            }
            detailViewController.pin = pin
            detailViewController.dataController = dataController
        }
    }

}

extension MapViewController: MKMapViewDelegate {
    
    func addCoordinate(coordinate: CLLocationCoordinate2D) {
        activityIndicatorView.startAnimating()
        let annotation = MKPointAnnotation()
        setCoordinateName(coordinate: coordinate) { (location, error) in
            self.activityIndicatorView.stopAnimating()
            if let error = error {
                self.showErrorMessage("Place not found: \(error.localizedDescription)")
                annotation.coordinate = coordinate
                annotation.title = "Unknown"
                self.saveAnnotation(annotation: annotation)
                self.mapView.addAnnotation(annotation)
            } else {
                 annotation.coordinate = coordinate
                 annotation.title = location
                 self.saveAnnotation(annotation: annotation)
                 self.mapView.addAnnotation(annotation)
            }
        }
    }
    
    func saveAnnotation(annotation: MKPointAnnotation) {
        let pin = Pin(context: dataController.viewContext)
        pin.latitude = annotation.coordinate.latitude
        pin.longitude = annotation.coordinate.longitude
        pin.name = annotation.title
        
        try? dataController.viewContext.save()
    }
    
    func loadSavedAnnotations() {
        if let fetchedPins = pinsFetchedResultsController.fetchedObjects {
            if fetchedPins.count > 0 {
                for pin in fetchedPins {
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
                    annotation.title = pin.name
                    mapView.addAnnotation(annotation)
                }
            }
        }
    }
    
    private func setCoordinateName(coordinate: CLLocationCoordinate2D, completion: @escaping (String?, Error?) -> Void) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { (placemarks, error) in
            if let error = error {
                self.showErrorMessage("Error setting coordinate name: \(error.localizedDescription)")
                completion(nil, error)
            } else {
                if let placemarks = placemarks, let placemark = placemarks.first {
                    if let locality = placemark.locality {
                        completion(locality, nil)
                    }
                }
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        deleteLocations()
        let location = Location(context: dataController.viewContext)
        let region = mapView.region
        location.longitude = region.center.longitude
        location.latitude = region.center.latitude
        
        location.longitudeDelta = region.span.longitudeDelta
        location.latitudeDelta = region.span.latitudeDelta
        
        try? dataController.viewContext.save()
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        performSegue(withIdentifier: "locationDetailSegue", sender: nil)
    }
}

extension MapViewController: NSFetchedResultsControllerDelegate {
    
    fileprivate func setupPinFetchResults() {
        activityIndicatorView.startAnimating()
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        
        fetchRequest.sortDescriptors = []
        
        pinsFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        pinsFetchedResultsController.delegate = self
        
        do {
            try pinsFetchedResultsController.performFetch()
        } catch {
            showErrorMessage("Error fetching pins: \(error.localizedDescription)")
        }
        activityIndicatorView.stopAnimating()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        do {
            try controller.performFetch()
        } catch {
            showErrorMessage("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    func setupLocationFetchRequest() {
        
        let fetchRequest: NSFetchRequest<Location> = Location.fetchRequest()
        
        fetchRequest.sortDescriptors = []
        
        locationFetchedResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        locationFetchedResultController.delegate = self
        
        do {
            try locationFetchedResultController.performFetch()
        } catch {
            showErrorMessage("Error fetching location: \(error.localizedDescription)")
        }
        
    }
    
    func deleteLocations() {
        let fetchDelete = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchDelete)
        
        do {
            try dataController.viewContext.execute(deleteRequest)
            try dataController.viewContext.save()
        } catch {
            showErrorMessage("Error deleting locations: \(error.localizedDescription)")
        }
        
    }
}

