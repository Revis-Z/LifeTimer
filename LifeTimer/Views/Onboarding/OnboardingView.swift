import SwiftUI
import AVKit

struct OnboardingPage: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let videoName: String
}

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    @State private var currentPage = 0
    
    let pages = [
        OnboardingPage(
            title: "Wake Up Inspired",
            subtitle: "Start your day with motivation and energy, not just a beep.",
            videoName: "sample01"
        ),
        OnboardingPage(
            title: "Immersive Experience",
            subtitle: "Random motivational quotes and serene videos to lift your mood.",
            videoName: "sample02"
        ),
        OnboardingPage(
            title: "Never Miss a Moment",
            subtitle: "Allow notifications to ensure your alarm wakes you up on time.",
            videoName: "sample03"
        ),
        OnboardingPage(
            title: "You Are Ready",
            subtitle: "Let's set your first motivational alarm.",
            videoName: "sample04"
        )
    ]
    
    var body: some View {
        ZStack {
            // 背景视频层
            OnboardingVideoPlayer(videoName: pages[currentPage].videoName)
                .ignoresSafeArea()
            
            // 渐变遮罩，确保文字可读性
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.3),
                    Color.black.opacity(0.6)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // 内容层
            VStack {
                Spacer()
                
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        VStack(spacing: 16) {
                            Spacer()
                            
                            Text(pages[index].title)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text(pages[index].subtitle)
                                .font(.system(size: 18))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                                .padding(.bottom, 40)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 300)
                
                // 底部按钮区域
                VStack(spacing: 20) {
                    if currentPage == 2 {
                        Button(action: {
                            requestNotificationPermission()
                            withAnimation {
                                currentPage += 1
                            }
                        }) {
                            Text("Enable Notifications")
                                .font(.headline)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 32)
                    } else if currentPage == pages.count - 1 {
                        Button(action: {
                            withAnimation {
                                hasSeenOnboarding = true
                            }
                        }) {
                            Text("Get Started")
                                .font(.headline)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 32)
                        .transition(.opacity)
                    } else {
                        Button(action: {
                            withAnimation {
                                currentPage += 1
                            }
                        }) {
                            Text("Next")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 32)
                    }
                    
                    // 跳过按钮
                    if currentPage < pages.count - 1 {
                        Button(action: {
                            withAnimation {
                                hasSeenOnboarding = true
                            }
                        }) {
                            Text("Skip")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.bottom, 8)
                    } else {
                        // 占位符以保持布局稳定
                        Text("")
                            .font(.subheadline)
                            .padding(.bottom, 8)
                    }
                }
                .padding(.bottom, 30)
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted via onboarding")
            }
        }
    }
}

// 简化的循环静音视频播放器
struct OnboardingVideoPlayer: UIViewControllerRepresentable {
    let videoName: String
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill
        controller.view.backgroundColor = .clear
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // 如果视频已经加载且名称相同，不重新加载
        if let currentItem = uiViewController.player?.currentItem as? AVPlayerItem,
           let urlAsset = currentItem.asset as? AVURLAsset,
           urlAsset.url.lastPathComponent.contains(videoName) {
            return
        }
        
        guard let url = Bundle.main.url(forResource: videoName, withExtension: "mp4") else { return }
        
        let player = AVPlayer(url: url)
        player.isMuted = true
        player.actionAtItemEnd = .none
        
        // 监听播放结束通知以实现循环
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            player.play()
        }
        
        uiViewController.player = player
        player.play()
    }
}

#Preview {
    OnboardingView()
}
