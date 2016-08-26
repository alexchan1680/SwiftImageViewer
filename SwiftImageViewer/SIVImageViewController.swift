//
//  SIVImageViewController.swift
//  SwiftImageViewer
//
//  Created by Alex on 24/8/2016.

import UIKit

public typealias SIVDefaultImageViewController = SIVImageViewController<UIImageView, SIVDefaultImageLoadingView>

public class SIVImageViewController<ImageView:SIVImageViewType, LoadingView:SIVImageLoadingIndicatorViewType where ImageView:UIView, LoadingView:UIView>: UIViewController {
    /// Control bars visibility handler (e.g. navigation bar or tool bar for image view controller or page view controller)
    public var barVisibilityHandler:((SIVBarVisibilitySignal) -> ())?
    
    /// Recommend only set one time
    public var source:SIVImageSourceType? {
        didSet {
            loadToken += 1
            update(withSource: source)
        }
    }
    
    /// Set this property if you want custom behaviour on single tap of loading view and image view.
    public var singleTapHandler:SIVClosure?
    
    private var loadToken = 0   // Source load token
    private func update(withSource source:SIVImageSourceType?){
        loadingView?.removeFromSuperview()  // Remove Loading view from superview.
        scrollView.image = nil              // Set scroll view to nil
        
        guard let source = source else { return }
        
        // if image has been cached, then simply load the image.
        if let image = source.loadedImage {
            scrollView.image = image
            return
        }
        
        // Update scroll view with preview image if possible.
        if let previewImage = source.previewImage {
            scrollView.image = previewImage
        }
        
        // Create Loading View
        var _loadingView:LoadingView!
        // Update auto resizing mask and layout loading view with layout size again.
        if case let .centered(size) = LoadingView.layoutSize {
            // put loading view center
            _loadingView = LoadingView(frame: view.bounds.centeredRect(size: size))
        } else {
            // put loading view center
            _loadingView = LoadingView(frame: view.bounds)
        }
        _loadingView.autoresizingMask = LoadingView.layoutSize.autoresizingMask
        
        // Configure loading view
        _loadingView.reloadHandler = {[weak self] in
            //unwrap source
            let source = self?.source
            self?.source = source
        }
        
        _loadingView.singleTapHandler = {[weak self] in
            guard let singleTapHandler = self?.singleTapHandler else {
                self?.barSignal = .toggle
                return
            }
            singleTapHandler()
        }
        
        // Inser subview above the scroll view (Mask scroll view)
        view.insertSubview(_loadingView, aboveSubview: scrollView)
        self.loadingView = _loadingView
        
        // Start loading the image.
        let loadToken = self.loadToken
        source.load(
            progress: {[weak _loadingView] progress in
                _loadingView?.progress = progress
            },
            completion: {[weak _loadingView, weak self] result in
                guard let _self = self, loadToken == _self.loadToken else { return }
                // Let loading view do some animate with result (It might display fail or something).
                if case let .success(image) = result {
                    self?.scrollView.image = image
                }
                
                _loadingView?.update(withResult: result){
                    guard case .success(_) = result else { return }
                    _loadingView?.removeFromSuperview()
                }
        })
    }
    
    // ScrollView for showing scaling image view.
    public lazy var scrollView:SIVScalingImageView<ImageView> = {[unowned self] in
        let scrollView = SIVScalingImageView<ImageView>(frame:CGRect(origin:.zero, size:self.view.frame.size))
        self.view.addSubview(scrollView)
        self.view.sendSubview(toBack: scrollView)
        return scrollView
        }()
    
    private var loadingView:LoadingView?    // Loading Indicator View, should be removed after finished loading.
    
    // BarSignalThrottler with 0.4seconds throttle interval
    private lazy var barSignalThrottler:SIVThrottledClosure = {[weak self] in
        return SIVThrottledClosure(interval: 0.4){[weak self] in
            guard let _self = self, let barSignal = _self.barSignal else { return }
            // Call visibility handler
            _self.barVisibilityHandler?(barSignal)
        }
        }()
    
    // Last set bar signal, this can be called many times, but will be throttled
    private var barSignal:SIVBarVisibilitySignal?{
        didSet {
            // When set, schedule singal throttler
            barSignalThrottler.schedule()
        }
    }
    
    // MARK: - Initialization
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        commonInit()
    }
    
    // Common initialization
    private func commonInit(){
        // When image view zoomed, hide
        scrollView.beginZoomingHandler = {[weak self] in
            // Hide
            self?.barSignal = .hide
        }
        
        // ScrollView Single Tap Handler
        scrollView.singleTapHandler = {[weak self] in
            guard let singleTapHandler = self?.singleTapHandler else {
                self?.barSignal = .toggle
                return
            }
            singleTapHandler()
        }
    }
    
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
