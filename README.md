# MindMap AI - iOS 思维导图应用

一个功能强大的 iOS 思维导图应用，集成 AI 助手和 iCloud 同步功能。

## 功能特点

### 核心功能
- **可拖拽的思维导图节点**：自由拖动和排列节点
- **多彩卡片设计**：支持 7 种颜色主题
- **节点连接线**：自动绘制父子节点之间的连接关系
- **缩放和平移**：双指缩放和拖动画布
- **节点编辑**：快速编辑节点标题、内容和颜色

### AI 聊天功能
- **浮动聊天窗口**：可缩放的 AI 助手界面
- **拖拽卡片到聊天**：将思维导图节点拖入聊天窗口，AI 可以基于节点内容提供建议
- **智能对话**：AI 助手帮助扩展想法和组织思路

### iCloud 同步
- **自动同步**：使用 CloudKit 实现 iCloud 数据同步
- **离线支持**：本地缓存数据，离线也能使用
- **跨设备同步**：在多个 iOS 设备间同步思维导图

## 技术栈

- **SwiftUI**：现代化的 iOS UI 框架
- **CloudKit**：iCloud 数据同步
- **Combine**：响应式编程
- **iOS 16+**：最低支持版本

## 如何运行

### 1. 使用 Xcode 打开项目

```bash
# 在 Mac 上克隆项目后
cd mind-map-with-ai
open MindMapAI.xcodeproj
```

### 2. 配置 iCloud

在 Xcode 中：
1. 选择项目 `MindMapAI`
2. 选择 Target `MindMapAI`
3. 点击 "Signing & Capabilities"
4. 添加你的 Apple Developer Team
5. 确保 iCloud 功能已启用
6. 修改 Bundle Identifier 为你自己的标识符（例如：`com.yourname.MindMapAI`）
7. 在 `MindMapAI.entitlements` 和 `CloudKitManager.swift` 中更新 iCloud 容器标识符

### 3. 运行应用

1. 选择一个 iOS 模拟器或真机
2. 点击 Run (⌘R)
3. 应用将在设备上启动

## 使用指南

### 创建节点
1. 点击右上角的 `+` 按钮创建新节点
2. 点击节点可以编辑内容
3. 拖动节点可以移动位置

### 使用 AI 助手
1. 点击右下角的浮动按钮打开 AI 聊天窗口
2. 直接输入文字与 AI 对话
3. 或者拖动思维导图卡片到聊天窗口，AI 会基于卡片内容给出建议

### 缩放和导航
- 双指捏合：缩放画布
- 单指拖动画布：平移视图
- 点击右侧工具栏的放大/缩小按钮

### 同步数据
- 点击云同步按钮手动同步
- 应用会自动在后台同步到 iCloud

## 项目结构

```
MindMapAI/
├── MindMapAIApp.swift          # 应用入口
├── ContentView.swift            # 主视图
├── Models/
│   ├── MindMapNode.swift       # 节点数据模型
│   └── ChatMessage.swift       # 聊天消息模型
├── Views/
│   ├── MindMapCanvas.swift     # 思维导图画布
│   ├── MindMapCard.swift       # 节点卡片组件
│   └── FloatingChatWindow.swift # 浮动聊天窗口
├── Services/
│   └── CloudKitManager.swift   # iCloud 同步管理
└── Assets.xcassets/            # 资源文件
```

## 注意事项

1. **iCloud 配置**：需要有效的 Apple Developer 账号才能使用 iCloud 功能
2. **真机测试**：CloudKit 在模拟器上可能有限制，建议使用真机测试同步功能
3. **网络连接**：首次同步需要网络连接

## 未来计划

- [ ] 集成真实的 AI API（如 OpenAI GPT）
- [ ] 支持图片和附件
- [ ] 导出为 PDF/图片
- [ ] 多人协作功能
- [ ] 思维导图模板库
- [ ] 语音输入支持

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！
