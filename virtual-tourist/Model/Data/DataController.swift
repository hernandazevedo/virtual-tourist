//
//  DataController.swift
//  virtual-tourist
//
//  Created by Hernand Azevedo on 25/11/19.
//  Copyright © 2019 Hernand Azevedo. All rights reserved.
//

import Foundation
import CoreData

class DataController {
    let persistentContainer: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    init(name: String) {
        persistentContainer = NSPersistentContainer(name: name)
    }
    
    func loadPersistentStores(completion: (() -> Void)? = nil) {
        persistentContainer.loadPersistentStores { (store, error) in
            
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            self.saveViewContext()
            completion?()
            
        }
    }
    

}

extension DataController {
    func saveViewContext(interval: TimeInterval = 30) {
        print("Saving View Context")
        
        if viewContext.hasChanges {
            try? viewContext.save()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            self.saveViewContext(interval: interval)
        }
    }
}
