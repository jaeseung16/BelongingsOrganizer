//
//  AppDelegate.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 6/12/22.
//

import Foundation
import os
import CloudKit
import CoreData
import Persistence
import UserNotifications
#if os(macOS)
import AppKit
#else
import UIKit
#endif

class AppDelegate: NSObject {
    private let logger = Logger()
    
    private let subscriptionID = "item-updated"
    private let didCreateItemSubscription = "didCreateItemSubscription"
    private let recordType = "CD_Item"
    private let recordValueKey = "CD_name"
    
    private let databaseOperationHelper = DatabaseOperationHelper(appName: BelongsOrganizerConstants.appName.rawValue)
    
    private var database: CKDatabase {
        CKContainer(identifier: BelongsOrganizerConstants.iCloudIdentifier.rawValue).privateCloudDatabase
    }
    
    let persistence: Persistence
    let viewModel: BelongingsViewModel
    
    override init() {
        self.persistence = Persistence(name: BelongsOrganizerConstants.appName.rawValue, identifier: BelongsOrganizerConstants.iCloudIdentifier.rawValue)
        self.viewModel = BelongingsViewModel(persistence: persistence)
        
        super.init()
    }
    
    private func registerForPushNotifications() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
                guard granted else {
                    return
                }
                self?.getNotificationSettings()
            }
    }

    private func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else {
                return
            }
            DispatchQueue.main.async {
                #if os(macOS)
                NSApplication.shared.registerForRemoteNotifications()
                #else
                UIApplication.shared.registerForRemoteNotifications()
                #endif
            }
        }
    }
    
    private func subscribe() {
        guard !UserDefaults.standard.bool(forKey: didCreateItemSubscription) else {
            logger.log("alredy true: didCreateItemSubscription=\(UserDefaults.standard.bool(forKey: self.didCreateItemSubscription))")
            return
        }
        
        let subscriber = Subscriber(database: database, subscriptionID: subscriptionID, recordType: recordType)
        subscriber.subscribe { result in
            switch result {
            case .success(let subscription):
                self.logger.log("Subscribed to \(subscription, privacy: .public)")
                UserDefaults.standard.setValue(true, forKey: self.didCreateItemSubscription)
                self.logger.log("set: didCreateItemSubscription=\(UserDefaults.standard.bool(forKey: self.didCreateItemSubscription))")
            case .failure(let error):
                self.logger.log("Failed to modify subscription: \(error.localizedDescription, privacy: .public)")
                UserDefaults.standard.setValue(false, forKey: self.didCreateItemSubscription)
            }
        }
    }
    
    private func processRemoteNotification() {
        databaseOperationHelper.addDatabaseChangesOperation(database: database) { result in
            switch result {
            case .success(let record):
                self.processRecord(record)
            case .failure(let error):
                self.logger.log("Failed to process remote notification: error=\(error.localizedDescription, privacy: .public)")
            }
        }
    }
    
    private func processRecord(_ record: CKRecord) {
        guard record.recordType == recordType else {
            return
        }
        
        guard let title = record.value(forKey: recordValueKey) as? String else {
            return
        }

        logger.log("Processing \(record)")
        
        let content = UNMutableNotificationContent()
        content.title = BelongsOrganizerConstants.appName.rawValue
        content.body = title
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
        
        logger.log("Processed \(record)")
    }

}

#if os(macOS)
extension AppDelegate: NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.log("didFinishLaunchingWithOptions")
        UNUserNotificationCenter.current().delegate = self
        
        registerForPushNotifications()
        
        // TODO: - Remove or comment out after testing
        // UserDefaults.standard.setValue(false, forKey: didCreateItemSubscription)
        
        subscribe()
    }
    
    func application(_ application: NSApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { String(format: "%02.2hhx", $0) }
        let token = tokenParts.joined()
        logger.log("Device Token: \(token)")
    }
    
    func application(_ application: NSApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        logger.log("Failed to register: \(String(describing: error))")
    }

    func application(_ application: NSApplication, didReceiveRemoteNotification userInfo: [String : Any]) {
        guard let notification = CKNotification(fromRemoteNotificationDictionary: userInfo) else {
            logger.log("notification=failed")
            return
        }
        logger.log("notification=\(String(describing: notification))")
        if !notification.isPruned && notification.notificationType == .database {
            if let databaseNotification = notification as? CKDatabaseNotification, databaseNotification.subscriptionID == subscriptionID {
                logger.log("databaseNotification=\(String(describing: databaseNotification.subscriptionID))")
                processRemoteNotification()
            }
        }
    }
    
}
#else
extension AppDelegate: UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
       
        logger.log("didFinishLaunchingWithOptions")
        UNUserNotificationCenter.current().delegate = self
        
        registerForPushNotifications()
        
        // TODO: - Remove or comment out after testing
        //UserDefaults.standard.setValue(false, forKey: didCreateArticleSubscription)
        
        subscribe()

        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { String(format: "%02.2hhx", $0) }
        let token = tokenParts.joined()
        logger.log("Device Token: \(token)")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        logger.log("Failed to register: \(String(describing: error))")
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        guard let notification = CKNotification(fromRemoteNotificationDictionary: userInfo) else {
            logger.log("notification=failed")
            completionHandler(.failed)
            return
        }
        logger.log("notification=\(String(describing: notification))")
        if !notification.isPruned && notification.notificationType == .database {
            if let databaseNotification = notification as? CKDatabaseNotification, databaseNotification.subscriptionID == subscriptionID {
                logger.log("databaseNotification=\(String(describing: databaseNotification.subscriptionID))")
                processRemoteNotification()
            }
        }
        
        completionHandler(.newData)
    }
}
#endif

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        logger.info("userNotificationCenter: notification=\(notification)")
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        logger.info("userNotificationCenter: response=\(response, privacy: .public)")
        viewModel.stringToSearch = response.notification.request.content.body
        completionHandler()
    }
}
