//
//  Alarm.swift
//  LifeTimer
//
//  Created by LifeTimer Team on 2024/12/19.
//  闹钟数据模型
//

import Foundation
import SwiftUI

// MARK: - 闹钟数据模型
struct Alarm: Identifiable, Codable {
    let id = UUID()
    var hour: Int
    var minute: Int
    var repeatMode: RepeatMode
    var isEnabled: Bool
    var volume: Double
    var createdAt: Date
    var modifiedAt: Date
    
    // MARK: - 初始化
    init(hour: Int = 7, minute: Int = 0, repeatMode: RepeatMode = .weekdays, isEnabled: Bool = true, volume: Double = 0.8) {
        self.hour = hour
        self.minute = minute
        self.repeatMode = repeatMode
        self.isEnabled = isEnabled
        self.volume = volume
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
    
    // MARK: - 计算属性
    
    /// 格式化的时间字符串 (HH:mm)
    var timeString: String {
        String(format: "%02d:%02d", hour, minute)
    }
    
    /// 重复模式描述
    var repeatModeDescription: String {
        repeatMode.description
    }
    
    /// 下次响铃时间
    var nextAlarmDate: Date? {
        guard isEnabled else { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        
        // 创建今天的闹钟时间
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = hour
        components.minute = minute
        components.second = 0
        
        guard let todayAlarmTime = calendar.date(from: components) else { return nil }
        
        switch repeatMode {
        case .once:
            // 一次性闹钟
            if todayAlarmTime > now {
                return todayAlarmTime
            } else {
                // 如果今天的时间已过，则设为明天
                return calendar.date(byAdding: .day, value: 1, to: todayAlarmTime)
            }
            
        case .daily:
            // 每日重复
            if todayAlarmTime > now {
                return todayAlarmTime
            } else {
                return calendar.date(byAdding: .day, value: 1, to: todayAlarmTime)
            }
            
        case .weekdays:
            // 工作日重复 (周一到周五)
            return nextWeekdayAlarmDate(from: todayAlarmTime, calendar: calendar, now: now)
            
        case .weekends:
            // 周末重复 (周六和周日)
            return nextWeekendAlarmDate(from: todayAlarmTime, calendar: calendar, now: now)
            
        case .custom(let weekdays):
            // 自定义重复
            return nextCustomAlarmDate(from: todayAlarmTime, calendar: calendar, now: now, weekdays: weekdays)
        }
    }
    
    // MARK: - 私有方法
    
    private func nextWeekdayAlarmDate(from alarmTime: Date, calendar: Calendar, now: Date) -> Date? {
        let weekdays = [2, 3, 4, 5, 6] // 周一到周五
        return nextAlarmDate(from: alarmTime, calendar: calendar, now: now, targetWeekdays: weekdays)
    }
    
    private func nextWeekendAlarmDate(from alarmTime: Date, calendar: Calendar, now: Date) -> Date? {
        let weekends = [1, 7] // 周日和周六
        return nextAlarmDate(from: alarmTime, calendar: calendar, now: now, targetWeekdays: weekends)
    }
    
    private func nextCustomAlarmDate(from alarmTime: Date, calendar: Calendar, now: Date, weekdays: Set<Int>) -> Date? {
        let targetWeekdays = Array(weekdays).sorted()
        return nextAlarmDate(from: alarmTime, calendar: calendar, now: now, targetWeekdays: targetWeekdays)
    }
    
    private func nextAlarmDate(from alarmTime: Date, calendar: Calendar, now: Date, targetWeekdays: [Int]) -> Date? {
        let currentWeekday = calendar.component(.weekday, from: now)
        
        // 检查今天是否是目标日期且时间未过
        if targetWeekdays.contains(currentWeekday) && alarmTime > now {
            return alarmTime
        }
        
        // 寻找下一个目标日期
        for i in 1...7 {
            guard let nextDate = calendar.date(byAdding: .day, value: i, to: alarmTime) else { continue }
            let nextWeekday = calendar.component(.weekday, from: nextDate)
            
            if targetWeekdays.contains(nextWeekday) {
                return nextDate
            }
        }
        
        return nil
    }
}

// MARK: - 重复模式枚举
enum RepeatMode: Codable, CaseIterable, Equatable {
    case once           // 仅一次
    case daily          // 每天
    case weekdays       // 工作日 (周一到周五)
    case weekends       // 周末 (周六、周日)
    case custom(Set<Int>) // 自定义 (1=周日, 2=周一, ..., 7=周六)
    
    // 为了支持CaseIterable，提供所有非关联值的case
    static var allCases: [RepeatMode] {
        return [.once, .daily, .weekdays, .weekends]
    }
    
    var description: String {
        switch self {
        case .once:
            return "仅一次"
        case .daily:
            return "每天"
        case .weekdays:
            return "工作日"
        case .weekends:
            return "周末"
        case .custom(let weekdays):
            if weekdays.isEmpty {
                return "从不"
            }
            let dayNames = ["", "周日", "周一", "周二", "周三", "周四", "周五", "周六"]
            let selectedDays = weekdays.sorted().compactMap { dayNames[safe: $0] }
            return selectedDays.joined(separator: ", ")
        }
    }
    
    var shortDescription: String {
        switch self {
        case .once:
            return "一次"
        case .daily:
            return "每天"
        case .weekdays:
            return "工作日"
        case .weekends:
            return "周末"
        case .custom:
            return "自定义"
        }
    }
}

// MARK: - Alarm 扩展
extension Alarm {
    /// 创建用于测试的示例闹钟
    static var sampleAlarms: [Alarm] {
        [
            Alarm(hour: 7, minute: 0, repeatMode: .weekdays, isEnabled: true, volume: 0.8),
            Alarm(hour: 8, minute: 30, repeatMode: .daily, isEnabled: false, volume: 0.6),
            Alarm(hour: 9, minute: 15, repeatMode: .weekends, isEnabled: true, volume: 0.9),
            Alarm(hour: 22, minute: 0, repeatMode: .once, isEnabled: true, volume: 0.7)
        ]
    }
    
    /// 更新修改时间
    mutating func updateModifiedDate() {
        modifiedAt = Date()
    }
}

// MARK: - Array 安全访问扩展
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}