import SwiftUI
import AVFoundation

// MARK: - 语音内容数据模型
struct VoiceContent: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let content: String
    let category: VoiceCategory
    let duration: TimeInterval
    var playCount: Int = 0
    var isFavorite: Bool = false
    
    // 模拟音频文件路径
    var audioFileName: String {
        return title.replacingOccurrences(of: " ", with: "_").lowercased()
    }
}

// MARK: - 语音分类枚举
enum VoiceCategory: String, CaseIterable {
    case morning = "晨起励志"
    case work = "工作激励"
    case life = "生活感悟"
    case motivation = "自我激励"
    case relaxation = "放松冥想"
    
    var icon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .work: return "briefcase.fill"
        case .life: return "heart.fill"
        case .motivation: return "flame.fill"
        case .relaxation: return "leaf.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .morning: return .orange
        case .work: return .blue
        case .life: return .pink
        case .motivation: return .red
        case .relaxation: return .green
        }
    }
}

// MARK: - 语音内容管理页面
struct VoiceContentView: View {
    @EnvironmentObject var alarmStore: AlarmStore
    @Environment(\.dismiss) private var dismiss
    
    // 状态管理
    @State private var searchText = ""
    @State private var selectedCategory: VoiceCategory? = nil
    @State private var expandedCategories: Set<VoiceCategory> = Set(VoiceCategory.allCases)
    @State private var currentlyPlaying: VoiceContent? = nil
    @State private var audioPlayer: AVAudioPlayer? = nil
    @State private var isPlaying = false
    @State private var playbackProgress: Double = 0.0
    @State private var playbackTimer: Timer? = nil
    @State private var favoriteContents: Set<UUID> = []
    @State private var showingPlaybackControls = false
    
    // 示例语音内容数据
    @State private var voiceContents: [VoiceContent] = [
        // 晨起励志
        VoiceContent(title: "新的一天开始", content: "每一个清晨都是新的开始，带着希望迎接挑战", category: .morning, duration: 45),
        VoiceContent(title: "晨光中的力量", content: "阳光洒在身上，内心充满无限可能", category: .morning, duration: 38),
        VoiceContent(title: "早起的鸟儿", content: "早起不仅是习惯，更是对生活的热爱", category: .morning, duration: 52),
        
        // 工作激励
        VoiceContent(title: "专注的力量", content: "专注是成功的关键，让我们全身心投入", category: .work, duration: 41),
        VoiceContent(title: "突破自我", content: "每一次挑战都是成长的机会", category: .work, duration: 47),
        VoiceContent(title: "团队协作", content: "一个人可以走得很快，一群人可以走得更远", category: .work, duration: 55),
        
        // 生活感悟
        VoiceContent(title: "感恩的心", content: "感恩生活中的每一个美好瞬间", category: .life, duration: 43),
        VoiceContent(title: "内心的平静", content: "在忙碌中寻找内心的宁静", category: .life, duration: 39),
        VoiceContent(title: "简单的幸福", content: "幸福其实很简单，就在身边的小事中", category: .life, duration: 48),
        
        // 自我激励
        VoiceContent(title: "永不放弃", content: "坚持到底，成功就在不远处", category: .motivation, duration: 44),
        VoiceContent(title: "相信自己", content: "你比想象中更强大，相信自己的力量", category: .motivation, duration: 42),
        VoiceContent(title: "勇敢前行", content: "勇气不是没有恐惧，而是带着恐惧继续前行", category: .motivation, duration: 50),
        
        // 放松冥想
        VoiceContent(title: "深呼吸", content: "深深吸气，慢慢呼出，让身心得到放松", category: .relaxation, duration: 60),
        VoiceContent(title: "冥想时光", content: "闭上眼睛，感受内心的宁静", category: .relaxation, duration: 90),
        VoiceContent(title: "释放压力", content: "放下今天的疲惫，拥抱内心的平和", category: .relaxation, duration: 75)
    ]
    
    // 过滤后的语音内容
    private var filteredContents: [VoiceContent] {
        let filtered = voiceContents.filter { content in
            let matchesSearch = searchText.isEmpty || 
                content.title.localizedCaseInsensitiveContains(searchText) ||
                content.content.localizedCaseInsensitiveContains(searchText)
            
            let matchesCategory = selectedCategory == nil || content.category == selectedCategory
            
            return matchesSearch && matchesCategory
        }
        
        return filtered.sorted { $0.category.rawValue < $1.category.rawValue }
    }
    
    // 按分类分组的内容
    private var groupedContents: [VoiceCategory: [VoiceContent]] {
        Dictionary(grouping: filteredContents) { $0.category }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景渐变
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        Color.blue.opacity(0.3),
                        Color.cyan.opacity(0.2)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 顶部按钮栏
                    topButtonBar
                    
                    // 搜索栏
                    searchBar
                    
                    // 分类筛选器
                    categoryFilter
                    
                    // 语音内容列表
                    contentList
                }
            }
            .navigationTitle("语音内容")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingPlaybackControls) {
                if let content = currentlyPlaying {
                    PlaybackControlView(
                        content: content,
                        isPlaying: $isPlaying,
                        progress: $playbackProgress,
                        onPlayPause: togglePlayback,
                        onStop: stopPlayback,
                        onSeek: seekToPosition
                    )
                }
            }
        }
        .onAppear {
            loadFavorites()
        }
        .onDisappear {
            stopPlayback()
        }
    }
    
    // MARK: - 顶部按钮栏
    private var topButtonBar: some View {
        HStack {
            // 完成按钮
            Button(action: {
                dismiss()
            }) {
                Text("完成")
                    .font(.headline)
                    .foregroundColor(.cyan)
            }
            
            Spacer()
            
            // 刷新按钮
            Button(action: {
                refreshContent()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                    Text("刷新内容")
                }
                .font(.headline)
                .foregroundColor(.cyan)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 5)
    }
    
    // MARK: - 搜索栏
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("搜索语音内容...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(.white)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    // MARK: - 分类筛选器
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // 全部分类按钮
                CategoryFilterButton(
                    title: "全部",
                    icon: "list.bullet",
                    color: .cyan,
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }
                
                // 各分类按钮
                ForEach(VoiceCategory.allCases, id: \.self) { category in
                    CategoryFilterButton(
                        title: category.rawValue,
                        icon: category.icon,
                        color: category.color,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = selectedCategory == category ? nil : category
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 10)
    }
    
    // MARK: - 内容列表
    private var contentList: some View {
        List {
            ForEach(VoiceCategory.allCases, id: \.self) { category in
                if let contents = groupedContents[category], !contents.isEmpty {
                    Section {
                        if expandedCategories.contains(category) {
                            ForEach(contents) { content in
                                VoiceContentRow(
                                    content: content,
                                    isPlaying: currentlyPlaying?.id == content.id && isPlaying,
                                    isFavorite: favoriteContents.contains(content.id),
                                    onPlay: { playContent(content) },
                                    onFavorite: { toggleFavorite(content) }
                                )
                            }
                        }
                    } header: {
                        CategoryHeader(
                            category: category,
                            isExpanded: expandedCategories.contains(category),
                            contentCount: contents.count
                        ) {
                            toggleCategoryExpansion(category)
                        }
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
        .background(Color.clear)
        .refreshable {
            await refreshContentAsync()
        }
    }
    
    // MARK: - 播放控制方法
    private func playContent(_ content: VoiceContent) {
        // 如果正在播放相同内容，则暂停/继续
        if currentlyPlaying?.id == content.id {
            togglePlayback()
            return
        }
        
        // 停止当前播放
        stopPlayback()
        
        // 开始播放新内容
        currentlyPlaying = content
        
        // 这里应该加载实际的音频文件
        // 由于是演示，我们使用模拟播放
        simulateAudioPlayback(content)
        
        // 更新播放次数
        updatePlayCount(for: content)
        
        // 显示播放控制界面
        showingPlaybackControls = true
    }
    
    private func simulateAudioPlayback(_ content: VoiceContent) {
        isPlaying = true
        playbackProgress = 0.0
        
        // 模拟播放进度
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if isPlaying && playbackProgress < 1.0 {
                playbackProgress += 0.1 / content.duration
            } else if playbackProgress >= 1.0 {
                stopPlayback()
            }
        }
    }
    
    private func togglePlayback() {
        isPlaying.toggle()
    }
    
    private func stopPlayback() {
        isPlaying = false
        playbackTimer?.invalidate()
        playbackTimer = nil
        audioPlayer?.stop()
        audioPlayer = nil
        currentlyPlaying = nil
        playbackProgress = 0.0
        showingPlaybackControls = false
    }
    
    private func seekToPosition(_ position: Double) {
        playbackProgress = position
        // 在实际实现中，这里应该设置音频播放器的播放位置
    }
    
    // MARK: - 收藏功能
    private func toggleFavorite(_ content: VoiceContent) {
        if favoriteContents.contains(content.id) {
            favoriteContents.remove(content.id)
        } else {
            favoriteContents.insert(content.id)
        }
        saveFavorites()
        
        // 更新内容数组中的收藏状态
        if let index = voiceContents.firstIndex(where: { $0.id == content.id }) {
            voiceContents[index].isFavorite = favoriteContents.contains(content.id)
        }
    }
    
    private func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: "FavoriteVoiceContents"),
           let favorites = try? JSONDecoder().decode(Set<UUID>.self, from: data) {
            favoriteContents = favorites
            
            // 更新内容数组中的收藏状态
            for index in voiceContents.indices {
                voiceContents[index].isFavorite = favoriteContents.contains(voiceContents[index].id)
            }
        }
    }
    
    private func saveFavorites() {
        if let data = try? JSONEncoder().encode(favoriteContents) {
            UserDefaults.standard.set(data, forKey: "FavoriteVoiceContents")
        }
    }
    
    // MARK: - 其他功能
    private func updatePlayCount(for content: VoiceContent) {
        if let index = voiceContents.firstIndex(where: { $0.id == content.id }) {
            voiceContents[index].playCount += 1
        }
    }
    
    private func toggleCategoryExpansion(_ category: VoiceCategory) {
        if expandedCategories.contains(category) {
            expandedCategories.remove(category)
        } else {
            expandedCategories.insert(category)
        }
    }
    
    private func refreshContent() {
        // 模拟刷新延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // 在实际应用中，这里会重新加载数据
        }
    }
    
    private func refreshContentAsync() async {
        // 异步刷新内容
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒延迟
    }
}

// MARK: - 分类筛选按钮
struct CategoryFilterButton: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? color : Color.white.opacity(0.1))
            )
            .foregroundColor(isSelected ? .black : .white)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 分类标题
struct CategoryHeader: View {
    let category: VoiceCategory
    let isExpanded: Bool
    let contentCount: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: category.icon)
                    .foregroundColor(category.color)
                    .font(.title3)
                
                Text(category.rawValue)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("(\(contentCount))")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 语音内容行
struct VoiceContentRow: View {
    let content: VoiceContent
    let isPlaying: Bool
    let isFavorite: Bool
    let onPlay: () -> Void
    let onFavorite: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 播放按钮
            Button(action: onPlay) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(.cyan)
            }
            .buttonStyle(PlainButtonStyle())
            
            // 内容信息
            VStack(alignment: .leading, spacing: 4) {
                Text(content.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(content.content)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
                HStack {
                    Text(formatDuration(content.duration))
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    if content.playCount > 0 {
                        Text("• 播放 \(content.playCount) 次")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer()
            
            // 收藏按钮
            Button(action: onFavorite) {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.title3)
                    .foregroundColor(isFavorite ? .red : .gray)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isPlaying ? Color.cyan.opacity(0.1) : Color.clear)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(content.title), \(content.content), 时长 \(formatDuration(content.duration))")
        .accessibilityHint(isPlaying ? "正在播放，点击暂停" : "点击播放")
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - 播放控制视图
struct PlaybackControlView: View {
    let content: VoiceContent
    @Binding var isPlaying: Bool
    @Binding var progress: Double
    let onPlayPause: () -> Void
    let onStop: () -> Void
    let onSeek: (Double) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // 内容信息
                VStack(spacing: 12) {
                    Text(content.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(content.content)
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
                .padding(.horizontal, 20)
                
                // 播放进度
                VStack(spacing: 12) {
                    Slider(value: Binding(
                        get: { progress },
                        set: { onSeek($0) }
                    ), in: 0...1)
                    .accentColor(.cyan)
                    
                    HStack {
                        Text(formatTime(progress * content.duration))
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text(formatTime(content.duration))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 20)
                
                // 播放控制按钮
                HStack(spacing: 40) {
                    Button(action: onStop) {
                        Image(systemName: "stop.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    
                    Button(action: onPlayPause) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.cyan)
                    }
                    
                    Button(action: {
                        // 重播功能
                        onSeek(0)
                    }) {
                        Image(systemName: "backward.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
            }
            .padding(.top, 20)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        Color.blue.opacity(0.3)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("正在播放")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundColor(.cyan)
                }
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - 预览
#Preview {
    VoiceContentView()
        .environmentObject(AlarmStore())
}