//
//  SIVTypesDefinition.swift
//  SwiftImageViewer
//
//  Created by Alex on 24/8/2016.

import UIKit

// Control bar signal for photo viewer.
public enum SIVBarVisibilitySignal{
    case toggle     // Toggle Visibility
    case hide       // Hide Bar
}


/**
 *Enum* that represents image (Static or Animated GIF)
 
 As it can be animated image, this type is *Enum* and have image or data two cases
*/
public enum SIVImage{
    case image(UIImage)
    case data(Data, CGSize)
    
    // Imag Size
    internal var size:CGSize {
        switch self {
        case let image(img):
            return img.size
        case let data(_, sz):
            return sz
        }
    }
    
    internal func toUIImage() -> UIImage?{
        switch self {
        case let image(img):
            return img
        case let data(dt, _):
            return UIImage(data: dt)
        }
    }
}

/**
 ImageView type that can display image
 
 *UIImageView* or *FLAnimatedImageView* should conform this protocol to use this library.
 */
public protocol SIVImageViewType: class {
    var sivImage:SIVImage? { get set }
}

/// Image Load Result with success & failed
public enum SIVImageLoadResult{
    case success(SIVImage)
    case failed(ErrorProtocol?)
}

/*
 SIVImageSourceType
 Image source which provides the image
*/
public protocol SIVImageSourceType {
    /// Loaded Image, Photo View Controller will check this property first, and if nil,
    var loadedImage:SIVImage? { get }
    
    var previewImage:SIVImage? { get }   // Ability to support preview image
    
    /// Load function with progress and result report.
    func load(progress:((Double) -> ())?, completion:((SIVImageLoadResult) -> ()))
}

public enum SIVImageLoadingIndicatorViewSize{
    case fullScreen         // Full Screen
    case centered(CGSize)   // Cenetered with size
    
    var autoresizingMask:UIViewAutoresizing {
        switch self {
        case .fullScreen:
            return [.flexibleWidth, .flexibleHeight]
        case .centered(_):
            return [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        }
    }
}

/*
 Loading Image Indicator View Type
 */
public protocol SIVImageLoadingIndicatorViewType: class {
    /// Set this property to update loading indicator view's progress.
    var progress:Double { get set }
    
    /// Loading Indicator view might have reload button, handler for it.
    var reloadHandler:SIVClosure? { get set }
    
    /// If Loading Indicator supports single tap for updating visibilty of control bar, implementing class can call this method
    var singleTapHandler:SIVClosure? { get set }
    
    /**
     Update with result, in case of success, this view will be removed from its superview so before doing it, there might be some animation
    */
    func update(withResult result:SIVImageLoadResult, completion:SIVClosure?)
    
    // Layout Size for this indicator view type
    static var layoutSize:SIVImageLoadingIndicatorViewSize { get }
}
