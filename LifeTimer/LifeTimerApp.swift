//
//  LifeTimerApp.swift
//  LifeTimer
//
//  Created by Revis on 2025/7/31.
//

import SwiftUI
import UserNotifications

@main
struct LifeTimerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            LaunchScreenView()
        }
    }
}

// MARK: - 应用委托
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 设置通知委托
        UNUserNotificationCenter.current().delegate = self
        
        // 设置通知类别
        AlarmStore.setupNotificationCategories()
        
        return true
    }
    
    // MARK: - 通知委托方法
    
    /// 应用在前台时收到通知
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        let identifier = notification.request.identifier
        let category = notification.request.content.categoryIdentifier
        
        print("🔔 收到前台通知 - ID: \(identifier), 类别: \(category)")
        
        // 检查是否是闹钟通知
        if category == "ALARM_CATEGORY" {
            print("⏰ 这是闹钟通知，触发闹钟界面")
            
            // 应用在前台时，不显示系统通知，直接触发闹钟界面
            DispatchQueue.main.async {
                print("📢 发送 alarmTriggered 通知")
                NotificationCenter.default.post(name: .alarmTriggered, object: identifier)
            }
            completionHandler([]) // 不显示系统通知
        } else {
            print("📱 其他类型通知，正常显示")
            // 其他通知正常显示
            completionHandler([.alert, .sound, .badge])
        }
    }
    
    /// 用户点击通知时调用
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let identifier = response.notification.request.identifier
        let actionIdentifier = response.actionIdentifier
        
        print("👆 用户与通知交互 - ID: \(identifier), 操作: \(actionIdentifier)")
        
        DispatchQueue.main.async {
            switch actionIdentifier {
            case "STOP_ALARM":
                print("⏹️ 用户点击停止按钮")
                // 用户点击了停止按钮
                NotificationCenter.default.post(name: .alarmStopped, object: identifier)
                
            case "SNOOZE_ALARM":
                print("😴 用户点击稍后提醒按钮")
                // 用户点击了稍后提醒按钮
                NotificationCenter.default.post(name: .alarmSnoozed, object: identifier)
                
            case UNNotificationDefaultActionIdentifier:
                print("📱 用户点击通知本身，触发闹钟界面")
                // 用户点击了通知本身（默认操作）
                NotificationCenter.default.post(name: .alarmTriggered, object: identifier)
                
            default:
                print("❓ 未知的通知操作: \(actionIdentifier)")
                break
            }
        }
        
        completionHandler()
    }
}

// MARK: - 通知名称扩展
extension Notification.Name {
    static let alarmTriggered = Notification.Name("alarmTriggered")
    static let alarmStopped = Notification.Name("alarmStopped")
    static let alarmSnoozed = Notification.Name("alarmSnoozed")
}
