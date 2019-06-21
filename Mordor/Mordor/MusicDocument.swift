//
//  MusicDocument.swift
//  Mordor
//
//  Created by Huang Bohan on 22/6/19.
//  Copyright © 2019 Huang Bohan. All rights reserved.
//

import UIKit

class MusicDocument: UIDocument {
    init() {
        let tempDir = FileManager.default.temporaryDirectory
        let url = tempDir.appendingPathComponent("xwlb.pdf")
        
        super.init(fileURL: url)
    }
}
