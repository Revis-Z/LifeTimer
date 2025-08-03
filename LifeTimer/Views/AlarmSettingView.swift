//
//  AlarmSettingView.swift
//  LifeTimer
//
//  Created by LifeTimer Team on 2024/12/19.
//  闹钟设置页面
//

import SwiftUI

struct AlarmSettingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var alarmStore: AlarmStore
    
    @Binding var alarm: Alarm?
    @Binding var isPresented: Bool
    
    // 编辑状态
    @State private var selectedTime = Date()
    @State private var selectedRepeatMode: RepeatMode = .daily
    @State private var volume: Double = 0.8
    @State private var customWeekdays: Set<Int> = []
    
    // UI状态
    @State private var showingCustomRepeat = false
    
    // 是否为编辑模式
    private var isEditMode: Bool {
        alarm != nil
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景渐变
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.05, green: 0.1, blue: 0.2),
                        Color(red: 0.1, green: 0.15, blue: 0.25)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 时间选择器
                        timePickerSection
                        
                        // 重复模式选择
                        repeatModeSection
                        
                        // 音量控制
                        volumeSection
                        

                        
                        // 操作按钮
                        actionButtonsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(isEditMode ? "编辑闹钟" : "新建闹钟")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            setupInitialValues()
        }
        .sheet(isPresented: $showingCustomRepeat) {
            CustomRepeatView(selectedWeekdays: $customWeekdays)
        }
    }
    
    // MARK: - 时间选择器部分
    private var timePickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.cyan)
                    .font(.title2)
                
                Text("闹钟时间")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            // 时间选择器卡片
            VStack {
                DatePicker(
                    "选择时间",
                    selection: $selectedTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .colorScheme(.dark)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - 重复模式选择部分
    private var repeatModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "repeat")
                    .foregroundColor(.cyan)
                    .font(.title2)
                
                Text("重复模式")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                // 预设重复模式
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach([RepeatMode.once, RepeatMode.daily], id: \.description) { mode in
                        repeatModeButton(mode)
                    }
                }
                
                // 自定义重复按钮
                Button(action: {
                    selectedRepeatMode = .custom(customWeekdays)
                    showingCustomRepeat = true
                }) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.cyan)
                        
                        Text("自定义")
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        if case .custom(_) = selectedRepeatMode {
                            Image(systemName: "checkmark")
                                .foregroundColor(.cyan)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        {
                                            if case .custom(_) = selectedRepeatMode {
                                                return Color.cyan
                                            } else {
                                                return Color.clear
                                            }
                                        }(),
                                        lineWidth: 2
                                    )
                            )
                    )
                }
                .foregroundColor(.white)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - 音量控制部分
    private var volumeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "speaker.wave.2")
                    .foregroundColor(.cyan)
                    .font(.title2)
                
                Text("音量")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(Int(volume * 100))%")
                    .font(.subheadline)
                    .foregroundColor(.cyan)
                    .fontWeight(.medium)
            }
            
            VStack(spacing: 16) {
                // 自定义音量滑块
                VStack {
                    Slider(value: $volume, in: 0...1) {
                        Text("音量")
                    } minimumValueLabel: {
                        Image(systemName: "speaker")
                            .foregroundColor(.gray)
                    } maximumValueLabel: {
                        Image(systemName: "speaker.wave.3")
                            .foregroundColor(.cyan)
                    }
                    .accentColor(.cyan)
                }
                

            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    

    
    // MARK: - 操作按钮部分
    private var actionButtonsSection: some View {
        HStack(spacing: 16) {
            // 取消按钮
            Button(action: {
                dismiss()
            }) {
                Text("取消")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    )
            }
            
            // 保存按钮
            Button(action: {
                saveAlarm()
            }) {
                Text("保存")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.cyan)
                    )
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - 重复模式按钮
    private func repeatModeButton(_ mode: RepeatMode) -> some View {
        Button(action: {
            selectedRepeatMode = mode
            // 触觉反馈
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }) {
            VStack(spacing: 8) {
                Text(mode.shortDescription)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(mode.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                selectedRepeatMode.description == mode.description ? Color.cyan : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .foregroundColor(.white)
    }
    
    // MARK: - 私有方法
    
    private func setupInitialValues() {
        if let existingAlarm = alarm {
            // 编辑模式：使用现有闹钟数据
            let calendar = Calendar.current
            var components = calendar.dateComponents([.hour, .minute], from: Date())
            components.hour = existingAlarm.hour
            components.minute = existingAlarm.minute
            selectedTime = calendar.date(from: components) ?? Date()
            
            selectedRepeatMode = existingAlarm.repeatMode
            volume = existingAlarm.volume
            
            if case .custom(let weekdays) = existingAlarm.repeatMode {
                customWeekdays = weekdays
            }
        } else {
            // 新建模式：使用默认值
            let calendar = Calendar.current
            var components = calendar.dateComponents([.hour, .minute], from: Date())
            components.hour = 7
            components.minute = 0
            selectedTime = calendar.date(from: components) ?? Date()
        }
    }
    
    private func saveAlarm() {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: selectedTime)
        
        let finalRepeatMode: RepeatMode
        if case .custom = selectedRepeatMode {
            finalRepeatMode = .custom(customWeekdays)
        } else {
            finalRepeatMode = selectedRepeatMode
        }
        
        if let existingAlarm = alarm {
            // 更新现有闹钟
            var updatedAlarm = existingAlarm
            updatedAlarm.hour = components.hour ?? 7
            updatedAlarm.minute = components.minute ?? 0
            updatedAlarm.repeatMode = finalRepeatMode
            updatedAlarm.volume = volume
            updatedAlarm.isEnabled = true  // 保存后自动启用闹钟
            
            alarmStore.updateAlarm(updatedAlarm)
        } else {
            // 创建新闹钟
            let newAlarm = Alarm(
                hour: components.hour ?? 7,
                minute: components.minute ?? 0,
                repeatMode: finalRepeatMode,
                isEnabled: true,
                volume: volume
            )
            
            alarmStore.addAlarm(newAlarm)
        }
        
        // 触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        dismiss()
    }
    

}

// MARK: - 自定义重复选择视图
struct CustomRepeatView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedWeekdays: Set<Int>
    
    private let weekdays = [
        (1, "周日"), (2, "周一"), (3, "周二"), (4, "周三"),
        (5, "周四"), (6, "周五"), (7, "周六")
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景渐变
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.05, green: 0.1, blue: 0.2),
                        Color(red: 0.1, green: 0.15, blue: 0.25)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("选择重复的日期")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.top)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        ForEach(weekdays, id: \.0) { weekday in
                            weekdayButton(weekday.0, weekday.1)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationTitle("自定义重复")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundColor(.cyan)
                    .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func weekdayButton(_ weekday: Int, _ name: String) -> some View {
        Button(action: {
            if selectedWeekdays.contains(weekday) {
                selectedWeekdays.remove(weekday)
            } else {
                selectedWeekdays.insert(weekday)
            }
            
            // 触觉反馈
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }) {
            Text(name)
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(selectedWeekdays.contains(weekday) ? .black : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(selectedWeekdays.contains(weekday) ? Color.cyan : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.cyan, lineWidth: 2)
                        )
                )
        }
    }
}

#Preview {
    AlarmSettingView(alarm: .constant(nil), isPresented: .constant(true))
        .environmentObject(AlarmStore())
}