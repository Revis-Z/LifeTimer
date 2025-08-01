//
//  SettingsView.swift
//  LifeTimer
//
//  Created by LifeTimer Team on 2024/12/19.
//  应用设置页面 - 管理应用配置和权限
//

import SwiftUI
import UserNotifications
import StoreKit
import UIKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var alarmStore: AlarmStore
    
    // 状态管理
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var showingNotificationAlert = false
    @State private var showingAboutSheet = false
    @State private var showingVoiceContentView = false
    
    // 应用偏好设置
    @AppStorage("enableHapticFeedback") private var enableHapticFeedback = true
    @AppStorage("enableSoundPreview") private var enableSoundPreview = true
    @AppStorage("autoLockPrevention") private var autoLockPrevention = true
    @AppStorage("showTimeIn24Hour") private var showTimeIn24Hour = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景渐变
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        Color.blue.opacity(0.1),
                        Color.purple.opacity(0.05)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                Form {
                    // 通知权限设置
                    Section {
                        notificationPermissionRow
                    } header: {
                        Text("通知权限")
                            .foregroundColor(.cyan)
                    } footer: {
                        Text("允许通知权限以确保闹钟能够正常工作")
                            .foregroundColor(.gray)
                    }
                    
                    // 应用偏好设置
                    Section {
                        hapticFeedbackRow
                        soundPreviewRow
                        autoLockPreventionRow
                        timeFormatRow
                    } header: {
                        Text("应用偏好")
                            .foregroundColor(.cyan)
                    }
                    
                    // 内容管理
                    Section {
                        voiceContentRow
                    } header: {
                        Text("内容管理")
                            .foregroundColor(.cyan)
                    }
                    
                    // 反馈与支持
                    Section {
                        rateAppRow
                        feedbackRow
                        aboutRow
                    } header: {
                        Text("反馈与支持")
                            .foregroundColor(.cyan)
                    }
                    
                    // 版本信息
                    Section {
                        versionInfoRow
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .accessibilityLabel("完成设置")
                }
            }
            .onAppear {
                checkNotificationPermission()
            }
            .alert("通知权限", isPresented: $showingNotificationAlert) {
                Button("去设置") {
                    openAppSettings()
                }
                Button("取消", role: .cancel) { }
            } message: {
                Text("请在设置中允许LifeTimer发送通知，以确保闹钟功能正常工作。")
            }
            .sheet(isPresented: $showingAboutSheet) {
                AboutView()
            }
            .sheet(isPresented: $showingVoiceContentView) {
                VoiceContentView()
                    .environmentObject(alarmStore)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - 设置行组件
    
    private var notificationPermissionRow: some View {
        HStack {
            Image(systemName: "bell.fill")
                .foregroundColor(.cyan)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("通知权限")
                    .foregroundColor(.white)
                
                Text(notificationStatusText)
                    .font(.caption)
                    .foregroundColor(notificationStatusColor)
            }
            
            Spacer()
            
            if notificationStatus != .authorized {
                Button("开启") {
                    requestNotificationPermission()
                }
                .font(.caption)
                .foregroundColor(.cyan)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                        )
                )
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("通知权限，当前状态：\(notificationStatusText)")
    }
    
    private var hapticFeedbackRow: some View {
        HStack {
            Image(systemName: "iphone.radiowaves.left.and.right")
                .foregroundColor(.cyan)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("触觉反馈")
                    .foregroundColor(.white)
                
                Text("操作时提供触觉反馈")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Toggle("", isOn: $enableHapticFeedback)
                .tint(.cyan)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("触觉反馈")
        .accessibilityValue(enableHapticFeedback ? "已开启" : "已关闭")
    }
    
    private var soundPreviewRow: some View {
        HStack {
            Image(systemName: "speaker.wave.2.fill")
                .foregroundColor(.cyan)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("声音预览")
                    .foregroundColor(.white)
                
                Text("设置音量时播放预览")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Toggle("", isOn: $enableSoundPreview)
                .tint(.cyan)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("声音预览")
        .accessibilityValue(enableSoundPreview ? "已开启" : "已关闭")
    }
    
    private var autoLockPreventionRow: some View {
        HStack {
            Image(systemName: "lock.slash.fill")
                .foregroundColor(.cyan)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("防止自动锁屏")
                    .foregroundColor(.white)
                
                Text("闹钟响起时保持屏幕常亮")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Toggle("", isOn: $autoLockPrevention)
                .tint(.cyan)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("防止自动锁屏")
        .accessibilityValue(autoLockPrevention ? "已开启" : "已关闭")
    }
    
    private var timeFormatRow: some View {
        HStack {
            Image(systemName: "clock.fill")
                .foregroundColor(.cyan)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("24小时制")
                    .foregroundColor(.white)
                
                Text("使用24小时时间格式")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Toggle("", isOn: $showTimeIn24Hour)
                .tint(.cyan)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("24小时制")
        .accessibilityValue(showTimeIn24Hour ? "已开启" : "已关闭")
    }
    
    private var voiceContentRow: some View {
        Button(action: {
            showingVoiceContentView = true
        }) {
            HStack {
                Image(systemName: "music.note.list")
                    .foregroundColor(.cyan)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("语音内容管理")
                        .foregroundColor(.white)
                    
                    Text("查看和管理励志语音")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
        }
        .accessibilityLabel("语音内容管理")
        .accessibilityHint("查看和管理励志语音内容")
    }
    

    
    private var rateAppRow: some View {
        Button(action: {
            requestAppReview()
        }) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("给应用评分")
                        .foregroundColor(.white)
                    
                    Text("在App Store中评价我们")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
        }
        .accessibilityLabel("给应用评分")
        .accessibilityHint("在App Store中为应用评分")
    }
    
    private var feedbackRow: some View {
        Button(action: {
            sendFeedback()
        }) {
            HStack {
                Image(systemName: "envelope.fill")
                    .foregroundColor(.cyan)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("意见反馈")
                        .foregroundColor(.white)
                    
                    Text("发送反馈和建议")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
        }
        .accessibilityLabel("意见反馈")
        .accessibilityHint("发送反馈和建议给开发团队")
    }
    
    private var aboutRow: some View {
        Button(action: {
            showingAboutSheet = true
        }) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.cyan)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("关于LifeTimer")
                        .foregroundColor(.white)
                    
                    Text("应用信息和开发团队")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
        }
        .accessibilityLabel("关于LifeTimer")
        .accessibilityHint("查看应用信息和开发团队介绍")
    }
    
    private var versionInfoRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("版本信息")
                    .foregroundColor(.white)
                    .font(.caption)
                
                Text("LifeTimer v\(appVersion)")
                    .foregroundColor(.gray)
                    .font(.caption2)
                
                Text("构建版本 \(buildNumber)")
                    .foregroundColor(.gray)
                    .font(.caption2)
            }
            
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("版本信息：LifeTimer v\(appVersion)，构建版本 \(buildNumber)")
    }
    
    // MARK: - 计算属性
    
    private var notificationStatusText: String {
        switch notificationStatus {
        case .authorized:
            return "已授权"
        case .denied:
            return "已拒绝"
        case .notDetermined:
            return "未设置"
        case .provisional:
            return "临时授权"
        case .ephemeral:
            return "临时授权"
        @unknown default:
            return "未知状态"
        }
    }
    
    private var notificationStatusColor: Color {
        switch notificationStatus {
        case .authorized:
            return .green
        case .denied:
            return .red
        case .notDetermined:
            return .orange
        case .provisional, .ephemeral:
            return .yellow
        @unknown default:
            return .gray
        }
    }
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    // MARK: - 方法
    
    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationStatus = settings.authorizationStatus
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    self.notificationStatus = .authorized
                } else {
                    self.showingNotificationAlert = true
                }
            }
        }
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    private func requestAppReview() {
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
    
    private func sendFeedback() {
        let email = "feedback@lifetimer.app"
        let subject = "LifeTimer 意见反馈"
        let body = """
        
        
        ---
        应用版本: \(appVersion) (\(buildNumber))
        设备型号: \(UIDevice.current.model)
        系统版本: \(UIDevice.current.systemVersion)
        """
        
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let url = URL(string: "mailto:\(email)?subject=\(encodedSubject)&body=\(encodedBody)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - 关于页面

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景渐变
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        Color.blue.opacity(0.1),
                        Color.purple.opacity(0.05)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // 应用图标和名称
                        VStack(spacing: 16) {
                            Image(systemName: "alarm.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.cyan)
                            
                            Text("LifeTimer")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("励志闹钟应用")
                                .font(.title3)
                                .foregroundColor(.gray)
                        }
                        
                        // 应用描述
                        VStack(alignment: .leading, spacing: 16) {
                            Text("关于应用")
                                .font(.headline)
                                .foregroundColor(.cyan)
                            
                            Text("LifeTimer是一款专注于励志语音唤醒的iOS闹钟应用。通过高质量的励志语音内容替代传统闹铃声，为用户提供积极正面的起床体验，帮助用户以更好的心态开始每一天。")
                                .foregroundColor(.white.opacity(0.9))
                                .lineSpacing(4)
                        }
                        
                        // 开发团队
                        VStack(alignment: .leading, spacing: 16) {
                            Text("开发团队")
                                .font(.headline)
                                .foregroundColor(.cyan)
                            
                            Text("LifeTimer Team")
                                .foregroundColor(.white)
                            
                            Text("致力于为用户提供优质的移动应用体验")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                        
                        // 版权信息
                        VStack(spacing: 8) {
                            Text("© 2024 LifeTimer Team")
                                .foregroundColor(.gray)
                                .font(.caption)
                            
                            Text("All rights reserved")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                }
            }
            .navigationTitle("关于")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AlarmStore())
}