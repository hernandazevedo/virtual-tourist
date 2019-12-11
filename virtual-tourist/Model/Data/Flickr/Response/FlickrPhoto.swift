//
//  FlickrPhoto.swift
//  virtual-tourist
//
//  Created by Hernand Azevedo on 11/12/19.
//  Copyright © 2019 Hernand Azevedo. All rights reserved.
//

import Foundation

struct FlickrPhoto: Codable {
    let id: String
    let owner: String
    let secret: String
    let server: String
    let farm: Int
    let title: String
}
