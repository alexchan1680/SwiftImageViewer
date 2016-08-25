//
//  UIImageViewExtension.swift
//  PhotoViewer
//
//  Created by Alex on 24/8/2016.

import UIKit

// MARK: - Conform to SIVImageViewType
extension UIImageView:SIVImageViewType {
    public var sivImage:SIVImage? {
        get {
            return image.flatMap{.image($0)}
        }
        set {
            image = newValue?.toUIImage()
        }
    }
}
