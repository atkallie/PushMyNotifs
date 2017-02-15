//
//  AppDelegate.swift
//  PushMyNotifs
//
//  Created by Ahmed T Khalil on 2/13/17.
//  Copyright © 2017 kalikans. All rights reserved.
//

import UIKit
import UserNotifications

import Firebase
import FirebaseMessaging
import FirebaseInstanceID

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        FIRApp.configure()
        
        if #available(iOS 10.0, *){
            //just like with local notifications, you have to ask permission first
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.badge,.sound], completionHandler:{(_, _) in})
            
            //...and set the notification center delegates (necessary protocols included in extensions below)
            //UNUserNotificationCenter.current().delegate = self
            FIRMessaging.messaging().remoteMessageDelegate = self
        }else {
            let settings: UIUserNotificationSettings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        //register for remote notifications (only need for remote notifications...obviously)
        application.registerForRemoteNotifications()
        
        
        //NotificationCenter (as opposed to UNUserNotificationCenter) is a notification (not necessarily a user notification) dispatch table
        //Here we are basically saying that the AppDelegate will observe
        //If a notification of name ".firInstanceIDTokenRefresh" is posted, then the receiver will react by calling the registrationTokenRefresh function to alert the observer of the posting
        //NOTE: firInstanceIDTokenRefresh is fired each time a device token is generated, so essentially this observer allows you to link the token refresh event (handled by Firebase) to your application. All you have to do is re-establish the connection using this new token
       
        NotificationCenter.default.addObserver(self, selector: #selector(self.registrationTokenRefresh(_:)), name: .firInstanceIDTokenRefresh, object: nil)
        
        
        return true
    }

    
/****************************  REMOTE NOTIFICATIONS SETUP  *************************/
    
    //the application failed to register for remote notifications
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print(error)
    }
    
    // This method, which tells returns a Firebase Messaging Scope of the device token, is only needed if you have pointer swizzling disabled. Otherwise, it will do this automatically for you
     
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        //Device tokens are used by APNS to identify a device-app combination
        //Each time a device runs the app, it gets the device token from APNS and send it to the Firebase server
        //The Firebase server then stores the device token and uses it when sending notifications to a particular device running your app
        //The info to be sent in the notification is packaged into a JSON dictionary and this dictionary, along with the device token, is sent as an HTTP/2 request to APNS, which handles the final delivery to the application
        
        FIRInstanceID.instanceID().setAPNSToken(deviceToken, type: .sandbox)
        
        //You will need this token later, so be sure to store it (see https://firebase.google.com/docs/cloud-messaging/ios/first-message -> 'Access the registration token')
        
        if let refreshToken = FIRInstanceID.instanceID().token(){
            print("********* Device Token *********")
            print(refreshToken)
            print("********************************")
        }
    }
    
    func registrationTokenRefresh(_ notification: UNNotification){
        // Instance ID provides a unique identifier for each app instance and a mechanism to authenticate and authorize actions
        // Token must be refreshed since it can change if the app is deleted, restored, etc.
        
        // If the token was changed, then you have to re-establish the Firebase data connection using the new token
        connectToFCM()
    }
    
    //configure the app delegate file to use Firebase Cloud Messaging (FCM)
    func connectToFCM(){
        //if there is no token, don't bother trying to connect
        if FIRInstanceID.instanceID().token() == nil{
            return
        }
        
        //disconnect previous connection if one exists
        FIRMessaging.messaging().disconnect()
        
        FIRMessaging.messaging().connect { (error) in
            if error != nil{
                print("There was an error: \(error)")
            }else{
                print("Connected to FCM")
            }
        }
    }

    
    /*
    //still don't understand
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        completionHandler(.newData)
    }
    */
    
/****************************  APP DELEGATE BOILER PLATE CODE  *************************/
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        
        //disconnect the Firebase data connection when app enters background
        FIRMessaging.messaging().disconnect()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        
        
        //connect the Firebase data connection when app enters foreground
        connectToFCM()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        //connect the Firebase data connection when app becomes active
        connectToFCM()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        
        FIRMessaging.messaging().disconnect()
    }
}


/******************** FIREBASE MESSAGING DELEGATE ********************/

//for data message handling
//alert app if anything is received from the Firebase server
extension AppDelegate: FIRMessagingDelegate{
    func applicationReceivedRemoteMessage(_ remoteMessage: FIRMessagingRemoteMessage) {
        print(remoteMessage.appData)
        print("********************")
        print(remoteMessage)
    }
}


/******************** USER NOTIFICATIONS CENTER INITIALIZATION (NOT NEEDED FOR SIMPLE PUSH NOTIFICATIONS) ******************************/
/*
@available(iOS 10.0, *)
//for notification (message) handling
extension AppDelegate: UNUserNotificationCenterDelegate{
    //to deliver notifications while app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        //preferred presentation option
        completionHandler([.alert])
    }
    
    //if you have any actions along with your notification, this is where you would handle what functionality they have
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print(response.actionIdentifier)
        completionHandler()
    }
}

*/










