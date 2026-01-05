//
//  ChatView.swift
//  midori
//
//  SwiftUI chat interface for Midori conversations
//

import SwiftUI

/// The main chat window content
struct ChatWindowContent: View {
    @ObservedObject var state: ChatWindowState
    var onSend: (String) -> Void
    var onClose: () -> Void

    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            ChatHeader(onClose: onClose)

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(state.messages) { message in
                            ChatBubble(message: message)
                                .id(message.id)
                        }

                        if state.isLoading {
                            LoadingBubble()
                                .id("loading")
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .onChange(of: state.messages.count) { _, _ in
                    // Scroll to bottom when new message arrives
                    if let lastMessage = state.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: state.isLoading) { _, isLoading in
                    if isLoading {
                        withAnimation {
                            proxy.scrollTo("loading", anchor: .bottom)
                        }
                    }
                }
            }

            // Input field
            ChatInput(
                text: $state.inputText,
                isInputFocused: $isInputFocused,
                onSend: {
                    let text = state.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !text.isEmpty {
                        state.addUserMessage(text)
                        state.inputText = ""
                        state.isLoading = true
                        onSend(text)
                    }
                }
            )
        }
        .frame(minWidth: 250, minHeight: 300)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            // Slight delay to ensure window is fully key before focusing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isInputFocused = true
            }
        }
    }
}

/// Chat header with title and close button
struct ChatHeader: View {
    var onClose: () -> Void

    var body: some View {
        HStack {
            // Midori icon
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "10B981"), Color(hex: "059669")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 20, height: 20)
                .overlay(
                    Text("M")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                )

            Text("Midori")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.primary)

            Spacer()

            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Close (Esc)")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
    }
}

/// Individual chat bubble
struct ChatBubble: View {
    let message: ChatMessage

    // Cyan color from waveform gradient for italics
    private let italicColor = Color(red: 0.0, green: 1.0, blue: 1.0)

    var body: some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 50)
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 2) {
                formattedText(message.content, isUser: message.isUser)
                    .font(.system(size: 11))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(message.isUser ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
                    )

                Text(timeString(from: message.timestamp))
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }

            if !message.isUser {
                Spacer(minLength: 50)
            }
        }
    }

    /// Parse *italics* and render them in cyan
    private func formattedText(_ text: String, isUser: Bool) -> Text {
        let baseColor: Color = isUser ? .white : .primary

        var result = Text("")
        var remaining = text
        let pattern = /\*([^*]+)\*/

        while let match = remaining.firstMatch(of: pattern) {
            // Add text before the match
            let before = String(remaining[..<match.range.lowerBound])
            if !before.isEmpty {
                result = result + Text(before).foregroundColor(baseColor)
            }

            // Add the italic text in cyan
            let italicText = String(match.1)
            result = result + Text(italicText)
                .italic()
                .foregroundColor(italicColor)

            // Continue with the rest
            remaining = String(remaining[match.range.upperBound...])
        }

        // Add any remaining text
        if !remaining.isEmpty {
            result = result + Text(remaining).foregroundColor(baseColor)
        }

        return result
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

/// Loading indicator bubble
struct LoadingBubble: View {
    @State private var dotCount = 0

    var body: some View {
        HStack {
            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 5, height: 5)
                        .opacity(index <= dotCount ? 1 : 0.3)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )

            Spacer()
        }
        .onAppear {
            animateDots()
        }
    }

    private func animateDots() {
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { timer in
            withAnimation {
                dotCount = (dotCount + 1) % 4
            }
        }
    }
}

/// Chat input field with scrollable text area
struct ChatInput: View {
    @Binding var text: String
    var isInputFocused: FocusState<Bool>.Binding
    var onSend: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            TextEditor(text: $text)
                .font(.system(size: 11))
                .scrollContentBackground(.hidden)
                .padding(6)
                .focused(isInputFocused)
                .frame(minHeight: 28, maxHeight: 120)
                .fixedSize(horizontal: false, vertical: true)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
                .onKeyPress(.return) {
                    if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        onSend()
                        return .handled
                    }
                    return .ignored
                }

            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(text.isEmpty ? .secondary : .accentColor)
            }
            .buttonStyle(.plain)
            .disabled(text.isEmpty)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
