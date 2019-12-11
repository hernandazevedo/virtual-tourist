//
//  DetailViewController.swift
//  virtual-tourist
//
//  Created by Hernand Azevedo on 09/12/19.
//  Copyright © 2019 Hernand Azevedo. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class DetailViewController: UIViewController {
    var pin: Pin!
    var dataController: DataController!
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    
    
    @IBOutlet weak var newCollectionBtn: UIButton!
    var blockOperations = [BlockOperation]()
    var activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureMapViewDelegate()
    }
    
    func setCollectionViewLoadingState(_ isLoading: Bool) {
        if isLoading {
            let yAxis = (collectionView.frame.minY) + (collectionView.frame.maxY - collectionView.frame.minY)/2
            activityIndicator.frame = CGRect(x: (view.frame.maxX/2) - 10, y: yAxis, width: 20, height: 20)
            activityIndicator.color = UIColor.darkGray
            activityIndicator.hidesWhenStopped = true
            view.addSubview(activityIndicator)
            DispatchQueue.main.async {
                self.activityIndicator.startAnimating()
                UIApplication.shared.beginIgnoringInteractionEvents()
                self.collectionView.alpha = 0.5
            }
        } else {
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                UIApplication.shared.endIgnoringInteractionEvents()
                self.collectionView.alpha = 1.0
            }
        }
    }
    
}

extension DetailViewController: MKMapViewDelegate {
    
    func configureMapViewDelegate() {
        mapView.delegate = self
        mapView.isUserInteractionEnabled = false
        centerRegion()
        addAnnotation()
    }
    
    func centerRegion() {
        let center = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        let region = MKCoordinateRegion(center: center, span: span)
        mapView.setRegion(region, animated: true)
    }
    
    func addAnnotation() {
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        annotation.title = pin.name
        mapView.addAnnotation(annotation)
    }
}

extension DetailViewController: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            blockOperations.append(BlockOperation(block: {
                self.collectionView.insertItems(at: [newIndexPath!])
            }))
        case .delete:
            blockOperations.append(BlockOperation(block: {
                self.collectionView.deleteItems(at: [indexPath!])
            }))
        case .update:
            collectionView.reloadItems(at: [indexPath!])
        case .move:
            collectionView.moveItem(at: indexPath!, to: newIndexPath!)
        default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.performBatchUpdates({
            for operation in self.blockOperations {
                operation.start()
            }
        }) { (completed) in }
        self.newCollectionBtn.isEnabled = true
        if UIApplication.shared.isIgnoringInteractionEvents {
            setCollectionViewLoadingState(false)
        }
    }
    
    func setupFetchedResults() {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = []
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
}
