import SwiftUI

struct LaunchScreenView: View {
    @State private var isActive = false
    
    var body: some View {
        ZStack {
            // 背景色
            Color(red: 0.15, green: 0.15, blue: 0.2)
                .ignoresSafeArea()
            
            // 应用Logo和名称
            VStack {
                Image(systemName: "alarm")
                    .font(.system(size: 72))
                    .foregroundColor(.white)
                    .padding(.bottom, 20)
                
                Text("LifeTimer")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .onAppear {
            // 3秒后自动跳转
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    isActive = true
                }
            }
        }
        .fullScreenCover(isPresented: $isActive) {
            MainView()
        }
    }
}

#Preview {
    LaunchScreenView()
}