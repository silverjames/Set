//
//  AppDelegate.swift
//  Set
//
//  Created by Bernhard F. Kraft on 08.06.18.
//  Copyright © 2018 Bernhard F. Kraft. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

//    func application(_ application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
//        return true
//    }
//    
//    func application(_ application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
//        return true
//    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        if let mySetViewController = self.window?.rootViewController as! SetViewController? {
            do {
                let url = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                let fileURL = url.appendingPathComponent("setGame")
                let gameData = try Data.init(contentsOf: fileURL)
                //                let jsonString = String(data: gameData, encoding: .utf8)
                //                print ("SET decoded game status from JSON: \(String(describing: jsonString))")
                mySetViewController.game = try JSONDecoder().decode(SetCardGame.self, from: gameData)
                mySetViewController.stateRestorationActive = true
                print ("app delegate:set model data restored")
            } catch CocoaError.fileNoSuchFile {
                print ("app delegate: no previously saved set data found")
                
            } catch {
                print ("app delegate: error occured during reading and decoding state: \(error)")
            }
        }
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        encodeAndWriteState()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.


    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:
        encodeAndWriteState()
    }

    private func encodeAndWriteState() {

        let jsonEncoder = JSONEncoder()
        if let mySetViewController = self.window?.rootViewController as! SetViewController? {
            do {
                let gameData = try jsonEncoder.encode(mySetViewController.game)
                let url = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                let fileURL = url.appendingPathComponent("setGame")
                try gameData.write(to: fileURL)
                mySetViewController.stateRestorationActive = true
                print ("app delegate: set model data saved")
                //                let jsonString = String(data: gameData, encoding: .utf8)
                //                print ("SET encoded game status to JSON: \(String(describing: jsonString))")
            } catch {
                print ("app delegate: error occured during encoding and writing state: \(error)")
            }
        }
    }
}

