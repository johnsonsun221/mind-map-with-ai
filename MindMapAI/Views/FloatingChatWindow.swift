import SwiftUI
import UniformTypeIdentifiers

/// 浮动的 AI 聊天窗口
struct FloatingChatWindow: View {
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isExpanded = false
    @State private var position: CGPoint = CGPoint(x: UIScreen.main.bounds.width - 60, y: UIScreen.main.bounds.height - 150)
    @State private var isDragging = false
    @State private var isProcessing = false

    // 拖放接收
    @State private var isDropTargeted = false

    var body: some View {
        ZStack {
            if isExpanded {
                // 展开状态：完整聊天界面
                expandedChatView
                    .transition(.scale.combined(with: .opacity))
            } else {
                // 收缩状态：浮动按钮
                collapsedButton
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isExpanded)
    }

    // MARK: - 收缩状态的浮动按钮
    private var collapsedButton: some View {
        Button(action: {
            isExpanded = true
        }) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)

                Image(systemName: "message.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)

                if messages.filter({ $0.role == .assistant }).count > 0 {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Text("\(messages.filter({ $0.role == .assistant }).count)")
                                .font(.caption2)
                                .foregroundColor(.white)
                        )
                        .offset(x: 20, y: -20)
                }
            }
        }
        .position(position)
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDragging = true
                    position = value.location
                }
                .onEnded { _ in
                    isDragging = false
                }
        )
    }

    // MARK: - 展开状态的聊天界面
    private var expandedChatView: some View {
        VStack(spacing: 0) {
            // 标题栏
            chatHeader

            // 消息列表
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            ChatBubble(message: message)
                                .id(message.id)
                        }

                        if isProcessing {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                Text("AI 思考中...")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding()
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _ in
                    if let lastMessage = messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }

            // 拖放区域提示
            if isDropTargeted {
                Text("松开以发送卡片内容到 AI")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.green.opacity(0.8))
                    .cornerRadius(8)
                    .padding()
            }

            // 输入框
            chatInputBar
        }
        .frame(width: 350, height: 500)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isDropTargeted ? Color.green : Color.clear, lineWidth: 3)
        )
        .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
        .onDrop(of: [UTType.data], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers: providers)
            return true
        }
    }

    // MARK: - 聊天标题栏
    private var chatHeader: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.purple)
                Text("AI 助手")
                    .font(.headline)
            }

            Spacer()

            Button(action: {
                isExpanded = false
            }) {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground).opacity(0.8))
    }

    // MARK: - 输入栏
    private var chatInputBar: some View {
        HStack(spacing: 12) {
            TextField("输入消息或拖入卡片...", text: $inputText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .submitLabel(.send)
                .onSubmit {
                    sendMessage()
                }

            Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 20))
                    .foregroundColor(inputText.isEmpty ? .gray : .blue)
            }
            .disabled(inputText.isEmpty)
        }
        .padding()
        .background(Color(UIColor.systemBackground).opacity(0.8))
    }

    // MARK: - 发送消息
    private func sendMessage() {
        guard !inputText.isEmpty else { return }

        let userMessage = ChatMessage(role: .user, content: inputText)
        messages.append(userMessage)

        let messageContent = inputText
        inputText = ""

        // 模拟 AI 响应
        Task {
            await generateAIResponse(for: messageContent)
        }
    }

    // MARK: - 生成 AI 响应
    private func generateAIResponse(for input: String) async {
        isProcessing = true

        // 模拟网络延迟
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5秒

        let responses = [
            "这是一个很好的想法！我建议你可以从以下几个方面展开：\n1. 定义核心功能\n2. 设计用户界面\n3. 考虑技术实现",
            "让我帮你分析一下这个主题。首先，我们需要理解其核心概念...",
            "基于你的输入，我认为可以创建几个子主题来更好地组织这些想法。",
            "这个节点看起来需要更多细节。你想要我帮你扩展哪个方向？",
            "我注意到这个主题和你之前提到的概念有关联。要不要我帮你建立连接？"
        ]

        let randomResponse = responses.randomElement() ?? "收到！让我思考一下..."

        await MainActor.run {
            let aiMessage = ChatMessage(role: .assistant, content: randomResponse)
            messages.append(aiMessage)
            isProcessing = false
        }
    }

    // MARK: - 处理拖放
    private func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            if provider.canLoadObject(ofClass: NSData.self) {
                _ = provider.loadObject(ofClass: NSData.self) { data, error in
                    guard let data = data as? Data,
                          let draggedNode = try? JSONDecoder().decode(DraggedNode.self, from: data) else {
                        return
                    }

                    DispatchQueue.main.async {
                        let messageContent = "【来自思维导图】\n标题: \(draggedNode.title)\n内容: \(draggedNode.content)"
                        let userMessage = ChatMessage(
                            role: .user,
                            content: messageContent,
                            relatedNodeId: draggedNode.nodeId
                        )
                        messages.append(userMessage)

                        // 生成 AI 响应
                        Task {
                            await generateAIResponse(for: messageContent)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 聊天气泡
struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(message.role == .user ? Color.blue : Color.gray.opacity(0.2))
                    )
                    .foregroundColor(message.role == .user ? .white : .primary)

                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: 250, alignment: message.role == .user ? .trailing : .leading)

            if message.role == .assistant {
                Spacer()
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()
        FloatingChatWindow()
    }
}
