//
//  Creation.swift
//  FrameIT
//
//  Created by Arthur Duver on 14/10/2018.
//  Copyright © 2018 Arthur Duver. All rights reserved.
//

import Foundation
import UIKit

class Creation {
    var image: UIImage
    var colorSwatch: ColorSwatch
    
    static var defaultImage:UIImage {
        return UIImage.init(named: "FrameIT-placeholder")!
    }
    
    static var defaultColorSwatch: ColorSwatch {
        return ColorSwatch.init(caption: "Simply yellow", color: .yellow)
    }
    
    init() {
        self.image = Creation.defaultImage
        self.colorSwatch = Creation.defaultColorSwatch
    }
    
    convenience init(colorSwatch:ColorSwatch?) {
        self.init()
        if let userColorSwatch = colorSwatch {
            self.colorSwatch = userColorSwatch
        }
    }
    
    func reset(colorSwatch:ColorSwatch?) {
        self.image = Creation.defaultImage
        if let userColorSwatch = colorSwatch {
            self.colorSwatch = userColorSwatch
        }
        else {
            self.colorSwatch = Creation.defaultColorSwatch
        }
    }
}
