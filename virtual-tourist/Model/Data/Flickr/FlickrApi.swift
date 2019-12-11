//
//  FlickrApi.swift
//  virtual-tourist
//
//  Created by Hernand Azevedo on 11/12/19.
//  Copyright © 2019 Hernand Azevedo. All rights reserved.
//

import Foundation
class FlickrAPI {
    
    static let apiKey = "4881e4eea63e28d9da4d2bd07360be73"
    
    enum Endpoints {
        static let base = "https://api.flickr.com/services/rest/"
        static let apiKeyParam = "&api_key=\(FlickrAPI.apiKey)"
        static let jsonFormatParam = "&format=json&nojsoncallback=1"
        
        case searchPhotosWithCoordinate(latitude: Double, longitude: Double, itemPerPage: Int, page: Int)
        
        var stringValue: String {
            switch self {
            case .searchPhotosWithCoordinate(let latitude, let longitude, let itemPerPage, let page):
                return Endpoints.base + "?method=flickr.photos.search" + Endpoints.apiKeyParam + "&lat=\(latitude)" + "&lon=\(longitude)" + "&per_page=\(itemPerPage)" + "&page=\(page)" + Endpoints.jsonFormatParam
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    class func getSearchPhotosResults(latitude: Double, longitude: Double, itemPerPage: Int, page: Int, completion: @escaping (Int?, [FlickrPhoto]?, Error?) -> Void) {
        
        let url = Endpoints.searchPhotosWithCoordinate(latitude: latitude, longitude: longitude, itemPerPage: itemPerPage, page: page).url
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, nil, error!)
                }
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let response = try decoder.decode(PhotosResponses.self, from: data)
                completion(response.photos.totalPages, response.photos.photo, nil)
            } catch {
                do {
                    let errorResponse = try decoder.decode(ErrorResponses.self, from: data)
                    DispatchQueue.main.async {
                        completion(nil, nil, errorResponse)
                    }
                } catch {
                    DispatchQueue.main.async {
                        print(String(data: data, encoding: .utf8)!)
                        completion(nil, nil, error)
                    }
                }
            }
        }
        task.resume()
    }
    
    class func getPhotoData(url: URL, completion: @escaping (Data?, URL, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                completion(nil, url, error!)
                return
            }
            completion(data, url, nil)
        }
        task.resume()
    }
    
    class func createPhotoURLsFrom(photos: [FlickrPhoto], size: String = "q") -> [URL] {
        var urls = [URL]()
        for photo in photos {
            let photoURL = URL(string: "https://farm\(photo.farm).staticflickr.com/\(photo.server)/\(photo.id)_\(photo.secret)_\(size).jpg")!
            urls.append(photoURL)
        }
        return urls
    }
    
}
