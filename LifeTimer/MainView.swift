//
//  MainView.swift
//  LifeTimer
//
//  Created by LifeTimer Team on 2024/12/19.
//  主页面 - 闹钟列表界面
//

import SwiftUI
import UserNotifications

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
                }
            }
            .navigationTitle("LifeTimer")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button("检查通知权限") {
                            alarmStore.checkNotificationPermission()
                        }
                        
                        Button("检查待处理通知") {
                            alarmStore.checkPendingNotifications()
                        }
                        
                        Button("测试闹钟响起") {
                            testAlarmRinging()
                        }
                        
                        Button("检查错过的闹钟") {
                            checkForMissedAlarms()
                        }
                        
                        Button("创建1分钟后测试闹钟") {
                            createTestAlarm()
                        }
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                    .accessibilityLabel("调试菜单")
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                    .accessibilityLabel("设置")
                }
            }
            .overlay(
                // 浮动添加按钮
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingAddButton {
                            showingNewAlarm = true
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 34)
                    }
                }
            )
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
            if let alarm = ringingAlarm {
                AlarmRingingView(isPresented: $showingAlarmRinging, alarm: alarm)
                    .environmentObject(alarmStore)
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
                
                if let alarm = alarmStore.alarms.first(where: { $0.id.uuidString == alarmId }) {
                    print("✅ 找到匹配的闹钟: \(alarm.timeString)")
                    ringingAlarm = alarm
                    showingAlarmRinging = true
                    print("🎵 闹钟响起界面已显示")
                } else {
                    print("❌ 未找到匹配的闹钟")
                }
            } else {
                print("❌ 通知对象不是字符串类型")
            }
        }
        
        // 监听闹钟停止通知
        NotificationCenter.default.addObserver(
            forName: .alarmStopped,
            object: nil,
            queue: .main
        ) { notification in
            showingAlarmRinging = false
            ringingAlarm = nil
        }
        
        // 监听闹钟稍后提醒通知
        NotificationCenter.default.addObserver(
            forName: .alarmSnoozed,
            object: nil,
            queue: .main
        ) { notification in
            if let alarmId = notification.object as? String,
               let alarm = alarmStore.alarms.first(where: { $0.id.uuidString == alarmId }) {
                // 设置5分钟后的稍后提醒
                scheduleSnoozeAlarm(for: alarm)
            }
            showingAlarmRinging = false
            ringingAlarm = nil
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
    
    // MARK: - 测试功能
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
                    
                    // 如果是一次性闹钟，触发后禁用
                    if alarm.repeatMode == .once {
                        alarmStore.toggleAlarm(alarm)
                        print("   ⏸️ 一次性闹钟已自动禁用")
                    }
                    
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
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(alarms) { alarm in
                    AlarmCardView(
                        alarm: alarm,
                        onToggle: { onToggle(alarm) },
                        onEdit: { onEdit(alarm) }
                    )
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
            .padding(.horizontal)
        }
    }
}

// MARK: - 闹钟卡片视图
struct AlarmCardView: View {
    let alarm: Alarm
    let onToggle: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 16) {
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
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(alarm.isEnabled ? 0.15 : 0.08))
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(alarm.isEnabled ? 0.3 : 0.1), lineWidth: 1)
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

// MARK: - 浮动添加按钮
struct FloatingAddButton: View {
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .accessibilityLabel("添加新闹钟")
    }
}

// MARK: - 预览
#Preview {
    MainView()
}