import SwiftUI
import SwiftData

// MARK: - AI Coach View (Chat)

struct AICoachView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var messageText = ""
    @State private var aiService: AICoachService?
    @State private var isTyping = false
    @State private var showPaywall = false
    @FocusState private var isInputFocused: Bool

    private var canUse: Bool { PremiumManager.shared.canUseAICoach }

    // Quick action prompts
    private let quickActions = [
        ("🎯", "Составь мне план привычек"),
        ("💪", "Мотивируй меня"),
        ("📊", "Проанализируй мой прогресс"),
        ("💡", "Дай совет по привычкам"),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                SergiTheme.Colors.backgroundLight
                    .ignoresSafeArea()

                if canUse {
                    coachContent
                } else {
                    premiumGate
                }
            }
            .navigationTitle("AI-Коуч")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if canUse {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button("Очистить историю", systemImage: "trash") {
                                // Would clear chat history
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .onAppear {
                if canUse, aiService == nil {
                    aiService = AICoachService(modelContext: modelContext)
                }
            }
        }
    }

    // MARK: - Premium Gate

    private var premiumGate: some View {
        VStack(spacing: SergiTheme.Spacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(SergiTheme.Colors.primary.opacity(0.12))
                    .frame(width: 120, height: 120)
                Image(systemName: "lock.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(SergiTheme.Colors.primary)
            }

            VStack(spacing: SergiTheme.Spacing.sm) {
                Text("AI-Коуч — Premium")
                    .font(SergiTheme.Typography.h2)
                Text("Персональный AI-ассистент для мотивации,\nпланирования и анализа привычек.")
                    .font(SergiTheme.Typography.body)
                    .foregroundStyle(SergiTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button("Открыть Premium") { showPaywall = true }
                .buttonStyle(.sergiPrimary)
                .frame(maxWidth: 240)

            Spacer()
        }
        .padding(SergiTheme.Spacing.lg)
    }

    // MARK: - Coach Content

    private var coachContent: some View {
        VStack(spacing: 0) {
                    // Messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: SergiTheme.Spacing.md) {
                                // Welcome message if empty
                                if aiService?.chatHistory.isEmpty ?? true {
                                    welcomeSection
                                }

                                ForEach(aiService?.chatHistory ?? [], id: \.id) { message in
                                    AIMessageBubble(message: message)
                                        .id(message.id)
                                }

                                if isTyping {
                                    HStack {
                                        aiAvatarSmall
                                        TypingIndicator()
                                        Spacer()
                                    }
                                }
                            }
                            .padding(SergiTheme.Spacing.md)
                        }
                        .onChange(of: aiService?.chatHistory.count) { _, _ in
                            withAnimation {
                                if let lastID = aiService?.chatHistory.last?.id {
                                    proxy.scrollTo(lastID, anchor: .bottom)
                                }
                            }
                        }
                    }

                    // Quick actions (when empty)
                    if aiService?.chatHistory.isEmpty ?? true {
                        quickActionsBar
                    }

                    // Input bar
                    inputBar
                }
    }

    // MARK: - Welcome Section

    private var welcomeSection: some View {
        VStack(spacing: SergiTheme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [SergiTheme.Colors.primary, SergiTheme.Colors.primaryLight],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "brain.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.white)
            }

            VStack(spacing: SergiTheme.Spacing.sm) {
                Text("Привет! Я Sergi 👋")
                    .font(SergiTheme.Typography.h2)

                Text("Я твой персональный AI-коуч.\nМогу помочь с привычками, мотивацией и планированием.")
                    .font(SergiTheme.Typography.body)
                    .foregroundStyle(SergiTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, SergiTheme.Spacing.xxl)
        .padding(.bottom, SergiTheme.Spacing.lg)
    }

    // MARK: - Quick Actions

    private var quickActionsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: SergiTheme.Spacing.sm) {
                ForEach(quickActions, id: \.1) { emoji, title in
                    Button {
                        sendMessage(title)
                    } label: {
                        HStack(spacing: SergiTheme.Spacing.xs) {
                            Text(emoji)
                            Text(title)
                                .font(SergiTheme.Typography.caption)
                        }
                        .padding(.horizontal, SergiTheme.Spacing.md)
                        .padding(.vertical, SergiTheme.Spacing.sm)
                        .background(
                            Capsule()
                                .fill(SergiTheme.Colors.surfaceLight)
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(SergiTheme.Colors.primary.opacity(0.3), lineWidth: 1)
                        )
                        .foregroundStyle(SergiTheme.Colors.textPrimary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, SergiTheme.Spacing.md)
            .padding(.bottom, SergiTheme.Spacing.sm)
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: SergiTheme.Spacing.sm) {
            TextField("Спроси что-нибудь...", text: $messageText, axis: .vertical)
                .font(SergiTheme.Typography.body)
                .lineLimit(1...4)
                .focused($isInputFocused)
                .padding(SergiTheme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: SergiTheme.Radius.large)
                        .fill(SergiTheme.Colors.surfaceLight)
                )

            Button {
                sendMessage(messageText)
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(
                        messageText.trimmingCharacters(in: .whitespaces).isEmpty
                        ? SergiTheme.Colors.textTertiary
                        : SergiTheme.Colors.primary
                    )
            }
            .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty || isTyping)
        }
        .padding(.horizontal, SergiTheme.Spacing.md)
        .padding(.vertical, SergiTheme.Spacing.sm)
        .background(.ultraThinMaterial)
    }

    // MARK: - AI Avatar

    private var aiAvatarSmall: some View {
        ZStack {
            Circle()
                .fill(SergiTheme.Colors.primary)
                .frame(width: 32, height: 32)
            Image(systemName: "brain.fill")
                .font(.system(size: 14))
                .foregroundStyle(.white)
        }
    }

    // MARK: - Send

    private func sendMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        messageText = ""
        isInputFocused = false
        isTyping = true

        Task {
            _ = await aiService?.sendMessage(trimmed)
            isTyping = false
        }
    }
}
