//
//  UIImage+Utility.swift
//  SwiftImageViewer
//
//  Created by Alex on 26/8/2016.
//
//

import UIKit
import CoreImage
import CoreGraphics

// MARK: - Utility functions to easily get ciImage, cgImage
extension UIImage {
    /**
     This function trys to return CIImage even the image is CGImageRef based.
     - Returns: CIImage equal to current image
     */
    var ciImage_:CoreImage.CIImage?{
        // if CIImage is not nil then return it
        if ciImage != nil {
            return ciImage
        }
        
        guard let cgImage = cgImage else {
            return nil
        }
        return CoreImage.CIImage(cgImage: cgImage)
    }
    
    /**
     This function trys to return CGImage even the image is CIImage based.
     - Returns: CGImage equal to current image
     */
    var cgImage_:CoreGraphics.CGImage?{
        if cgImage != nil {
            return cgImage
        }
        
        guard let ciImage = ciImage else {
            return nil
        }
        
        let ctx = CIContext(options: nil)
        return ctx.createCGImage(ciImage, from: ciImage.extent)
    }
}

// MARK: - Wrappers for UIImageJPEGRepresentation & UIImagePNGRepresentation functions
extension UIImage {
    /**
     Wrapper for UIImageJPEGRepresentation
     UIImageJPEGRepresentation crashes when it is CIImage based, so did some wrapping here.
     It also does orientation fix.
     */
    func jpegRepresentation(compressionQuality q:CGFloat) -> Data?{
        guard let fixedImage = orientationFixed(),
            let cgImage = fixedImage.cgImage_ else {
                return nil
        }
        return UIImageJPEGRepresentation(UIImage(cgImage: cgImage), q)
    }
    
    /**
     Wrapper for UIImagePNGRepresentation
     UIImageJPEGRepresentation crashes when it is CIImage based, so did some wrapping here.
     It also does orientation fix.
     */
    func pngRepresentation() -> Data?{
        guard let fixedImage = orientationFixed(),
            let cgImage = fixedImage.cgImage_ else {
                return nil
        }
        return UIImagePNGRepresentation(UIImage(cgImage: cgImage))
    }
}


// MARK: - Alpha
extension UIImage{
    /**
     Check if current image has alpha
     - Returns: true if the image has an alpha layer
     */
    func hasAlpha() -> Bool{
        guard let alpha = cgImage_?.alphaInfo else { return false }
        switch alpha{
        case .first, .last, .premultipliedFirst, .premultipliedLast:
            return true
        default:
            return false
        }
    }
    
    /**
     Converts image to alpha mode image
     - Returns: a copy of the given image, adding an alpha channel if it doesn't already have one
     */
    func imageWithAlpha() -> UIImage?{
        if hasAlpha(){
            return self
        }
        
        guard let imageRef = cgImage_ else {
            return nil
        }
        
        let width = imageRef.width
        let height = imageRef.height
        let bitmapInfo:CGBitmapInfo = .alphaInfoMask
        // The bitsPerComponent and bitmapInfo values are hard-coded to prevent an "unsupported parameter combination" error
        let offscreenContext = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: imageRef.colorSpace!, bitmapInfo: bitmapInfo.rawValue)
        
        // Draw the image into the context and retrieve the new image, which will now have an alpha layer
        offscreenContext?.draw(imageRef, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let imageRefWithAlpha = offscreenContext?.makeImage() else {
            return nil
        }
        return UIImage(cgImage: imageRefWithAlpha)
    }
    
    /// Returns a copy of the image with a transparent border of the given size added around its edges.
    /// If the image has no alpha layer, one will be added to it.
    func transparentBorderImage(borderSize : CGFloat) -> UIImage?{
        // If the image does not have an alpha layer, add one
        guard let image = imageWithAlpha() else {
            return nil
        }
        
        guard let cgImage = image.cgImage_ else{
            return nil
        }
        
        let newRect = CGRect(x: 0, y: 0, width: image.size.width + borderSize * 2 , height: image.size.height + borderSize * 2)
        
        let bitmap = CGContext(data: nil,
                               width: Int(newRect.size.width),
                               height: Int(newRect.size.height),
                               bitsPerComponent: cgImage.bitsPerComponent,
                               bytesPerRow: 0,
                               space: cgImage.colorSpace!,
                               bitmapInfo: cgImage.bitmapInfo.rawValue)
        
        let imageLocation = CGRect(x: borderSize, y: borderSize, width: image.size.width, height: image.size.height)
        bitmap?.draw(cgImage, in: imageLocation)
        
        let borderImageRef = bitmap?.makeImage()
        
        // Create a mask to make the border transparent, and combine it with the image
        let maskImageRef = newBorderMask(borderSize: borderSize, size: newRect.size)
        guard let transparentBorderImageRef = borderImageRef?.masking(maskImageRef!) else {
            return nil
        }
        return UIImage(cgImage: transparentBorderImageRef)
    }
    
    /// Creates a mask that makes the outer edges transparent and everything else opaque
    /// The size must include the entire mask (opaque part + transparent border)
    /// The caller is responsible for releasing the returned reference by calling CGImageRelease
    fileprivate func newBorderMask(borderSize:CGFloat, size:CGSize) -> CGImage?{
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let maskContext = CGContext(data: nil,
                                    width: Int(size.width),
                                    height: Int(size.height),
                                    bitsPerComponent: 8,
                                    bytesPerRow: 0,
                                    space: colorSpace,
                                    bitmapInfo: CGBitmapInfo().rawValue | CGImageAlphaInfo.none.rawValue
        )
        
        // Start with a mask that's entirely transparent
        maskContext?.setFillColor(UIColor.black.cgColor)
        maskContext?.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        // Make the inner part (within the border) opaque
        maskContext?.setFillColor(UIColor.white.cgColor)
        maskContext?.fill(CGRect(x: borderSize, y: borderSize, width: size.width - borderSize * 2, height: size.height - borderSize * 2))
        
        return maskContext?.makeImage()
    }
}

// MARK: - Resize
extension UIImage{
    /// Returns a copy of this image that is cropped to the given bounds.
    /// The bounds will be adjusted using CGRectIntegral.
    /// This method ignores the image's imageOrientation setting.
    func cropped(to bounds:CGRect) -> UIImage?{
        guard let imageRef = cgImage_?.cropping(to: bounds) else{
            return nil
        }
        return UIImage(cgImage: imageRef)
    }
    
    /// Returns a copy of this image that is squared to the thumbnail size.
    /// If transparentBorder is non-zero, a transparent border of the given size will be added around the edges of the thumbnail. (Adding a transparent border of at least one pixel in size has the side-effect of antialiasing the edges of the image when rotating it using Core Animation.)
    func thumbnail(size thumbnailSize:CGFloat, transparentBorder borderSize:CGFloat = 0, cornerRadius:CGFloat = 0, interpolationQuality quality:CGInterpolationQuality = .default) -> UIImage?{
        // Crop out any part of the image that's larger than the thumbnail size
        // The cropped rect must be centered on the resized image
        // Round the origin points so that the size isn't altered when CGRectIntegral is later invoked
        
        guard let resizedImage = resized(withContentMode:.scaleAspectFill, bounds: CGSize(width: thumbnailSize, height: thumbnailSize), interpolationQuality: quality) else{
            return nil
        }
        
        let cropRect = CGRect(
            x: (resizedImage.size.width - thumbnailSize) / 2,
            y: (resizedImage.size.height - thumbnailSize) / 2,
            width: thumbnailSize,
            height: thumbnailSize)
        
        let croppedImage = resizedImage.cropped(to:cropRect)
        let transparentBorderImage =  (borderSize > 0.0 ? croppedImage?.transparentBorderImage(borderSize: borderSize) : croppedImage)
        return cornerRadius == 0.0 ? transparentBorderImage : transparentBorderImage?.roundCornered(withRadius: cornerRadius, borderSize: borderSize)
    }
    
    /// Returns a rescaled copy of the image, taking into account its orientation
    /// The image will be scaled disproportionately if necessary to fit the bounds specified by the parameter
    func resized(to newSize:CGSize, interpolationQuality quality:CGInterpolationQuality) -> UIImage?{
        var drawTransposed = false
        
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            drawTransposed = true
        default:
            break
        }
        return resized(to: newSize, transform: transformConsideringOrientation(to: newSize), drawTransposed: drawTransposed, interpolationQuality: quality)
    }
    
    /// Resizes the image according to the given content mode, taking into account the image's orientation
    func resized(withContentMode contentMode:UIViewContentMode, bounds:CGSize, interpolationQuality quality:CGInterpolationQuality) -> UIImage?{
        let horizontalRatio = bounds.width / size.width
        let verticalRatio = bounds.height / size.height
        var ratio:CGFloat = 0.0
        
        switch contentMode {
        case .scaleAspectFill:
            ratio = max(horizontalRatio, verticalRatio)
        case .scaleAspectFit:
            ratio = min(horizontalRatio, verticalRatio)
        default:
            fatalError("Unsupported content mode:\(contentMode)")
        }
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        return resized(to: newSize, interpolationQuality: quality)
    }
    
    /// Returns a copy of the image that has been transformed using the given affine transform and scaled to the new size
    /// The new image's orientation will be UIImageOrientationUp, regardless of the current image's orientation
    /// If the new size is not integral, it will be rounded up
    fileprivate func resized(to newSize:CGSize, transform:CGAffineTransform, drawTransposed transpose:Bool, interpolationQuality quality:CGInterpolationQuality) -> UIImage?{
        guard let cgImage = cgImage_ else{
            return nil
        }
        
        let newRect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height).integral;
        let transposedRect = CGRect(x: 0, y: 0, width: newRect.size.height, height: newRect.size.width);
        
        // Build a context that's the same dimensions as the new size
        let bitmap = CGContext(data: nil,
                               width: Int(newRect.size.width),
                               height: Int(newRect.size.height),
                               bitsPerComponent: cgImage.bitsPerComponent,
                               bytesPerRow: 0,
                               space: cgImage.colorSpace!,
                               bitmapInfo: cgImage.bitmapInfo.rawValue);
        
        // Rotate and/or flip the image if required by its orientation
        bitmap?.concatenate(transform)
        
        // Set the quality level to use when rescaling
        bitmap!.interpolationQuality = quality;
        
        // Draw into the context; this scales the image
        bitmap?.draw(cgImage, in: transpose ? transposedRect : newRect)
        
        // Get the resized image from the context and a UIImage
        guard let newImageRef = bitmap?.makeImage() else{
            return nil
        }
        return UIImage(cgImage: newImageRef)
    }
    
    fileprivate func transformConsideringOrientation(to newSize:CGSize) -> CGAffineTransform{
        var transform = CGAffineTransform.identity
        switch imageOrientation {
        case .down, .downMirrored: // EXIF = 3, EXIF = 4
            transform = transform.translatedBy(x: newSize.width, y: newSize.height)
            transform = transform.rotated(by: CGFloat(M_PI))
            
        case .left, .leftMirrored:  // EXIF = 6, EXIF = 5
            transform = transform.translatedBy(x: newSize.width, y: 0)
            transform = transform.rotated(by: CGFloat(M_PI_2))
            
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: newSize.height)
            transform = transform.rotated(by: CGFloat(-M_PI_2))
        default:
            break
        }
        
        switch imageOrientation{
        case .upMirrored, .downMirrored: // EXIF = 2, EXIF = 4
            transform = transform.translatedBy(x: newSize.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: newSize.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        default:
            break
        }
        return transform
    }
}

// Rounded Corner
extension UIImage {
    // Creates a copy of this image with rounded corners
    // If borderSize is non-zero, a transparent border of the given size will also be added
    // Original author: Björn Sållarp. Used with permission. See: http://blog.sallarp.com/iphone-uiimage-round-corners/
    func roundCornered(withRadius cornerSize:CGFloat, borderSize:CGFloat) -> UIImage?{
        guard let image = imageWithAlpha() else {
            return nil
        }
        
        guard let cgImage = image.cgImage_ else {
            return nil
        }
        
        // Build a context that's the same dimensions as the new size
        let context = CGContext(data: nil,
                                width: Int(image.size.width),
                                height: Int(image.size.height),
                                bitsPerComponent: cgImage.bitsPerComponent,
                                bytesPerRow: 0,
                                space: cgImage.colorSpace!,
                                bitmapInfo: cgImage.bitmapInfo.rawValue)
        
        // Create a clipping path with rounded corners
        context?.beginPath()
        let r = CGRect(x: borderSize, y: borderSize, width: image.size.width - borderSize * 2, height: image.size.height - borderSize * 2)
        addRoundedRectToPath(r, context: context, ovalWidth: cornerSize, ovalHeight: cornerSize)
        
        context?.closePath()
        context?.clip()
        
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        
        guard let clippedImage = context?.makeImage() else {
            return nil
        }
        
        return UIImage(cgImage: clippedImage)
    }
    
    
    /// Adds a rectangular path to the given context and rounds its corners by the given extents
    /// Original author: Björn Sållarp. Used with permission. See: http://blog.sallarp.com/iphone-uiimage-round-corners/
    func addRoundedRectToPath(_ rect:CGRect, context:CGContext?, ovalWidth:CGFloat, ovalHeight:CGFloat){
        guard ovalWidth > 0 && ovalHeight > 0 else{
            context?.addRect(rect)
            return
        }
        context?.saveGState()
        context?.translateBy(x: rect.minX, y: rect.minY)
        context?.scaleBy(x: ovalWidth, y: ovalHeight)
        let fw = rect.width / ovalWidth
        let fh = rect.height / ovalHeight
        
        context?.move(to: CGPoint(x: fw, y: fh/2))
        context?.addArc(tangent1End: CGPoint(x:fw, y:fh), tangent2End: CGPoint(x:fw/2, y:fh), radius: 1)
        context?.addArc(tangent1End: CGPoint(x:0, y:fh), tangent2End: CGPoint(x:0, y:fh/2), radius: 1)
        context?.addArc(tangent1End: CGPoint(x:0, y:0), tangent2End: CGPoint(x:fw/2, y:0), radius: 1)
        context?.addArc(tangent1End: CGPoint(x:fw, y:0), tangent2End: CGPoint(x:fw, y:fh/2), radius: 1)
        
        context?.closePath()
        context?.restoreGState()
    }
}

// MARK: - Fix Orientation
extension UIImage {
    /**
     Return fixed orientation image
     */
    func orientationFixed() -> UIImage?{
        if imageOrientation == .up {
            return self
        }
        
        // Get transform
        let transform = transformConsideringOrientation(to: size)
        guard let cgImage = cgImage_ else {
            return nil
        }
        
        let ctx = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: 0,
            space: cgImage.colorSpace!,
            bitmapInfo: cgImage.bitmapInfo.rawValue
        )
        
        ctx?.concatenate(transform)
        
        switch imageOrientation{
        case .left, .leftMirrored, .right, .rightMirrored:
            ctx?.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        default:
            ctx?.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }
        
        guard let rotatedCGImage = ctx?.makeImage() else{
            return nil
        }
        return UIImage(cgImage: rotatedCGImage)
    }
}

// MARK: - Scaled Image if resolution exceeds maximum bounds
extension UIImage {
    /**
     Returns scaled image if current image exceeds resolution
     If smaller than resolution, return self
     - Parameter resolution: Max resolution value (e.g. 1024, 2560 ...)
     */
    func scaled(toMaxDimension resolution:CGFloat) -> UIImage?{
        let maxSize = max(size.height, size.width)
        guard maxSize > resolution else {
            return self
        }
        return resized(withContentMode: .scaleAspectFit, bounds: CGSize(width: resolution, height:resolution), interpolationQuality: .high)
    }
}





