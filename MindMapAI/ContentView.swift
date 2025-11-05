import SwiftUI

/// 主内容视图
struct ContentView: View {
    @StateObject private var viewModel = MindMapViewModel()

    var body: some View {
        ZStack {
            // 思维导图画布（背景层）
            MindMapCanvas(viewModel: viewModel)

            // 浮动 AI 聊天窗口（前景层）
            FloatingChatWindow(viewModel: viewModel)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
