//
//  GraphCalcSplitViewController.swift
//  GraphCalc
//
//  Created by Todd Laney on 6/5/15.
//  Copyright (c) 2015 Todd Laney. All rights reserved.
//

import UIKit

class WrapViewController : UIViewController
{
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return childViewControllers[0].preferredStatusBarStyle()
    }
    
    override func overrideTraitCollectionForChildViewController(childViewController: UIViewController) -> UITraitCollection!
    {
        var tc = self.traitCollection
        if tc.userInterfaceIdiom == .Phone {
            
        }
        return tc
    }
}

extension UISplitViewController
{
    func makeLandscapeRegularWidth()
    {
        if let window = UIApplication.sharedApplication().windows.first as? UIWindow {
            if (window.rootViewController == self) {
                let wrap = WrapViewController()
                wrap.addChildViewController(self)
                wrap.view.addSubview(self.view)
                window.rootViewController = wrap
            }
        }
    }
}

class GraphCalcSplitViewController: UISplitViewController, UISplitViewControllerDelegate
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        delegate = self
        
        setupDetail(viewControllers[1] as? UIViewController)
        
        let barc = (viewControllers[0] as? UINavigationController)?.topViewController.view.backgroundColor
        let tint = UIColor.yellowColor()
        
        let appearance = UINavigationBar.appearance()
        appearance.barTintColor = barc
        appearance.tintColor = tint
        appearance.titleTextAttributes = [NSForegroundColorAttributeName: tint]
        
        //self.makeLandscapeRegularWidth()
    }
    
     override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    func setupDetail(vc : UIViewController?)
    {
        // enable "back" button on default empty detail view controller and turn off swipe
        if let nav = vc as? UINavigationController {
            
            nav.topViewController.navigationItem.leftBarButtonItem = displayModeButtonItem()
            nav.topViewController.navigationItem.leftItemsSupplementBackButton = true
            
            presentsWithGesture = false
            preferredDisplayMode = .AllVisible // .PrimaryOverlay
        }
    }
    
    // MARK: UISplitViewControllerDelegate

    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController:UIViewController!, ontoPrimaryViewController primaryViewController:UIViewController!) -> Bool
    {
        NSLog("collapseSecondaryViewController")
        return true // I handled collapse, ie always collapse to master
    }
    
    func splitViewController(splitViewController: UISplitViewController, showDetailViewController vc: UIViewController, sender: AnyObject?) -> Bool
    {
        setupDetail(vc)
        return false // let system do default, ie show it!
    }
}
