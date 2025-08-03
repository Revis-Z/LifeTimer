import SwiftUI
import UIKit
import AVFoundation
import AVKit
import AudioToolbox
import Combine

struct AlarmRingingView: View {
    @EnvironmentObject var alarmStore: AlarmStore
    @Binding var isPresented: Bool
    let alarm: Alarm
    
    @State private var currentTime = Date()
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var playbackProgress: Double = 0.0
    @State private var audioDuration: Double = 0.0
    @State private var timer: Timer?
    @State private var progressTimer: Timer?
    @State private var systemSoundTimer: Timer?
    @State private var isViewLoaded = false
    @State private var showDebugInfo = false
    @State private var audioDelegate: AudioPlayerDelegate?
    @State private var videoPlayer: AVQueuePlayer?
    @State private var playerLooper: AVPlayerLooper?
    
    // 励志语音内容数组
    let motivationalAudios = [
        ("早安激励", "每一个清晨都是新的开始，今天的你比昨天更强大！"),
        ("成功启程", "成功属于那些敢于追梦的人，今天就是你追梦的日子！"),
        ("积极能量", "用积极的心态迎接新的一天，你的笑容就是最好的阳光！"),
        ("目标达成", "每一步都在接近你的目标，坚持下去，胜利就在前方！"),
        ("自信满满", "相信自己的能力，你拥有改变世界的力量！"),
        ("勇敢前行", "勇敢面对挑战，每一次困难都是成长的机会！"),
        ("梦想实现", "梦想不会逃跑，逃跑的只有不敢追梦的人！"),
        ("正能量", "今天是美好的一天，让我们用正能量填满每一刻！"),
        ("坚持不懈", "坚持是成功的密码，今天继续为梦想努力！"),
        ("美好开始", "新的一天，新的机会，让我们创造属于自己的精彩！")
    ]
    
    // MARK: - 计算属性
    
    var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        return formatter
    }
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.locale = Locale.current
        return formatter
    }
    
    var currentAudio: (String, String) {
        let index = Int(currentTime.timeIntervalSince1970) % motivationalAudios.count
        return motivationalAudios[index]
    }
    
    // MARK: - 格式化方法
    
    func formatTimeForDisplay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }
    
    func formatDateForDisplay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 视频背景
                if let player = videoPlayer {
                    VideoPlayer(player: player)
                        .ignoresSafeArea()
                        .onAppear {
                            player.play()
                        }
                } else {
                    // 备用背景 - 自然风景风格
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.4, green: 0.5, blue: 0.6),
                            Color(red: 0.3, green: 0.4, blue: 0.5),
                            Color(red: 0.2, green: 0.3, blue: 0.4)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                }
                
                // 主要内容区域
                VStack(spacing: 0) {
                    // 顶部状态栏区域
                    HStack {
                        Spacer()
                        
                        // 调试按钮
                        Button(action: {
                            showDebugInfo.toggle()
                        }) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, geometry.safeAreaInsets.top + 8)
                    
                    Spacer()
                    
                    // 中心时间显示区域
                    VStack(spacing: 16) {
                        // 主要时间显示 - 参考截图的超大字体
                        Text(formatTimeForDisplay(currentTime))
                            .font(.system(size: min(geometry.size.width * 0.25, 120), weight: .ultraLight, design: .default))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                            .tracking(2) // 字符间距
                        
                        // 日期信息
                         Text(formatDateForDisplay(currentTime))
                             .font(.system(size: 18, weight: .medium))
                             .foregroundColor(.white.opacity(0.9))
                             .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        
                        // 励志文字
                        Text(currentAudio.1)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding(.top, 20)
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    
                    Spacer()
                    
                    // 底部控制栏 - 集成所有控制功能
                     VStack(spacing: 16) {
                         // 媒体播放控制栏
                         HStack(spacing: 0) {
                             // 媒体控制按钮组
                             HStack(spacing: 24) {
                                 // 上一首按钮
                                 Button(action: {
                                     let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                     impactFeedback.impactOccurred()
                                 }) {
                                     Image(systemName: "backward.fill")
                                         .font(.system(size: 20, weight: .medium))
                                         .foregroundColor(.white)
                                 }
                                 
                                 // 播放/暂停按钮
                                 Button(action: togglePlayback) {
                                     Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                         .font(.system(size: 24, weight: .medium))
                                         .foregroundColor(.white)
                                 }
                                 
                                 // 下一首按钮
                                 Button(action: {
                                     let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                     impactFeedback.impactOccurred()
                                 }) {
                                     Image(systemName: "forward.fill")
                                         .font(.system(size: 20, weight: .medium))
                                         .foregroundColor(.white)
                                 }
                             }
                             
                             Spacer()
                         }
                         .padding(.horizontal, 32)
                         .padding(.vertical, 16)
                         .background(
                             RoundedRectangle(cornerRadius: 24)
                                 .fill(.ultraThinMaterial.opacity(0.8))
                                 .background(
                                     RoundedRectangle(cornerRadius: 24)
                                         .fill(Color.black.opacity(0.3))
                                 )
                         )
                         
                         // 闹钟操作按钮栏
                         HStack(spacing: 16) {
                             // 稍后提醒按钮
                             Button(action: snoozeAlarm) {
                                 Text("稍后提醒")
                                     .font(.system(size: 16, weight: .medium))
                                     .foregroundColor(.white)
                                     .frame(maxWidth: .infinity)
                                     .frame(height: 48)
                                     .background(
                                         RoundedRectangle(cornerRadius: 24)
                                             .fill(Color.gray.opacity(0.6))
                                     )
                             }
                             
                             // 关闭闹钟按钮
                             Button(action: dismissAlarm) {
                                 Text("关闭闹钟")
                                     .font(.system(size: 16, weight: .medium))
                                     .foregroundColor(.white)
                                     .frame(maxWidth: .infinity)
                                     .frame(height: 48)
                                     .background(
                                         RoundedRectangle(cornerRadius: 24)
                                             .fill(Color.red.opacity(0.7))
                                     )
                             }
                         }
                         .padding(.horizontal, 32)
                     }
                     .padding(.horizontal, 20)
                     .padding(.bottom, geometry.safeAreaInsets.bottom + 20)
                }
                
                // 调试信息（可选显示）
                if showDebugInfo {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("🔧 调试信息")
                            .font(.headline)
                            .foregroundColor(.yellow)
                        
                        Text("音频播放器: \(audioPlayer != nil ? "已创建" : "未创建")")
                        Text("播放状态: \(isPlaying ? "播放中" : "已停止")")
                        Text("音频时长: \(String(format: "%.1f", audioDuration))秒")
                        Text("播放进度: \(String(format: "%.1f", playbackProgress))秒")
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                // 调试信息按钮（右上角）
                VStack {
                    HStack {
                        Spacer()
                        
                        // 调试按钮
                        Button(action: {
                            showDebugInfo.toggle()
                        }) {
                            Image(systemName: "info.circle")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.6))
                                .shadow(color: .black.opacity(0.5), radius: 2)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, geometry.safeAreaInsets.top + 8)
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            print("🎵 AlarmRingingView 出现")
            print("📱 当前时间: \(Date())")
            print("⏰ 闹钟信息: \(alarm.timeString)")
            
            if !isViewLoaded {
                setupVideo()
                setupAudio()
                startTimeTimer()
                isViewLoaded = true
                print("✅ 闹钟响起页面初始化完成")
            }
            // 防止屏幕自动锁定
            UIApplication.shared.isIdleTimerDisabled = true
            
            // 强制触发视图更新
            DispatchQueue.main.async {
                currentTime = Date()
            }
        }
        .onDisappear {
            print("🎵 AlarmRingingView 消失")
            cleanup()
            // 恢复屏幕自动锁定
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - 计算属性
    
    // MARK: - 视频相关方法
    
    func setupVideo() {
        print("🎬 设置视频播放器...")
        
        // 尝试加载视频文件
        guard let videoURL = Bundle.main.url(forResource: "sample", withExtension: "mp4") else {
            print("❌ 找不到视频文件 sample.mp4")
            return
        }
        
        print("✅ 找到视频文件: \(videoURL.path)")
        
        // 创建视频播放器
        let playerItem = AVPlayerItem(url: videoURL)
        videoPlayer = AVQueuePlayer(playerItem: playerItem)
        
        // 设置循环播放
        if let player = videoPlayer {
            playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
            
            // 静音视频播放（因为我们有单独的音频）
            player.isMuted = true
            
            print("✅ 视频播放器设置成功，已设置为循环播放")
        }
    }
    
    // MARK: - 音频相关方法
    
    func setupAudio() {
        print("🔧 设置音频...")
        print("🔊 目标音量: \(alarm.volume)")
        
        // 调试音频文件
        debugAudioFiles()
        
        // 设置音频会话
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.duckOthers, .allowBluetooth])
            try audioSession.setActive(true)
            print("✅ 音频会话设置成功")
            print("📊 当前音频会话类别: \(audioSession.category)")
        } catch {
            print("❌ 音频会话设置失败: \(error)")
        }
        
        // 尝试加载音频文件
        guard let audioURL = Bundle.main.url(forResource: "sample", withExtension: "flac") else {
            print("❌ 找不到音频文件 sample.flac")
            print("🔄 尝试使用系统默认声音")
            setupSystemSound()
            return
        }
        
        print("✅ 找到音频文件: \(audioURL.path)")
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            
            // 创建音频代理并设置回调
            audioDelegate = AudioPlayerDelegate()
            audioDelegate?.onFinishPlaying = { success in
                DispatchQueue.main.async {
                    self.isPlaying = false
                    self.stopProgressTimer()
                }
            }
            audioDelegate?.onDecodeError = { error in
                DispatchQueue.main.async {
                    self.isPlaying = false
                    self.stopProgressTimer()
                    self.setupSystemSound()
                }
            }
            audioDelegate?.onBeginInterruption = {
                DispatchQueue.main.async {
                    self.isPlaying = false
                    self.stopProgressTimer()
                }
            }
            audioDelegate?.onEndInterruption = { flags in
                DispatchQueue.main.async {
                    if flags == AVAudioSession.InterruptionOptions.shouldResume.rawValue {
                        self.audioPlayer?.play()
                        self.isPlaying = true
                        self.startProgressTimer()
                    }
                }
            }
            
            audioPlayer?.delegate = audioDelegate
            audioPlayer?.numberOfLoops = -1 // 无限循环
            audioPlayer?.volume = Float(alarm.volume)
            audioDuration = audioPlayer?.duration ?? 30.0
            
            // 预加载音频
            audioPlayer?.prepareToPlay()
            
            print("✅ 音频播放器设置成功")
            print("🎵 音频时长: \(audioDuration)秒")
            print("🔊 播放器音量: \(audioPlayer?.volume ?? 0)")
            
            // 立即开始播放
            playAudio()
        } catch {
            print("❌ 音频播放器创建失败: \(error)")
            print("🔄 回退到系统声音")
            setupSystemSound()
        }
    }
    
    func playAudio() {
        print("▶️ 开始播放音频...")
        
        if let player = audioPlayer {
            print("🎵 使用AVAudioPlayer播放")
            print("🔊 播放器音量: \(player.volume)")
            print("📊 音频时长: \(player.duration)秒")
            
            let success = player.play()
            print("🎯 播放结果: \(success ? "成功" : "失败")")
            
            if success {
                isPlaying = true
                startProgressTimer()
                print("✅ 音频播放已启动")
            } else {
                print("❌ 音频播放启动失败")
                setupSystemSound()
            }
        } else {
            print("⚠️ 没有音频播放器，使用模拟播放")
            isPlaying = true
            startProgressTimer()
        }
        
        // 触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        print("📳 触觉反馈已触发")
    }
    
    func pauseAudio() {
        if let player = audioPlayer {
            player.pause()
        }
        isPlaying = false
        stopProgressTimer()
        
        // 触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    func togglePlayback() {
        if isPlaying {
            pauseAudio()
        } else {
            playAudio()
        }
    }
    
    func replayAudio() {
        if let player = audioPlayer {
            player.currentTime = 0
            player.play()
            isPlaying = true
            playbackProgress = 0
            startProgressTimer()
        } else {
            // 模拟重播
            playbackProgress = 0
            isPlaying = true
            startProgressTimer()
        }
        
        // 触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
    
    // MARK: - 定时器相关方法
    
    func startTimeTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            currentTime = Date()
        }
    }
    
    func startProgressTimer() {
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if let player = audioPlayer {
                playbackProgress = player.currentTime
                if !player.isPlaying && playbackProgress >= audioDuration {
                    isPlaying = false
                    stopProgressTimer()
                }
            } else {
                // 模拟播放进度
                playbackProgress += 0.1
                if playbackProgress >= audioDuration {
                    isPlaying = false
                    stopProgressTimer()
                }
            }
        }
    }
    
    func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    // MARK: - 操作方法
    
    func dismissAlarm() {
        print("⏹️ 关闭闹钟")
        
        // 停止所有音频播放
        audioPlayer?.stop()
        systemSoundTimer?.invalidate()
        systemSoundTimer = nil
        isPlaying = false
        
        // 发送闹钟停止通知，让MainView处理一次性闹钟的禁用
        NotificationCenter.default.post(name: .alarmStopped, object: alarm.id.uuidString)
        print("📤 已发送闹钟停止通知")
        
        // 触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        // 清理资源
        cleanup()
        
        // 关闭页面
        isPresented = false
        print("✅ 闹钟页面已关闭")
    }
    
    func snoozeAlarm() {
        print("😴 稍后提醒")
        
        // 停止所有音频播放
        audioPlayer?.stop()
        systemSoundTimer?.invalidate()
        systemSoundTimer = nil
        isPlaying = false
        
        // 发送稍后提醒通知，让MainView处理
        NotificationCenter.default.post(name: .alarmSnoozed, object: alarm.id.uuidString)
        print("📤 已发送稍后提醒通知")
        
        // 触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // 清理资源
        cleanup()
        
        // 关闭页面
        isPresented = false
        print("✅ 闹钟页面已关闭")
    }
    
    func cleanup() {
        timer?.invalidate()
        timer = nil
        systemSoundTimer?.invalidate()
        systemSoundTimer = nil
        stopProgressTimer()
        audioPlayer?.stop()
        audioPlayer?.delegate = nil
        audioPlayer = nil
        audioDelegate = nil
        
        // 清理视频播放器
        videoPlayer?.pause()
        playerLooper?.disableLooping()
        playerLooper = nil
        videoPlayer = nil
        
        print("🧹 清理完成")
    }
    
    // MARK: - 系统声音备选方案
    
    func setupSystemSound() {
        print("🔔 设置系统声音备选方案")
        
        // 立即播放系统声音和振动
        AudioServicesPlaySystemSound(1005) // 系统闹钟声音
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate) // 振动
        
        // 设置定时器重复播放系统声音
        systemSoundTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            print("🔔 播放系统声音")
            AudioServicesPlaySystemSound(1005)
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
        
        isPlaying = true
        audioDuration = 30.0
        startProgressTimer()
        
        print("✅ 系统声音备选方案已启动")
    }
    
    // MARK: - 辅助方法
    
    func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // 调试方法：检查音频文件
    func debugAudioFiles() {
        print("🔍 调试音频文件...")
        
        // 检查Bundle中的所有文件
        let bundle = Bundle.main
        print("📁 Bundle路径: \(bundle.bundlePath)")
        
        // 尝试不同的方式查找音频文件
        let possibleNames = ["sample", "sample.flac"]
        let possibleExtensions = ["flac", "mp3", "wav", "m4a", ""]
        
        for name in possibleNames {
            for ext in possibleExtensions {
                if let url = bundle.url(forResource: name, withExtension: ext.isEmpty ? nil : ext) {
                    print("✅ 找到文件: \(name).\(ext) -> \(url.path)")
                    
                    // 检查文件是否存在
                    if FileManager.default.fileExists(atPath: url.path) {
                        print("✅ 文件确实存在")
                        
                        // 检查文件大小
                        if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                           let fileSize = attributes[.size] as? Int64 {
                            print("📊 文件大小: \(fileSize) 字节")
                        }
                    } else {
                        print("❌ 文件路径存在但文件不存在")
                    }
                }
            }
        }
        
        // 列出Bundle根目录的所有文件
        if let contents = try? FileManager.default.contentsOfDirectory(atPath: bundle.bundlePath) {
            print("📂 Bundle根目录内容:")
            for file in contents.sorted() {
                if file.lowercased().contains("sample") || 
                   file.hasSuffix(".flac") ||
                   file.hasSuffix(".mp3") || 
                   file.hasSuffix(".wav") || 
                   file.hasSuffix(".m4a") {
                    print("  🎵 \(file)")
                }
            }
        }
    }
}

// MARK: - 音频播放代理类

class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    var onFinishPlaying: ((Bool) -> Void)?
    var onDecodeError: ((Error?) -> Void)?
    var onBeginInterruption: (() -> Void)?
    var onEndInterruption: ((Int) -> Void)?
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("🎵 音频播放完成: \(flag ? "成功" : "失败")")
        onFinishPlaying?(flag)
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("❌ 音频解码错误: \(error?.localizedDescription ?? "未知错误")")
        onDecodeError?(error)
    }
    
    func audioPlayerBeginInterruption(_ player: AVAudioPlayer) {
        print("⏸️ 音频播放被中断")
        onBeginInterruption?()
    }
    
    func audioPlayerEndInterruption(_ player: AVAudioPlayer, withOptions flags: Int) {
        print("▶️ 音频中断结束，恢复播放")
        onEndInterruption?(flags)
    }
}

// MARK: - 预览

#Preview {
    AlarmRingingView(
        isPresented: .constant(true),
        alarm: Alarm(
            hour: 7,
            minute: 30,
            repeatMode: .once,
            isEnabled: true,
            volume: 0.7
        )
    )
    .environmentObject(AlarmStore())
}