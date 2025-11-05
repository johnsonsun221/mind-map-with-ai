import SwiftUI

/// App 图标生成器 - 用于生成应用图标
struct AppIconGenerator: View {
    var body: some View {
        ZStack {
            // 渐变背景
            LinearGradient(
                colors: [
                    Color(red: 0.4, green: 0.6, blue: 1.0),
                    Color(red: 0.6, green: 0.4, blue: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // 思维导图节点图案
            VStack(spacing: 20) {
                // 中心节点
                Circle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 40))
                            .foregroundColor(Color(red: 0.5, green: 0.45, blue: 1.0))
                    )

                // 连接线和子节点
                HStack(spacing: 40) {
                    // 左节点
                    Circle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 24))
                                .foregroundColor(Color.yellow)
                        )

                    // 右节点
                    Circle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "star.fill")
                                .font(.system(size: 24))
                                .foregroundColor(Color.orange)
                        )
                }
                .offset(y: -60)
            }

            // 装饰性连接线
            Path { path in
                path.move(to: CGPoint(x: 512, y: 512))
                path.addLine(to: CGPoint(x: 400, y: 650))

                path.move(to: CGPoint(x: 512, y: 512))
                path.addLine(to: CGPoint(x: 624, y: 650))
            }
            .stroke(Color.white.opacity(0.6), lineWidth: 4)
        }
        .frame(width: 1024, height: 1024)
    }
}

#Preview {
    AppIconGenerator()
}
