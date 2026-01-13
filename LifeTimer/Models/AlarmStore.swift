//
//  AlarmStore.swift
//  LifeTimer
//
//  Created by LifeTimer Team on 2024/12/19.
//  闹钟数据管理类
//

import Foundation
import SwiftUI
import UserNotifications

// MARK: - 闹钟数据管理类
class AlarmStore: ObservableObject {
    @Published var alarms: [Alarm] = []
    private let userDefaults = UserDefaults.standard
    private let alarmsKey = "SavedAlarms"
    
    // MARK: - 初始化
    init() {
        loadAlarms()
        
        // 添加示例数据（仅在首次启动时）
        if alarms.isEmpty {
            addSampleAlarms()
        }
    }
    
    // MARK: - 闹钟管理方法
    
    /// 添加新闹钟
    func addAlarm(_ alarm: Alarm) {
        alarms.append(alarm)
        saveAlarms()
        scheduleNotification(for: alarm)
    }
    
    /// 更新闹钟
    func updateAlarm(_ alarm: Alarm) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            var updatedAlarm = alarm
            updatedAlarm.updateModifiedDate()
            alarms[index] = updatedAlarm
            saveAlarms()
            
            // 重新安排通知
            cancelNotification(for: alarm)
            if updatedAlarm.isEnabled {
                scheduleNotification(for: updatedAlarm)
            }
        }
    }
    
    /// 删除闹钟
    func deleteAlarm(_ alarm: Alarm) {
        alarms.removeAll { $0.id == alarm.id }
        saveAlarms()
        cancelNotification(for: alarm)
    }
    
    /// 切换闹钟开关状态
    func toggleAlarm(_ alarm: Alarm) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index].isEnabled.toggle()
            alarms[index].updateModifiedDate()
            saveAlarms()
            
            if alarms[index].isEnabled {
                scheduleNotification(for: alarms[index])
            } else {
                cancelNotification(for: alarm)
            }
        }
    }
    

    
    // MARK: - 数据持久化
    
    private func saveAlarms() {
        if let encoded = try? JSONEncoder().encode(alarms) {
            userDefaults.set(encoded, forKey: alarmsKey)
        }
    }
    
    private func loadAlarms() {
        if let data = userDefaults.data(forKey: alarmsKey),
           let decoded = try? JSONDecoder().decode([Alarm].self, from: data) {
            alarms = decoded
        }
    }
    

    
    // MARK: - 通知管理
    
    private func scheduleNotification(for alarm: Alarm) {
        guard alarm.isEnabled else { 
            print("⏸️ 闹钟已禁用，跳过通知调度: \(alarm.timeString)")
            return 
        }
        
        guard let nextAlarmDate = alarm.nextAlarmDate else { 
            print("❌ 无法计算下次响铃时间: \(alarm.timeString)")
            return 
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        print("📅 为闹钟调度通知: \(alarm.timeString), 下次响铃: \(formatter.string(from: nextAlarmDate))")
        
        let content = UNMutableNotificationContent()
        content.title = "LifeTimer"
        content.body = "Time to wake up! Get ready for a wonderful day!"
        content.sound = .default
        content.categoryIdentifier = "ALARM_CATEGORY"
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: nextAlarmDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        print("🔔 通知触发器设置: 年=\(components.year ?? 0), 月=\(components.month ?? 0), 日=\(components.day ?? 0), 时=\(components.hour ?? 0), 分=\(components.minute ?? 0)")
        
        let request = UNNotificationRequest(
            identifier: alarm.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ 添加通知失败: \(error.localizedDescription)")
                } else {
                    print("✅ 通知已成功添加: \(alarm.timeString), ID: \(alarm.id.uuidString)")
                }
            }
        }
    }
    
    private func cancelNotification(for alarm: Alarm) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [alarm.id.uuidString])
        print("🗑️ 已取消闹钟通知: \(alarm.timeString)")
    }
    
    // MARK: - 调试方法
    
    /// 检查所有待处理的通知（调试用）
    func checkPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("\n📋 当前待处理的通知数量: \(requests.count)")
            
            for request in requests {
                if let trigger = request.trigger as? UNCalendarNotificationTrigger,
                   let nextTriggerDate = trigger.nextTriggerDate() {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    formatter.timeStyle = .short
                    formatter.locale = Locale(identifier: "zh_CN")
                    
                    print("🔔 通知ID: \(request.identifier)")
                    print("   标题: \(request.content.title)")
                    print("   下次触发: \(formatter.string(from: nextTriggerDate))")
                    print("   重复: \(trigger.repeats ? "是" : "否")")
                    print("   ---")
                }
            }
            print("")
        }
    }
    
    /// 检查通知权限状态
    func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                print("\n🔐 通知权限状态:")
                print("   授权状态: \(settings.authorizationStatus.rawValue)")
                print("   声音权限: \(settings.soundSetting.rawValue)")
                print("   提醒权限: \(settings.alertSetting.rawValue)")
                print("   角标权限: \(settings.badgeSetting.rawValue)")
                print("")
            }
        }
    }
    
    // MARK: - 示例数据
    
    private func addSampleAlarms() {
        let sampleAlarms = [
            Alarm(hour: 7, minute: 0, repeatMode: .daily, isEnabled: true, volume: 0.8),
            Alarm(hour: 9, minute: 0, repeatMode: .once, isEnabled: false, volume: 0.7)
        ]
        
        for alarm in sampleAlarms {
            addAlarm(alarm)
        }
    }
}

// MARK: - 通知类别设置
extension AlarmStore {
    /// 设置通知类别和操作
    static func setupNotificationCategories() {
        let stopAction = UNNotificationAction(
            identifier: "STOP_ALARM",
            title: "Stop Alarm",
            options: [.foreground]
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ALARM",
            title: "Snooze",
            options: []
        )
        
        let alarmCategory = UNNotificationCategory(
            identifier: "ALARM_CATEGORY",
            actions: [stopAction, snoozeAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([alarmCategory])
    }
}