//
//  AppDelegate.swift
//  virtual-tourist
//
//  Created by Hernand Azevedo on 12/11/19.
//  Copyright © 2019 Hernand Azevedo. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    let dataController = DataController(name: "VirtualTouristStore")

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        dataController.loadPersistentStores()
        
        let navigationController = window?.rootViewController as? UINavigationController
        let mapViewController = navigationController?.topViewController as? MapViewController
        mapViewController?.dataController = dataController

        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
       saveContext()
    }

    func applicationWillTerminate(_ application: UIApplication) {
       saveContext()
    }

    func saveContext() {
       try? dataController.viewContext.save()
    }
}

