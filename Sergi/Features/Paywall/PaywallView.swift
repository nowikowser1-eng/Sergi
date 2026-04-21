import SwiftUI
import StoreKit

// MARK: - Paywall View

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: SubscriptionPlan = .annual
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    private let storeService = StoreService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        SergiTheme.Colors.primary.opacity(0.1),
                        SergiTheme.Colors.backgroundLight,
                        SergiTheme.Colors.accent.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: SergiTheme.Spacing.xl) {
                        // Header
                        headerSection

                        // Features
                        featuresSection

                        // Plan picker
                        planPicker

                        // CTA
                        ctaButton

                        // Legal
                        legalSection
                    }
                    .padding(SergiTheme.Spacing.lg)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(SergiTheme.Colors.textTertiary)
                    }
                }
            }
            .alert("Ошибка", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .task {
                await storeService.loadProducts()
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: SergiTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [SergiTheme.Colors.primary, SergiTheme.Colors.accent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "crown.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.white)
            }

            Text("Sergi Premium")
                .font(SergiTheme.Typography.h1)
                .foregroundStyle(SergiTheme.Colors.textPrimary)

            Text("Разблокируй полный потенциал\nсвоих привычек")
                .font(SergiTheme.Typography.bodyLarge)
                .foregroundStyle(SergiTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)

            // Trial badge
            Text("3 дня бесплатно")
                .font(SergiTheme.Typography.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, SergiTheme.Spacing.md)
                .padding(.vertical, SergiTheme.Spacing.xs)
                .background(Capsule().fill(SergiTheme.Colors.success))
        }
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(spacing: SergiTheme.Spacing.md) {
            featureRow(icon: "brain.fill", title: "AI-Коуч", description: "Персональный коуч с полным функционалом", color: SergiTheme.Colors.primary)
            featureRow(icon: "infinity", title: "Безлимит привычек", description: "Создавай сколько угодно привычек", color: SergiTheme.Colors.categoryHealth)
            featureRow(icon: "chart.xyaxis.line", title: "Продвинутая аналитика", description: "Глубокие инсайты и корреляции", color: SergiTheme.Colors.categoryProductivity)
            featureRow(icon: "paintpalette.fill", title: "Кастомные темы", description: "Иконки, цвета и оформление", color: SergiTheme.Colors.categoryRelationships)
            featureRow(icon: "arrow.down.doc.fill", title: "Экспорт данных", description: "CSV, PDF — все твои данные", color: SergiTheme.Colors.info)
            featureRow(icon: "nosign", title: "Без рекламы", description: "Чистый интерфейс без отвлечений", color: SergiTheme.Colors.textSecondary)
        }
        .padding(SergiTheme.Spacing.md)
        .sergiCard()
    }

    private func featureRow(icon: String, title: String, description: String, color: Color) -> some View {
        HStack(spacing: SergiTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(Circle().fill(color.opacity(0.12)))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(SergiTheme.Typography.body)
                    .fontWeight(.medium)
                    .foregroundStyle(SergiTheme.Colors.textPrimary)
                Text(description)
                    .font(SergiTheme.Typography.caption)
                    .foregroundStyle(SergiTheme.Colors.textSecondary)
            }

            Spacer()

            Image(systemName: "checkmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(SergiTheme.Colors.success)
        }
    }

    // MARK: - Plan Picker

    private var planPicker: some View {
        VStack(spacing: SergiTheme.Spacing.sm) {
            ForEach(mainPlans, id: \.self) { plan in
                PlanCard(
                    plan: plan,
                    isSelected: selectedPlan == plan,
                    storeProduct: storeService.product(for: plan)
                ) {
                    withAnimation(SergiTheme.Animation.microInteraction) {
                        selectedPlan = plan
                    }
                }
            }
        }
    }

    private var mainPlans: [SubscriptionPlan] {
        [.monthly, .quarterly, .annual]
    }

    // MARK: - CTA

    private var ctaButton: some View {
        VStack(spacing: SergiTheme.Spacing.sm) {
            Button {
                purchase()
            } label: {
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Начать бесплатный период")
                }
            }
            .buttonStyle(.sergiPrimary)
            .disabled(isPurchasing)

            Button("Восстановить покупки") {
                Task { await storeService.restorePurchases() }
            }
            .font(SergiTheme.Typography.caption)
            .foregroundStyle(SergiTheme.Colors.textTertiary)
        }
    }

    // MARK: - Legal

    private var legalSection: some View {
        VStack(spacing: SergiTheme.Spacing.xs) {
            Text("Подписка продлевается автоматически. Отмена — в настройках Apple ID.")
            Text("Условия использования • Политика конфиденциальности")
                .foregroundStyle(SergiTheme.Colors.primary)
        }
        .font(.system(size: 11))
        .foregroundStyle(SergiTheme.Colors.textTertiary)
        .multilineTextAlignment(.center)
    }

    // MARK: - Purchase

    private func purchase() {
        guard let product = storeService.product(for: selectedPlan) else {
            errorMessage = "Продукт не найден. Попробуйте позже."
            showError = true
            return
        }

        isPurchasing = true
        Task {
            do {
                let success = try await storeService.purchase(product)
                if success {
                    dismiss()
                }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isPurchasing = false
        }
    }
}

// MARK: - Plan Card

private struct PlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let storeProduct: Product?
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: SergiTheme.Spacing.xs) {
                    HStack(spacing: SergiTheme.Spacing.sm) {
                        Text(plan.displayName)
                            .font(SergiTheme.Typography.h3)
                            .foregroundStyle(SergiTheme.Colors.textPrimary)

                        if plan.isBestValue {
                            Text("Лучшая цена")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(SergiTheme.Colors.success))
                        }

                        if plan.discountPercent > 0 {
                            Text("-\(plan.discountPercent)%")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(SergiTheme.Colors.error)
                        }
                    }

                    Text(priceText)
                        .font(SergiTheme.Typography.caption)
                        .foregroundStyle(SergiTheme.Colors.textSecondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected ? SergiTheme.Colors.primary : SergiTheme.Colors.textTertiary)
            }
            .padding(SergiTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: SergiTheme.Radius.medium)
                    .fill(SergiTheme.Colors.surfaceLight)
                    .overlay(
                        RoundedRectangle(cornerRadius: SergiTheme.Radius.medium)
                            .strokeBorder(
                                isSelected ? SergiTheme.Colors.primary : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
            .sergiShadow()
        }
        .buttonStyle(.plain)
    }

    private var priceText: String {
        if let product = storeProduct {
            return "\(product.displayPrice)"
        }
        return "\(plan.priceRubles) ₽ (\(plan.monthlyEquivalent) ₽/мес)"
    }
}
