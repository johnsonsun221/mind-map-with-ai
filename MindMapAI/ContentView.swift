import SwiftUI

/// 主内容视图
struct ContentView: View {
    var body: some View {
        ZStack {
            // 思维导图画布（背景层）
            MindMapCanvas()

            // 浮动 AI 聊天窗口（前景层）
            FloatingChatWindow()
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
