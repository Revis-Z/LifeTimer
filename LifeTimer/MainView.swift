//
//  MainView.swift
//  LifeTimer
//
//  Created by LifeTimer Team on 2024/12/19.
//  主页面 - 闹钟列表界面
//

import SwiftUI
import UserNotifications
import UIKit

// MARK: - 主页面视图
struct MainView: View {
    @StateObject private var alarmStore = AlarmStore()
    @State private var showingSettings = false
    @State private var showingNewAlarm = false
    @State private var selectedAlarm: Alarm?
    @State private var showingAlarmRinging = false
    @State private var ringingAlarm: Alarm?
    @State private var alarmCheckTimer: Timer?
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景渐变
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.2),
                        Color(red: 0.05, green: 0.05, blue: 0.15)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 闹钟列表或空状态
                    if alarmStore.alarms.isEmpty {
                        EmptyStateView()
                    } else {
                        AlarmListView(
                            alarms: alarmStore.alarms,
                            onToggle: { alarm in
                                alarmStore.toggleAlarm(alarm)
                            },
                            onEdit: { alarm in
                                selectedAlarm = alarm
                            },
                            onDelete: { alarm in
                                alarmStore.deleteAlarm(alarm)
                            }
                        )
                    }
                    
                    Spacer()
                    
                    // 底部导航栏
                    BottomNavigationBar(
                        onSettingsTapped: {
                            showingSettings = true
                        },
                        onAddAlarmTapped: {
                            showingNewAlarm = true
                        }
                    )
                }
            }
            .navigationTitle("LifeTimer")
            .navigationBarTitleDisplayMode(.large)
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingNewAlarm) {
            AlarmSettingView(alarm: .constant(nil), isPresented: $showingNewAlarm)
                .environmentObject(alarmStore)
        }
        .sheet(item: $selectedAlarm) { alarm in
            AlarmSettingView(alarm: .constant(alarm), isPresented: .constant(true))
                .environmentObject(alarmStore)
        }
        .fullScreenCover(isPresented: $showingAlarmRinging) {
            // 使用局部变量保存闹钟数据，避免在显示期间被清空
            let alarmToShow = ringingAlarm
            
            if let alarm = alarmToShow {
                AlarmRingingView(isPresented: $showingAlarmRinging, alarm: alarm)
                    .environmentObject(alarmStore)
                    .onAppear {
                        print("🎬 fullScreenCover 被触发")
                        print("📊 showingAlarmRinging: \(showingAlarmRinging)")
                        print("📊 ringingAlarm: \(alarm.timeString)")
                        print("✅ 创建 AlarmRingingView")
                    }
            } else {
                // 如果没有闹钟数据，创建一个当前时间的临时闹钟
                let now = Date()
                let calendar = Calendar.current
                let hour = calendar.component(.hour, from: now)
                let minute = calendar.component(.minute, from: now)
                
                let fallbackAlarm = Alarm(
                    hour: hour,
                    minute: minute,
                    repeatMode: .once,
                    isEnabled: true,
                    volume: 0.8
                )
                
                AlarmRingingView(isPresented: $showingAlarmRinging, alarm: fallbackAlarm)
                    .environmentObject(alarmStore)
                    .onAppear {
                        print("⚠️ 使用备用闹钟数据显示界面")
                        print("📊 备用闹钟时间: \(fallbackAlarm.timeString)")
                    }
            }
        }
        .onAppear {
            requestNotificationPermission()
            setupNotificationObservers()
            setupAppStateObservers()
            startAlarmCheckTimer()
        }
        .onDisappear {
            removeNotificationObservers()
            removeAppStateObservers()
            stopAlarmCheckTimer()
        }
    }
    
    // MARK: - 请求通知权限
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("通知权限请求失败: \(error)")
            } else if granted {
                print("通知权限已获取")
            } else {
                print("通知权限被拒绝")
            }
        }
    }
    
    // MARK: - 通知监听设置
    private func setupNotificationObservers() {
        // 监听闹钟触发通知
        NotificationCenter.default.addObserver(
            forName: .alarmTriggered,
            object: nil,
            queue: .main
        ) { notification in
            print("📢 收到 alarmTriggered 通知")
            
            if let alarmId = notification.object as? String {
                print("🔍 查找闹钟 ID: \(alarmId)")
                print("📊 当前闹钟总数: \(self.alarmStore.alarms.count)")
                
                // 打印所有闹钟的ID用于调试
                for (index, alarm) in self.alarmStore.alarms.enumerated() {
                    print("📋 闹钟[\(index)]: ID=\(alarm.id.uuidString), 时间=\(alarm.timeString), 启用=\(alarm.isEnabled)")
                }
                
                // 查找匹配的闹钟
                if let alarm = self.alarmStore.alarms.first(where: { $0.id.uuidString == alarmId }) {
                    print("✅ 找到匹配的闹钟: \(alarm.timeString)")
                    
                    // 确保在主线程上原子性地设置状态
                    DispatchQueue.main.async {
                        print("🔄 在主线程设置闹钟状态")
                        self.ringingAlarm = alarm
                        print("📱 ringingAlarm 已设置: \(alarm.timeString)")
                        self.showingAlarmRinging = true
                        print("🎵 showingAlarmRinging 已设置为 true")
                        print("🎵 闹钟响起界面已显示")
                    }
                } else {
                    print("❌ 未找到匹配的闹钟")
                    print("🔍 尝试使用部分匹配查找...")
                    
                    // 尝试部分匹配（前8位）
                    let shortId = String(alarmId.prefix(8))
                    if let alarm = self.alarmStore.alarms.first(where: { $0.id.uuidString.hasPrefix(shortId) }) {
                        print("✅ 通过部分匹配找到闹钟: \(alarm.timeString)")
                        
                        DispatchQueue.main.async {
                            self.ringingAlarm = alarm
                            self.showingAlarmRinging = true
                            print("🎵 通过部分匹配显示闹钟界面")
                        }
                    } else {
                        print("❌ 部分匹配也未找到闹钟")
                        
                        // 如果找不到闹钟，创建一个临时闹钟用于显示
                        let now = Date()
                        let calendar = Calendar.current
                        let hour = calendar.component(.hour, from: now)
                        let minute = calendar.component(.minute, from: now)
                        
                        let tempAlarm = Alarm(
                            hour: hour,
                            minute: minute,
                            repeatMode: .once,
                            isEnabled: true,
                            volume: 0.8
                        )
                        
                        print("🆘 创建临时闹钟用于显示: \(tempAlarm.timeString)")
                        
                        DispatchQueue.main.async {
                            self.ringingAlarm = tempAlarm
                            self.showingAlarmRinging = true
                            print("🎵 使用临时闹钟显示界面")
                        }
                    }
                }
            } else {
                print("❌ 通知对象不是字符串类型: \(String(describing: notification.object))")
            }
        }
        
        // 监听闹钟停止通知
        NotificationCenter.default.addObserver(
            forName: .alarmStopped,
            object: nil,
            queue: .main
        ) { notification in
            print("🛑 收到闹钟停止通知")
            
            // 如果当前有响铃的闹钟且是一次性闹钟，则禁用它
            if let currentAlarm = self.ringingAlarm, currentAlarm.repeatMode == .once {
                print("⏸️ 禁用一次性闹钟: \(currentAlarm.timeString)")
                self.alarmStore.toggleAlarm(currentAlarm)
            }
            
            self.showingAlarmRinging = false
            self.ringingAlarm = nil
            print("✅ 闹钟界面已关闭")
        }
        
        // 监听闹钟稍后提醒通知
        NotificationCenter.default.addObserver(
            forName: .alarmSnoozed,
            object: nil,
            queue: .main
        ) { notification in
            print("😴 收到稍后提醒通知")
            
            if let alarmId = notification.object as? String,
               let alarm = self.alarmStore.alarms.first(where: { $0.id.uuidString == alarmId }) {
                // 设置5分钟后的稍后提醒
                self.scheduleSnoozeAlarm(for: alarm)
                print("⏰ 已设置5分钟后提醒")
            }
            
            self.showingAlarmRinging = false
            self.ringingAlarm = nil
            print("✅ 闹钟界面已关闭，稍后提醒已设置")
        }
    }
    
    private func removeNotificationObservers() {
        NotificationCenter.default.removeObserver(self, name: .alarmTriggered, object: nil)
        NotificationCenter.default.removeObserver(self, name: .alarmStopped, object: nil)
        NotificationCenter.default.removeObserver(self, name: .alarmSnoozed, object: nil)
    }
    
    // MARK: - 应用状态监听
    private func setupAppStateObservers() {
        // 监听应用进入前台
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            checkForMissedAlarms()
        }
        
        // 监听应用变为活跃状态
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            checkForMissedAlarms()
        }
    }
    
    private func removeAppStateObservers() {
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    // MARK: - 定时器管理
    private func startAlarmCheckTimer() {
        // 每30秒检查一次闹钟状态
        alarmCheckTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            checkForMissedAlarms()
        }
        print("⏰ 闹钟检查定时器已启动")
    }
    
    private func stopAlarmCheckTimer() {
        alarmCheckTimer?.invalidate()
        alarmCheckTimer = nil
        print("⏰ 闹钟检查定时器已停止")
    }
    
    // MARK: - 测	试功能
    private func testAlarmRinging() {
        // 创建一个测试闹钟
        let testAlarm = Alarm(hour: Calendar.current.component(.hour, from: Date()),
                             minute: Calendar.current.component(.minute, from: Date()),
                             repeatMode: .once,
                             isEnabled: true,
                             volume: 0.8)
        
        print("🔔 测试闹钟响起 - 当前时间: \(Date())")
        
        // 设置响铃闹钟并显示界面
        ringingAlarm = testAlarm
        showingAlarmRinging = true
        
        print("✅ 测试闹钟界面已触发")
    }
    
    private func directShowAlarmRinging() {
        print("🎯 直接显示闹钟页面测试")
        
        // 创建一个测试闹钟
        let testAlarm = Alarm(
            hour: Calendar.current.component(.hour, from: Date()),
            minute: Calendar.current.component(.minute, from: Date()),
            repeatMode: .once,
            isEnabled: true,
            volume: 0.8
        )
        
        print("📱 测试闹钟: \(testAlarm.timeString)")
        print("🔊 音量: \(testAlarm.volume)")
        
        DispatchQueue.main.async {
            self.ringingAlarm = testAlarm
            self.showingAlarmRinging = true
            print("✅ 闹钟页面应该已显示")
        }
    }
    
    // MARK: - 创建测试闹钟
    private func createTestAlarm() {
        let now = Date()
        let calendar = Calendar.current
        
        // 创建1分钟后的时间
        guard let testTime = calendar.date(byAdding: .minute, value: 1, to: now) else {
            print("❌ 无法创建测试时间")
            return
        }
        
        let testHour = calendar.component(.hour, from: testTime)
        let testMinute = calendar.component(.minute, from: testTime)
        
        let testAlarm = Alarm(
            hour: testHour,
            minute: testMinute,
            repeatMode: .once,
            isEnabled: true,
            volume: 0.8
        )
        
        alarmStore.addAlarm(testAlarm)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        print("🧪 已创建测试闹钟: \(testAlarm.timeString) (1分钟后: \(formatter.string(from: testTime)))")
        print("📱 请等待1分钟，观察闹钟是否触发")
    }
    
    // MARK: - 检查错过的闹钟
    private func checkForMissedAlarms() {
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        print("🔍 检查错过的闹钟 - 当前时间: \(formatter.string(from: now))")
        print("📋 总闹钟数量: \(alarmStore.alarms.count)")
        
        for (index, alarm) in alarmStore.alarms.enumerated() {
            print("⏰ 闹钟 \(index + 1): \(alarm.timeString), 启用: \(alarm.isEnabled), 重复: \(alarm.repeatModeDescription)")
            
            guard alarm.isEnabled else { 
                print("   ⏸️ 闹钟已禁用，跳过")
                continue 
            }
            
            if let nextAlarmDate = alarm.nextAlarmDate {
                print("   📅 下次响铃时间: \(formatter.string(from: nextAlarmDate))")
                
                // 检查是否应该触发（允许2分钟的误差，考虑到定时器间隔）
                let timeDifference = now.timeIntervalSince(nextAlarmDate)
                if timeDifference >= 0 && timeDifference <= 120 {
                    print("   🔔 触发闹钟！时间差: \(timeDifference)秒")
                    
                    // 触发闹钟
                    ringingAlarm = alarm
                    showingAlarmRinging = true
                    
                    // 注意：不在这里禁用一次性闹钟，而是在闹钟停止时处理
                    print("   ✅ 闹钟界面已显示，等待用户操作")
                    
                    return
                } else if timeDifference > 120 {
                    print("   ⏰ 闹钟时间已过太久: \(Int(timeDifference))秒")
                } else {
                    print("   ⏳ 闹钟尚未到时间: \(Int(-timeDifference))秒后响铃")
                }
            } else {
                print("   ❌ 无法计算下次响铃时间")
            }
        }
        
        print("✅ 检查完成，无需触发闹钟")
    }
    
    // MARK: - 稍后提醒功能
    private func scheduleSnoozeAlarm(for alarm: Alarm) {
        let content = UNMutableNotificationContent()
        content.title = "LifeTimer - 稍后提醒"
        content.body = "是时候起床了！准备好迎接美好的一天吧！"
        content.sound = .default
        content.categoryIdentifier = "ALARM_CATEGORY"
        
        // 5分钟后触发
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 300, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "\(alarm.id.uuidString)_snooze",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("设置稍后提醒失败: \(error)")
            } else {
                print("已设置5分钟后提醒")
            }
        }
    }
}



// MARK: - 空状态视图
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "alarm.fill")
                .font(.system(size: 80))
                .foregroundColor(.white.opacity(0.6))
            
            VStack(spacing: 12) {
                Text("还没有闹钟")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("点击下方的 + 按钮\n创建你的第一个励志闹钟")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("还没有闹钟，点击加号按钮创建你的第一个励志闹钟")
    }
}

// MARK: - 闹钟列表视图
struct AlarmListView: View {
    let alarms: [Alarm]
    let onToggle: (Alarm) -> Void
    let onEdit: (Alarm) -> Void
    let onDelete: (Alarm) -> Void
    
    var body: some View {
        List {
            ForEach(alarms) { alarm in
                AlarmCardView(
                    alarm: alarm,
                    onToggle: { onToggle(alarm) },
                    onEdit: { onEdit(alarm) }
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    // 删除按钮
                    Button(role: .destructive) {
                        // 添加触觉反馈
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        
                        // 执行删除
                        onDelete(alarm)
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                    .tint(.red)
                    
                    // 编辑按钮
                    Button {
                        // 添加触觉反馈
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        
                        onEdit(alarm)
                    } label: {
                        Label("编辑", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
                .contextMenu {
                    Button(action: { onEdit(alarm) }) {
                        Label("编辑", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: { onDelete(alarm) }) {
                        Label("删除", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }
}

// MARK: - 闹钟卡片视图
struct AlarmCardView: View {
    let alarm: Alarm
    let onToggle: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        let cardContent = HStack(spacing: 16) {
            // 时间显示
            VStack(alignment: .leading, spacing: 4) {
                Text(alarm.timeString)
                    .font(.system(size: 32, weight: .light, design: .default))
                    .foregroundColor(.white)
                
                Text(alarm.repeatModeDescription)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // 开关
            Toggle("", isOn: Binding(
                get: { alarm.isEnabled },
                set: { _ in onToggle() }
            ))
            .toggleStyle(CustomToggleStyle())
            .accessibilityLabel(alarm.isEnabled ? "关闭闹钟" : "开启闹钟")
        }
        .padding(20)
        
        let backgroundOpacity = alarm.isEnabled ? 0.15 : 0.08
        let strokeOpacity = alarm.isEnabled ? 0.3 : 0.1
        
        return Button(action: onEdit) {
            cardContent
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(backgroundOpacity))
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(strokeOpacity), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("闹钟 \(alarm.timeString) \(alarm.repeatModeDescription) \(alarm.isEnabled ? "已开启" : "已关闭")")
    }
}

// MARK: - 自定义开关样式
struct CustomToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                configuration.isOn.toggle()
            }
            
            // 触觉反馈
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }) {
            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? Color.blue : Color.gray.opacity(0.3))
                .frame(width: 50, height: 30)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 26, height: 26)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isOn)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 底部导航栏
struct BottomNavigationBar: View {
    let onSettingsTapped: () -> Void
    let onAddAlarmTapped: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // Home 按钮
            TabBarButton(
                icon: "house",
                title: "Home",
                isSelected: true,
                action: {}
            )
            
//            // Discover 按钮
//            TabBarButton(
//                icon: "square.grid.2x2",
//                title: "Discover",
//                isSelected: false,
//                action: {}
//            )
            
            // 中央添加按钮
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                onAddAlarmTapped()
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.6, green: 0.5, blue: 1.0),
                                        Color(red: 0.4, green: 0.3, blue: 0.9)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            }
            .buttonStyle(ScaleButtonStyle())
            
//            // Insights 按钮
//            TabBarButton(
//                icon: "chart.bar",
//                title: "Insights",
//                isSelected: false,
//                action: {}
//            )
//            
            // Profile 按钮
            TabBarButton(
                icon: "gearshape",
                title: "Setting",
                isSelected: false,
                action: onSettingsTapped
            )
        }
        .frame(height: 88)
        .background(
            // 深色背景，类似截图
            RoundedRectangle(cornerRadius: 28)
                .fill(Color(red: 0.15, green: 0.15, blue: 0.2))
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

// MARK: - 标签栏按钮
struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            action()
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? Color(red: 0.5, green: 0.4, blue: 1.0) : Color.gray)
                
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? Color(red: 0.5, green: 0.4, blue: 1.0) : Color.gray)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 按钮缩放样式
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - 预览
#Preview {
    MainView()
}
