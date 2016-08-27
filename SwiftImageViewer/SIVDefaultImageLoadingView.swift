//
//  SIVDefaultImageLoadingView.swift
//  SwiftImageViewer
//
//  Created by Alex on 25/8/2016.

import UIKit

public class SIVDefaultImageLoadingView:UIView, SIVImageLoadingIndicatorViewType {
    // Properties set from out side of this view
    public var progress: Double = 0.0 {
        didSet {
            progressView?.setProgress(Float(progress), animated: true)
        }
    }
    
    public var reloadHandler:SIVClosure?
    public var singleTapHandler:SIVClosure?
    
    public static var layoutSize: SIVImageLoadingIndicatorViewSize {
        return .centered(CGSize(width: 80, height: 80))
    }
    
    public func update(withResult result:SIVImageLoadResult, completion:SIVClosure?){
        progressView?.removeFromSuperview()
        switch result {
        case .success(_):
            _ = createSucceedView()
            DispatchQueue.main.after(when: .now() + .milliseconds(800)){
                UIView.animate(withDuration: 0.5, animations:{
                    self.alpha = 0.0
                }){_ in
                    // Should call completion so containing view controller can remove in case of success.
                    completion?()
                }
            }
            break
        case .failed(_):
            // Add failed view
            let failedView = createFailedView()
            let button = createReloadButton()
            button.alpha = 0.0
            DispatchQueue.main.after(when: .now() + .milliseconds(800)){
                UIView.animate(withDuration: 0.5, animations: {
                    failedView.alpha = 0.0
                    button.alpha = 1.0
                }){_ in
                    completion?()
                }
            }
            break
        }
    }
    
    // MARK: - Initializers
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit(){
        backgroundColor = .clear()
        
        // Add Gesture recognizer to this view.
        addGestureRecognizer(singleTapGestureRecognizer)
        
        // Create blur view first
        _ = crateBluredBackView()
        
        // Add progress view
        progressView = createProgressView()
        
        // Update progress
        progress = 0
    }
    
    private lazy var singleTapGestureRecognizer:UITapGestureRecognizer = {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(singleTapped(_:)))
        tapGestureRecognizer.numberOfTapsRequired = 1
        return tapGestureRecognizer
    }()
    
    @IBAction func singleTapped(_ sender: AnyObject){
        // Call single tap handler
        singleTapHandler?()
    }
    
    // MARK: - ProgressView part
    private let viewsInset = CGSize(width: 8, height: 8)
    private var progressView:MRProgressView?
    
    private func createProgressView() -> MRProgressView {
        let progressView = MRCircularProgressView(frame: bounds.insetBy(dx: viewsInset.width, dy: viewsInset.height))
        progressView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleBottomMargin, .flexibleTopMargin]
        progressView.tintColor = .white()
        progressView.lineWidth = 3.0
        addSubview(progressView)
        return progressView
    }
    
    private func createFailedView() -> MRCrossIconView {
        let failedView = MRCrossIconView(frame: bounds.insetBy(dx: viewsInset.width, dy: viewsInset.height))
        failedView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleBottomMargin, .flexibleTopMargin]
        failedView.tintColor = .white()
        failedView.lineWidth = 2.0
        addSubview(failedView)
        return failedView
    }
    
    private func createSucceedView() -> MRCheckmarkIconView {
        let succeedView = MRCheckmarkIconView(frame: bounds.insetBy(dx: viewsInset.width, dy: viewsInset.height))
        succeedView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleBottomMargin, .flexibleTopMargin]
        succeedView.tintColor = .white()
        succeedView.lineWidth = 2.0
        addSubview(succeedView)
        return succeedView
    }
    
    private func crateBluredBackView() -> UIView {
        // Add Blured view
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blurView.frame = bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.layer.borderColor = UIColor.clear().cgColor
        blurView.layer.masksToBounds = true
        blurView.layer.cornerRadius = 6.0
        
        addSubview(blurView)    // At bottom
        return blurView
    }
    
    private func createReloadButton() -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle("RELOAD", for: [.normal])
        button.tintColor = .white()
        button.sizeToFit()
        addSubview(button)
        button.center = bounds.center
        button.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin, .flexibleRightMargin, .flexibleBottomMargin]
        
        button.addTarget(self, action: #selector(reloadButtonTapped(_:)), for: [.touchUpInside])
        return button
    }
    
    @IBAction func reloadButtonTapped(_ sender:AnyObject) {
        reloadHandler?()
        // Remove all superviews
        subviews.forEach{$0.removeFromSuperview()}
        progressView = createProgressView()
        progress = 0
    }
}
