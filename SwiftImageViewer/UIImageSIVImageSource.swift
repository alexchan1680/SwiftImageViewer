//
//  UIImageSIVImageSource.swift
//  SwiftImageViewer
//
//  Created by Alex on 27/8/2016.
//
//

import UIKit

public struct UIImageSIVImageSource {
    public let image:UIImage
    public init(image:UIImage){
        self.image = image
    }
}

extension UIImageSIVImageSource: SIVImageSourceType {
    public var loadedImage:SIVImage?{
        return .image(image)
    }
    public var previewImage:SIVImage?{
        return nil
    }
    
    public func load(progress: (Double) -> (), completion: (SIVImageLoadResult) -> ()) {
        progress(1.0)
        completion(.success(.image(image)))
    }
    
    public func cancel(){}
}
