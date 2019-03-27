//
//  UIWindow+VisibleViewController.swift
//  Alarm-ios-swift
//
//  Created by natsu1211 on 2017/04/09.
//  Copyright © 2017年 LongGames. All rights reserved.
//

import Foundation
import UIKit
public extension UIWindow {
    var visibleViewController: UIViewController? {
        return UIWindow.getVisibleViewControllerFrom(sourceViewController: self.rootViewController)
    }

    static func getVisibleViewControllerFrom(sourceViewController: UIViewController?) -> UIViewController? {
        if let navigationController = sourceViewController as? UINavigationController {

            return UIWindow.getVisibleViewControllerFrom(
                    sourceViewController: navigationController.visibleViewController)

        } else if let tabBarController = sourceViewController as? UITabBarController {
            return UIWindow.getVisibleViewControllerFrom(sourceViewController: tabBarController.selectedViewController)
        } else {
            if let presentedViewController = sourceViewController?.presentedViewController {
                return UIWindow.getVisibleViewControllerFrom(sourceViewController: presentedViewController)
            } else {
                return sourceViewController
            }
        }
    }
}
