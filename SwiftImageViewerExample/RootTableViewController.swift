//
//  RootTableViewController.swift
//  SwiftImageViewer
//
//  Created by Alex on 25/8/2016.
//
//

import UIKit
import SwiftImageViewer

class RootTableViewController: UITableViewController {
    // Menu
    enum Menu:Int{
        case immediate = 0
        case delayed = 1
    }
    
    // Images
    lazy var images:[UIImage] = {
        return (0..<5).flatMap{UIImage(named:"image\($0).jpg")}
    }()
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = ImagesViewController(nibName: nil, bundle: nil)
        vc.view.frame = UIScreen.main.bounds
        vc.automaticallyAdjustsScrollViewInsets = false
        
        guard let menu = Menu(rawValue: indexPath.row) else { return }
        switch menu {
        case .immediate:
            vc.images = images.map{UIImageSIVImageSource(image: $0)}
        case .delayed:
            vc.images = images.map{DelayedImageSource(image: $0)}
        }
        
        show(vc, sender: nil)
    }
}
