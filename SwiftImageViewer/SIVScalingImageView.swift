//
//  SIVScalingImageView.swift
//  SwiftImageViewer
//
//  Created by Alex on 23/8/2016.

import UIKit

public class SIVScalingImageView<T where T:SIVImageViewType, T:UIView>: UIScrollView, UIScrollViewDelegate{
    public var image:SIVImage?{
        didSet {
            precondition(Thread.isMainThread, "This property should be accessed on main thread.")
            // Update image size first of all.
            imageSize = image?.size
            guard let image = image else {
                // Remove ImageView from super view.
                imageView?.removeFromSuperview()
                return
            }
            show(image:image)
        }
    }
    public var zoomPhotos2Fill:Bool = true
    
    /// Single Tap Handler : Main purpose is to toggle control bar of photo view controller
    public var singleTapHandler:SIVClosure?
    public var beginZoomingHandler:SIVClosure?
    
    public private(set) var imageView:T?
    private var imageSize:CGSize?       // Set when image is set
    
    private lazy var singleTapGestureRecognizer:UITapGestureRecognizer = {
        let recognizer = UITapGestureRecognizer(target:self, action:#selector(scrollViewSingleTapped(_:)))
        recognizer.numberOfTapsRequired = 1
        return recognizer
    }()
    
    private lazy var doubleTapGestureRecognizer:UITapGestureRecognizer = {
        let recognizer = UITapGestureRecognizer(target:self, action:#selector(scrollViewDoubleTapped(_:)))
        recognizer.numberOfTapsRequired = 2
        return recognizer
    }()
    
    private func internalInit(){
        backgroundColor = .clear()
        delegate = self
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        decelerationRate = UIScrollViewDecelerationRateFast
        bounces = false
        // autoresizingMask = [.flexibleWidth, .flexibleHeight]  //This is important
        
        addGestureRecognizer(singleTapGestureRecognizer)
        addGestureRecognizer(doubleTapGestureRecognizer)
    }
    
    /// Override frame
    override public var frame: CGRect {
        get {
            return super.frame
        }
        
        set {
            let shouldChange = (frame != newValue)
            super.frame = newValue
            if shouldChange {
                setMaxMinZoomScale4CurrentBounds()
            }
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        internalInit()
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        internalInit()
    }
    
    // MARK: - Show Image
    private func show(image:SIVImage?){
        self.imageView?.removeFromSuperview()
        guard let image = image, let size = imageSize else {
            self.imageView = nil
            return
        }
        
        maximumZoomScale = 1
        minimumZoomScale = 1
        zoomScale = 1
        
        contentSize = CGSize(width: 0, height: 0)
        // Create image view
        let imageViewFrame = CGRect(origin: .zero, size: size)
        let imageView = T(frame: imageViewFrame)
        imageView.sivImage = image  // Update image
        addSubview(imageView)
        self.imageView = imageView
        contentSize = size
        
        setMaxMinZoomScale4CurrentBounds()
        
        // Force invoke set needs layout
        setNeedsLayout()
    }
    
    // MARK: - Zoom Image Logic
    private func setMaxMinZoomScale4CurrentBounds(){
        guard let imageView = imageView, let imageSize = imageSize else { return }
        
        maximumZoomScale = 1
        minimumZoomScale = 1
        zoomScale = 1
        
        imageView.frame = CGRect(origin: .zero, size: imageView.bounds.size)
        
        let boundSize = frame.size
        
        // Calculate min/max zoom scale
        let xScale = boundSize.width / imageSize.width
        let yScale = boundSize.height / imageSize.height
        
        var minScale = min(xScale, yScale)
        
        isScrollEnabled = false
        var maxScale = CGFloat(3)
        if case .pad = UIDevice.current().userInterfaceIdiom {
            maxScale = 4
        }
        
        // Image is smaller than screen, so no zooming.
        if xScale >= 1 && yScale >= 1 {
            minScale = 1.0  // No zooming
        }
        
        maximumZoomScale = maxScale
        minimumZoomScale = minScale
        
        // Initial Zoom
        zoomScale = initialZoomScaleWithMinScale()
        if zoomScale != minScale {
            contentOffset = CGPoint(x: (imageSize.width * zoomScale - boundSize.width) / 2,
                                    y: (imageSize.height * zoomScale - boundSize.height) / 2)
        }
        
        // Disable scrolling initially  until the first pinch to fix issues with swiping on an initially zoomed in photo
        isScrollEnabled = false
        
        setNeedsLayout()
    }
    
    private func initialZoomScaleWithMinScale() -> CGFloat{
        guard let imageSize = imageSize, zoomPhotos2Fill else { return minimumZoomScale }
        
        let boundsSize = frame.size
        
        let boundsAspectRatio = boundsSize.width / boundsSize.height
        let imageAspectRatio = imageSize.width / imageSize.height
        
        let xScale = boundsSize.width / imageSize.width     // The scale needed to perfectly fit the image-wide
        let yScale = boundsSize.height / imageSize.height   // The scale neeeded to perfectly fit the image height-wise
        
        // Zooms standard portrait images on a 3.5in screen but not on a 4in screen.
        if abs(boundsAspectRatio - imageAspectRatio) < 0.17 {
            let zoomScale = max(xScale, yScale)
            // Ensure we don't zoom in or out too far, just in case
            return min(max(minimumZoomScale, zoomScale), maximumZoomScale)
        }
        return minimumZoomScale
    }
        
    // MARK: - Layout Logic
    override public func layoutSubviews() {
        super.layoutSubviews()
        guard let imageView = imageView else { return }
        
        let boundsSize = frame.size
        var frame2Center = imageView.frame
        
        // Horizontally
        if frame2Center.size.width < boundsSize.width {
            frame2Center.origin.x = (boundsSize.width - frame2Center.width) / 2.0
        } else {
            frame2Center.origin.x = 0
        }
        
        // Vertically
        if frame2Center.size.height < boundsSize.height {
            frame2Center.origin.y = (boundsSize.height - frame2Center.height) / 2.0
        } else {
            frame2Center.origin.y = 0
        }
        
        // Only update frame if not equal
        if imageView.frame != frame2Center {
            imageView.frame = frame2Center
        }
    }
    
    // MARK: - Tap Handler
    @IBAction func scrollViewSingleTapped(_ sender:AnyObject){
        singleTapHandler?()
    }
    
    @IBAction func scrollViewDoubleTapped(_ sender:AnyObject){
        guard let imageView = imageView, imageSize != nil else { return }
        // Scroll View minimize / maximize logic
        if zoomScale > minimumZoomScale + CGFloat(FLT_EPSILON) {
            setZoomScale(minimumZoomScale, animated: true)
        } else {
            let touchPoint = doubleTapGestureRecognizer.location(in: imageView)
            let boundsSize = frame.size
            let newZoomScale = maximumZoomScale
            let xsize = boundsSize.width / newZoomScale
            let ysize = boundsSize.height / newZoomScale
            zoom(to: CGRect(x: touchPoint.x - xsize / 2, y: touchPoint.y - ysize / 2, width: xsize, height: ysize),
                 animated: true)
        }
    }
    
    
    // MARK: - UIScrollViewDelegate
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        isScrollEnabled = true
        
        // When begin zooming,
        beginZoomingHandler?()
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        setNeedsLayout()
        layoutIfNeeded()
    }
}
