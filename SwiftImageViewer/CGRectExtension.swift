//
//  CGRectExtension.swift
//  SwiftImageViewer
//
//  Created by Alex on 25/8/2016.

import Foundation

// MARK: - Handful extensions
extension CGRect {
    /// Center point of the CGRect
    var center:CGPoint {
        return CGPoint(x: midX, y: midY)
    }
    
    /// Centered Rect
    func centeredRect(size:CGSize) -> CGRect{
        return CGRect(center: center, size: size)
    }
    
    /// Get Origin of centered rect.
    func originFor(centered size:CGSize) -> CGPoint{
        return centeredRect(size: size).origin
    }
    
    init (center:CGPoint, size:CGSize){
        self.init(origin:CGPoint(x:center.x - size.width / 2, y:center.y - size.height / 2),
                  size:size
        )
    }
}
