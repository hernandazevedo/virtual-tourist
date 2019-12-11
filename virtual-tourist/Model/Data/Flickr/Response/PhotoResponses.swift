//
//  PhotoResponses.swift
//  virtual-tourist
//
//  Created by Hernand Azevedo on 11/12/19.
//  Copyright © 2019 Hernand Azevedo. All rights reserved.
//

import Foundation

struct PhotoResponses: Codable {
    let currentPage: Int
    let totalPages: Int
    let itemsPerPage: Int
    let totalPhotos: String
    let photo: [FlickrPhoto]
    
    enum CodingKeys: String, CodingKey {
        case currentPage = "page"
        case totalPages = "pages"
        case itemsPerPage = "perpage"
        case totalPhotos = "total"
        case photo = "photo"
    }
}

struct PhotosResponses: Codable {
    let photos: PhotoResponses
    let stat: String
}
