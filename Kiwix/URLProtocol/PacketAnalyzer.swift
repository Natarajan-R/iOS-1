//
//  PacketAnalyzer.swift
//  Kiwix
//
//  Created by Chris Li on 7/18/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

class PacketAnalyzer {
    static let sharedInstance = PacketAnalyzer()
    private var listening = false
    private var images = [(data: Data, url: URL)]()
    
    func startListening() {
        listening = true
    }
    
    func stopListening() {
        listening = false
        images.removeAll()
    }
    
    func addImage(_ data: Data, url: URL) {
        guard listening else {return}
        images.append((data, url))
    }
    
    func chooseImage() -> (data: Data, url: URL)? {
        return images.first
    }
}
