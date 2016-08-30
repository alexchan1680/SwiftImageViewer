//
//  ImagesViewController.swift
//  SwiftImageViewer
//
//  Created by Alex on 25/8/2016.
//
//

import UIKit
import SwiftImageViewer

class ImagesViewController: UIViewController {
    var images = [SIVImageSourceType](){
        didSet {
            pageNumber = 0
        }
    }
    private var currentImageVC:SIVDefaultImageViewController?
    
    private lazy var prevBarButtonItem:UIBarButtonItem = {
        return UIBarButtonItem(title: "PREV", style: .plain, target: self, action: #selector(prevButtonTapped(_:)))
    }()
    
    private lazy var nextBarButtonItem:UIBarButtonItem = {
        return UIBarButtonItem(title: "NEXT", style: .plain, target: self, action: #selector(nextButtonTapped(_:)))
    }()
    
    private var isBarHidden = false {
        didSet {
            guard isBarHidden != oldValue else { return }
            navigationController?.setToolbarHidden(isBarHidden, animated: true)
            navigationController?.setNavigationBarHidden(isBarHidden, animated: true)
        }
    }
    
    private var pageNumber = 0{
        didSet {
            
            // Update prev bar button item and next bar button item
            prevBarButtonItem.isEnabled = (pageNumber > 0)
            nextBarButtonItem.isEnabled = (pageNumber < images.count - 1)
            
            guard pageNumber >= 0 && pageNumber < images.count else { return }
            
            // Remove any previous viewcontroller if any
            if let currentImageVC = currentImageVC {
                currentImageVC.willMove(toParentViewController: nil)
                currentImageVC.view.removeFromSuperview()
                currentImageVC.removeFromParentViewController()
            }
            
            let imageVC = SIVDefaultImageViewController(nibName: nil, bundle: nil)
            imageVC.source = images[pageNumber]
            
            // Assign bar visibilty handler.
            imageVC.barVisibilityHandler = {[weak self] signal in
                guard let _self = self else { return }
                switch signal {
                case .hide:
                    _self.isBarHidden = true
                case .toggle:
                    _self.isBarHidden = !_self.isBarHidden
                }
            }
            addChildViewController(imageVC)
            
            view.addSubview(imageVC.view)
            imageVC.view.translatesAutoresizingMaskIntoConstraints = false
            imageVC.view.alignEdges(to: view)
            
            imageVC.didMove(toParentViewController: self)
            currentImageVC = imageVC
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupToolBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(false, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setToolbarHidden(true, animated: true)
    }
    
    private func setupToolBar(){
        toolbarItems = [prevBarButtonItem,
                        UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                        nextBarButtonItem]
    }
    
    @IBAction func prevButtonTapped(_ sender:AnyObject) {
        guard pageNumber > 0 else { return }
        pageNumber -= 1
    }
    
    @IBAction func nextButtonTapped(_ sender:AnyObject) {
        guard pageNumber < images.count - 1 else { return }
        pageNumber += 1
    }
}

extension UIView {
    func alignEdges(to view:UIView){
        translatesAutoresizingMaskIntoConstraints = false
        let edgeAttributes:[NSLayoutAttribute] = [.top, .bottom, .left, .right]
        let constraints = edgeAttributes.map{
            NSLayoutConstraint(item: self, attribute: $0, relatedBy: .equal, toItem: view, attribute: $0, multiplier: 1.0, constant: 0.0)
        }
        view.addConstraints(constraints)
    }
}
