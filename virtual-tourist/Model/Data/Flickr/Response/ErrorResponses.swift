//
//  ErrorResponses.swift
//  virtual-tourist
//
//  Created by Hernand Azevedo on 11/12/19.
//  Copyright © 2019 Hernand Azevedo. All rights reserved.
//

import Foundation

struct ErrorResponses: Codable {
    let stat: String
    let code: Int
    let message: String
}

extension ErrorResponses: LocalizedError {
    var errorDescription: String? {
        return message
    }
}
