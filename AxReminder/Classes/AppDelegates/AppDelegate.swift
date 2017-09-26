//
//  AppDelegate.swift
//  AxReminder
//
//  Created by devedbox on 2017/6/26.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        loadViewControllers()
        setupUIAppearance()
        
        // let date = Date()
        // let gif = UIImage.gif(named: "Gif")!
        // let image = #imageLiteral(resourceName: "image_sample")
        // let bordered = image.bordered(24.0)
        // let rounded = image.round(40.0, border: 30.0)
        // let cornered = image.cornered
        // let cropped = image.crop(to: CGRect(origin: .zero, size: image.size).insetBy(dx: 0.0, dy: fabs(image.size.height - image.size.width) * 0.5))
        // let cropped = gif.crop(fits: gif.size.scale(by: 0.5), using: .center, rendering: .auto)
        // let resized = image.resize(fits: CGSize(width: image.size.height, height: image.size.height), quality: .high)
        // let croppingSize = CGSize(width: image.size.width * 0.5, height: image.size.width * 0.5)
        // let cropped = image.crop(fits: croppingSize, using: .bottomRight)
        // let thumbnail = image.thumbnail(squares: 20, borderWidth: 10, cornerRadius: 10, quality: .high)
        // let thumbnail = image.thumbnail(scalesToFit: 100)
        // let imagefromstring = UIImage.image(from: "imagefromstring", using: UIFont.boldSystemFont(ofSize: 36))
        // let pdf = UIImage.image(fromPDFNamed: "Swift", scalesToFit: UIScreen.main.bounds.size, pageCountLimits: 3)
        // let resizing = UIImage.ResizingMode.center
        // let merged1 = #imageLiteral(resourceName: "image_to_merge").merge(with: [image,#imageLiteral(resourceName: "location_center")], using: .vertically(.topToBottom, resizing))
        // let merged2 = #imageLiteral(resourceName: "image_to_merge").merge(with: [image,#imageLiteral(resourceName: "location_center")], using: .vertically(.bottomToTop, resizing))
        // let color = image.color(at: CGPoint(x: image.size.width-1, y: image.size.height-1), scale: 2.0)
        // let colors = image.majorColors()
        // let fixedImage = #imageLiteral(resourceName: "image_to_merge").grayed?.rotate(by: CGFloat.pi / 6.0)
        // let image1 = UIImage.gif(named: "Gif")!
        // let handled1 = image1.resize(fits: CGSize(width: 120, height: 120), using: .center)
        // let image2 = #imageLiteral(resourceName: "image_to_merge")
        // let handled2 = image2.resize(fits: CGSize(width: 120, height: 80), using: .center)
        // print("Cost timing: \(Date().timeIntervalSince(date))")
        // let imageView1 = UIImageView(image: cropped)
        // imageView1.contentMode = .center
        // imageView1.frame = CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/* * 0.5 - 0.0*/))
        // imageView1.backgroundColor = .white
        // let imageView2 = UIImageView(image: merged2)
        // imageView2.contentMode = .scaleAspectFit
        // imageView2.frame = CGRect(origin: CGPoint(x: 0, y: UIScreen.main.bounds.height * 0.5), size: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.5))
        // imageView2.backgroundColor = .white
        // window = UIWindow(frame: UIScreen.main.bounds)
        // window?.backgroundColor = UIColor(hex: "f5f5f5")
        // window?.rootViewController = UIViewController()
        // window?.addSubview(imageView1)
        // window?.addSubview(imageView2)
        // window?.makeKeyAndVisible()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
    }
}

