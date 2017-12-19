//
//  ViewController.swift
//  App
//
//  Created by Mark Hall on 2017-12-19.
//

import Vapor
import HTTP

struct ViewController {
    
    func addRoutes(to drop: Droplet) {
        drop.get("") { req in
            return try drop.view.make("master")
        }
    }
}
