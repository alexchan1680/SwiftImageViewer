//
//  ImageSources.swift
//  SwiftImageViewer
//
//  Created by Alex on 26/8/2016.
//
//

import UIKit
import SwiftImageViewer

// MARK: Delayed Image Source
// Randomly fails =)
struct DelayedImageSource{
    var image:UIImage
    var delay:TimeInterval
    
    init(image:UIImage, delay:TimeInterval = 3.0){
        self.image = image
        self.delay = delay
    }
}

extension DelayedImageSource: SIVImageSourceType {
    var loadedImage:SIVImage?{
        return nil
    }
    
    var previewImage:SIVImage?{
        return image.scaled(toMaxDimension: 300).flatMap{.image($0)}
    }
    
    func load(progress: (Double) -> (), completion: (SIVImageLoadResult) -> ()) {
        let source = DispatchSource.timer(queue: .main)
        var pg:Double = 0
        
        // Update every 200 ms
        let increment = 1 / ((delay * 1000) / 200)
        source.scheduleRepeating(deadline: .now() + .milliseconds(200), interval: .milliseconds(200))
        source.setEventHandler{
            pg += increment
            progress(pg)
            if pg >= 1 {
                source.cancel()
                if arc4random() % 2 == 1 {
                    completion(.success(.image(self.image)))
                } else {
                    completion(.failed(nil))
                }
            }
        }
        source.resume()
    }
    
    func cancel(){}
}
