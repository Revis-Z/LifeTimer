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
    
    // 当前显示的励志句子（随机选择后固定显示）
    @State private var currentMotivationalText: String = ""
    
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
                        Text(currentMotivationalText)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding(.top, 20)
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    
                    Spacer()
                    
                    // 底部控制栏 - 集成所有控制功能
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
                     .padding(.horizontal, 20)
                     .padding(.bottom, geometry.safeAreaInsets.bottom + 20)
                }
                

            }
        }
        .onAppear {
            if !isViewLoaded {
                // 随机选择一条励志句子
                if let randomAudio = motivationalAudios.randomElement() {
                    currentMotivationalText = randomAudio.1
                }
                
                setupVideo()
                setupAudio()
                startTimeTimer()
                isViewLoaded = true
            }
            // 防止屏幕自动锁定
            UIApplication.shared.isIdleTimerDisabled = true
            
            // 强制触发视图更新
            DispatchQueue.main.async {
                currentTime = Date()
            }
        }
        .onDisappear {
            cleanup()
            // 恢复屏幕自动锁定
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - 计算属性
    
    // MARK: - 视频相关方法
    
    func setupVideo() {
        // 获取Video文件夹中的所有MP4文件
        let videoFileNames = ["sample01", "sample02", "sample03", "sample04"]
        
        // 随机选择一个视频文件
        let randomVideoName = videoFileNames.randomElement() ?? "sample01"
        
        // 尝试加载随机选择的视频文件
        guard let videoURL = Bundle.main.url(forResource: randomVideoName, withExtension: "mp4") else {
            return
        }
        
        // 创建视频播放器
        let playerItem = AVPlayerItem(url: videoURL)
        videoPlayer = AVQueuePlayer(playerItem: playerItem)
        
        // 设置循环播放
        if let player = videoPlayer {
            playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
            
            // 静音视频播放（因为我们有单独的音频）
            player.isMuted = true
            
            // 自动开始播放视频
            player.play()
        }
    }
    
    // MARK: - 音频相关方法
    
    func setupAudio() {
        // 设置音频会话
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.duckOthers, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            // 音频会话设置失败，继续使用系统声音
        }
        
        // 获取Audio文件夹中的所有FLAC文件
        let audioFileNames = ["sample01", "sample02", "sample03"]
        
        // 随机选择一个音频文件
        let randomAudioName = audioFileNames.randomElement() ?? "sample01"
        
        // 尝试加载随机选择的音频文件
        guard let audioURL = Bundle.main.url(forResource: randomAudioName, withExtension: "flac") else {
            setupSystemSound()
            return
        }
        
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
            
            // 立即开始播放
            playAudio()
        } catch {
            setupSystemSound()
        }
    }
    
    func playAudio() {
        audioPlayer?.play()
        isPlaying = true
        startProgressTimer()
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
        // 停止所有音频播放
        audioPlayer?.stop()
        systemSoundTimer?.invalidate()
        systemSoundTimer = nil
        isPlaying = false
        
        // 发送闹钟停止通知，让MainView处理一次性闹钟的禁用
        NotificationCenter.default.post(name: .alarmStopped, object: alarm.id.uuidString)
        
        // 触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        // 清理资源
        cleanup()
        
        // 关闭页面
        isPresented = false
    }
    
    func snoozeAlarm() {
        // 停止所有音频播放
        audioPlayer?.stop()
        systemSoundTimer?.invalidate()
        systemSoundTimer = nil
        isPlaying = false
        
        // 发送稍后提醒通知，让MainView处理
        NotificationCenter.default.post(name: .alarmSnoozed, object: alarm.id.uuidString)
        
        // 触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // 清理资源
        cleanup()
        
        // 关闭页面
        isPresented = false
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
    }
    
    // MARK: - 系统声音备选方案
    
    func setupSystemSound() {
        // 立即播放系统声音和振动
        AudioServicesPlaySystemSound(1005) // 系统闹钟声音
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate) // 振动
        
        // 设置定时器重复播放系统声音
        systemSoundTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            AudioServicesPlaySystemSound(1005)
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
        
        isPlaying = true
        audioDuration = 30.0
        startProgressTimer()
    }
    
    // MARK: - 辅助方法
    
    func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    

}

// MARK: - 音频播放代理类

class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    var onFinishPlaying: ((Bool) -> Void)?
    var onDecodeError: ((Error?) -> Void)?
    var onBeginInterruption: (() -> Void)?
    var onEndInterruption: ((Int) -> Void)?
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinishPlaying?(flag)
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        onDecodeError?(error)
    }
    
    func audioPlayerBeginInterruption(_ player: AVAudioPlayer) {
        onBeginInterruption?()
    }
    
    func audioPlayerEndInterruption(_ player: AVAudioPlayer, withOptions flags: Int) {
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