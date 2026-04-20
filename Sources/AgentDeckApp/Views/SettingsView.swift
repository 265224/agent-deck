import SwiftUI
import AppKit
import AgentDeckCore

// MARK: - Settings tabs

enum SettingsTab: String, CaseIterable, Identifiable {
    case general
    case setup
    case display
    case sound
    case appearance
    case about

    var id: String { rawValue }

    func label(_ lang: LanguageManager) -> String {
        switch self {
        case .general:    lang.t("settings.tab.general")
        case .setup:      lang.t("settings.tab.setup")
        case .appearance: lang.t("settings.tab.appearance")
        case .display:    lang.t("settings.tab.display")
        case .sound:      lang.t("settings.tab.sound")
        case .about:      lang.t("settings.tab.about")
        }
    }

    func summary(_ lang: LanguageManager) -> String {
        switch self {
        case .general:    lang.t("settings.summary.general")
        case .setup:      lang.t("settings.summary.setup")
        case .appearance: lang.t("settings.summary.appearance")
        case .display:    lang.t("settings.summary.display")
        case .sound:      lang.t("settings.summary.sound")
        case .about:      lang.t("settings.summary.about")
        }
    }

    var icon: String {
        switch self {
        case .general:    "gearshape.fill"
        case .setup:      "arrow.down.circle.fill"
        case .appearance: "paintbrush.fill"
        case .display:    "textformat.size"
        case .sound:      "speaker.wave.2.fill"
        case .about:      "info.circle.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .general:    .gray
        case .setup:      .orange
        case .appearance: .purple
        case .display:    .blue
        case .sound:      .green
        case .about:      .blue
        }
    }

    var section: SettingsSection {
        switch self {
        case .general, .setup, .display, .sound, .appearance: .system
        case .about:                                          .app
        }
    }
}

enum SettingsSection: String, CaseIterable {
    case system
    case app

    func header(_ lang: LanguageManager) -> String {
        switch self {
        case .system:   lang.t("settings.section.system")
        case .app:      "Agent Deck"
        }
    }

    var tabs: [SettingsTab] {
        SettingsTab.allCases.filter { $0.section == self }
    }
}

// MARK: - Root settings view

struct SettingsView: View {
    var model: AppModel
    @State private var selectedTab: SettingsTab = .general

    private var lang: LanguageManager { model.lang }
    private let sidebarWidth: CGFloat = 214

    init(model: AppModel, initialTab: SettingsTab = .general) {
        self.model = model
        _selectedTab = State(initialValue: initialTab)
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: sidebarWidth)

            Rectangle()
                .fill(AgentDeckSettingsStyle.hairline)
                .frame(width: 1)

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: selectedTab.icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(selectedTab.iconColor)
                        .frame(width: 30, height: 30)
                        .background(AgentDeckSettingsStyle.panel)
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedTab.label(lang))
                            .font(.system(size: 21, weight: .bold))
                            .foregroundStyle(.white)
                        Text(selectedTab.summary(lang))
                            .font(.departureMono(size: 10))
                            .foregroundStyle(.white.opacity(0.38))
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)

                    settingsStatusCluster
                }
                .padding(.horizontal, 26)
                .padding(.top, 24)
                .padding(.bottom, 14)

                detailView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(AgentDeckSettingsStyle.background)
        }
        .frame(minWidth: 860, idealWidth: 940, minHeight: 580, idealHeight: 680)
        .background(AgentDeckSettingsStyle.background)
        .preferredColorScheme(.dark)
    }

    private var settingsStatusCluster: some View {
        HStack(spacing: 8) {
            AgentDeckSettingsMetricPill(
                label: "LIVE",
                value: "\(model.liveSessionCount)",
                tint: model.liveSessionCount > 0 ? AgentDeckSettingsStyle.green : .white.opacity(0.5)
            )
            AgentDeckSettingsMetricPill(
                label: "NEEDS",
                value: "\(model.liveAttentionCount)",
                tint: model.liveAttentionCount > 0 ? AgentDeckSettingsStyle.amber : .white.opacity(0.5)
            )
        }
    }

    // MARK: Sidebar

    @ViewBuilder
    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            sidebarBrand

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(SettingsSection.allCases, id: \.self) { section in
                        sidebarSection(section)
                    }
                }
                .padding(.vertical, 18)
            }
            .scrollIndicators(.never)
            .frame(maxHeight: .infinity)

            sidebarStatus
        }
        .background(Color.black.opacity(0.92))
    }

    private var sidebarBrand: some View {
        HStack(spacing: 10) {
            AgentDeckBrandMark(size: 24, tint: AgentDeckSettingsStyle.green, isAnimating: true, style: .duotone)
            VStack(alignment: .leading, spacing: 1) {
                Text("VIBE ISLAND")
                    .font(.departureMono(size: 12))
                    .foregroundStyle(AgentDeckSettingsStyle.green)
                Text("SETTINGS")
                    .font(.departureMono(size: 9))
                    .foregroundStyle(.white.opacity(0.38))
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 28)
        .padding(.bottom, 8)
    }

    private func sidebarSection(_ section: SettingsSection) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(section.header(lang).uppercased())
                .font(.departureMono(size: 9))
                .foregroundStyle(.white.opacity(0.34))
                .padding(.horizontal, 18)

            ForEach(section.tabs) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    AgentDeckSettingsSidebarRow(
                        title: tab.label(lang),
                        systemImage: tab.icon,
                        tint: tab.iconColor,
                        isSelected: selectedTab == tab
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var sidebarStatus: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: model.liveAttentionCount > 0 ? "bell.badge.fill" : "dot.radiowaves.left.and.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(model.liveAttentionCount > 0 ? AgentDeckSettingsStyle.amber : AgentDeckSettingsStyle.green)
                .frame(width: 24, height: 24)
                .background(Color.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(model.liveSessionCount == 1 ? "1 live session" : "\(model.liveSessionCount) live sessions")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.82))
                Text(model.lastActionMessage)
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(.white.opacity(0.44))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AgentDeckSettingsStyle.panelStrong)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(AgentDeckSettingsStyle.hairline)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.horizontal, 12)
        .padding(.bottom, 14)
    }

    // MARK: Detail

    @ViewBuilder
    private var detailView: some View {
        switch selectedTab {
        case .general:
            GeneralSettingsPane(model: model)
        case .setup:
            SetupSettingsPane(model: model)
        case .appearance:
            AppearanceSettingsPane(model: model)
        case .display:
            DisplaySettingsPane(model: model)
        case .sound:
            SoundSettingsPane(model: model)
        case .about:
            AboutSettingsPane(model: model)
        }
    }
}

enum AgentDeckSettingsStyle {
    static let background = Color(red: 0.025, green: 0.026, blue: 0.029)
    static let panel = Color.white.opacity(0.055)
    static let panelStrong = Color.white.opacity(0.085)
    static let hairline = Color.white.opacity(0.09)
    static let green = Color(red: 0.36, green: 1.0, blue: 0.34)
    static let amber = Color(red: 1.0, green: 0.68, blue: 0.22)
}

private struct AgentDeckSettingsSidebarRow: View {
    let title: String
    let systemImage: String
    let tint: Color
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isSelected ? .black : tint)
                .frame(width: 24, height: 24)
                .background(isSelected ? AgentDeckSettingsStyle.green : Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            Text(title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.66))

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(isSelected ? Color.white.opacity(0.08) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.horizontal, 8)
    }
}

struct AgentDeckSettingsSection<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title.uppercased())
                    .font(.departureMono(size: 10))
                    .foregroundStyle(AgentDeckSettingsStyle.green.opacity(0.9))
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(.white.opacity(0.45))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AgentDeckSettingsStyle.panel)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(AgentDeckSettingsStyle.hairline)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct AgentDeckSettingsRow<Accessory: View>: View {
    let title: String
    var subtitle: String? = nil
    var systemImage: String = "terminal"
    var tint: Color = AgentDeckSettingsStyle.green
    @ViewBuilder var accessory: () -> Accessory

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.44))
                        .lineLimit(2)
                        .truncationMode(.middle)
                }
            }

            Spacer(minLength: 0)
            accessory()
        }
        .padding(12)
        .background(Color.black.opacity(0.28))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.white.opacity(0.06))
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct AgentDeckStatusPill: View {
    let text: String
    let tint: Color
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: 5) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 9, weight: .bold))
            }
            Text(text)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(tint.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
    }
}

private struct AgentDeckSettingsMetricPill: View {
    let label: String
    let value: String
    let tint: Color

    var body: some View {
        HStack(spacing: 7) {
            Text(label)
                .font(.departureMono(size: 9))
                .foregroundStyle(.white.opacity(0.42))
            Text(value)
                .font(.departureMono(size: 13))
                .foregroundStyle(tint)
                .frame(minWidth: 16, alignment: .trailing)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(AgentDeckSettingsStyle.panel)
        .overlay(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .strokeBorder(AgentDeckSettingsStyle.hairline)
        )
        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
    }
}

struct AgentDeckSettingsButtonStyle: ButtonStyle {
    enum Kind {
        case primary
        case secondary
        case destructive
    }

    var kind: Kind = .secondary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11.5, weight: .bold))
            .foregroundStyle(foreground)
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(background.opacity(configuration.isPressed ? 0.68 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    private var foreground: Color {
        switch kind {
        case .primary: .black
        case .secondary: .white.opacity(0.78)
        case .destructive: Color(red: 1.0, green: 0.42, blue: 0.42)
        }
    }

    private var background: Color {
        switch kind {
        case .primary: AgentDeckSettingsStyle.green
        case .secondary: Color.white.opacity(0.1)
        case .destructive: Color(red: 1.0, green: 0.18, blue: 0.18).opacity(0.14)
        }
    }
}

// MARK: - General

struct GeneralSettingsPane: View {
    var model: AppModel

    @State private var launchAtLogin = false

    private var lang: LanguageManager { model.lang }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                AgentDeckSettingsSection(title: lang.t("settings.section.system")) {
                    VStack(spacing: 8) {
                        AgentDeckSettingsRow(title: lang.t("settings.general.launchAtLogin"), systemImage: "power", tint: AgentDeckSettingsStyle.green) {
                            Toggle("", isOn: $launchAtLogin)
                                .labelsHidden()
                                .toggleStyle(.switch)
                        }

                        AgentDeckSettingsRow(title: lang.t("settings.general.monitor"), systemImage: "display", tint: .cyan) {
                            Picker("", selection: Binding(
                                get: { model.overlayDisplaySelectionID },
                                set: { model.overlayDisplaySelectionID = $0 }
                            )) {
                                Text(lang.t("settings.general.automatic")).tag(OverlayDisplayOption.automaticID)
                                ForEach(model.overlayDisplayOptions) { option in
                                    Text(option.title).tag(option.id)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 190)
                        }
                    }
                }

                AgentDeckSettingsSection(title: lang.t("settings.general.language")) {
                    AgentDeckSettingsRow(title: lang.t("settings.general.language"), systemImage: "globe", tint: AgentDeckSettingsStyle.amber) {
                        Picker("", selection: Binding(
                            get: { lang.language },
                            set: { lang.language = $0 }
                        )) {
                            Text(lang.t("settings.general.languageSystem")).tag(LanguageManager.AppLanguage.system)
                            Text(lang.t("settings.general.languageEnglish")).tag(LanguageManager.AppLanguage.en)
                            Text(lang.t("settings.general.languageChinese")).tag(LanguageManager.AppLanguage.zhHans)
                            Text(lang.t("settings.general.languageTraditionalChinese")).tag(LanguageManager.AppLanguage.zhHant)
                        }
                        .labelsHidden()
                        .frame(width: 190)
                    }
                }

                AgentDeckSettingsSection(title: lang.t("settings.general.behavior")) {
                    VStack(spacing: 8) {
                        settingsToggleRow(lang.t("settings.general.autoCollapse"), systemImage: "arrow.down.right.and.arrow.up.left", isOn: .constant(true))
                        settingsToggleRow(lang.t("settings.general.showDockIcon"), systemImage: "dock.rectangle", isOn: Binding(
                            get: { model.showDockIcon },
                            set: { model.showDockIcon = $0 }
                        ))
                        settingsToggleRow(lang.t("settings.general.hapticFeedback"), systemImage: "hand.tap.fill", isOn: Binding(
                            get: { model.hapticFeedbackEnabled },
                            set: { model.hapticFeedbackEnabled = $0 }
                        ))
                        settingsToggleRow(lang.t("settings.general.completionReply"), systemImage: "arrowshape.turn.up.left.fill", isOn: Binding(
                            get: { model.completionReplyEnabled },
                            set: { model.completionReplyEnabled = $0 }
                        ))
                        settingsToggleRow(lang.t("settings.general.suppressFrontmostNotifications"), systemImage: "bell.slash.fill", isOn: Binding(
                            get: { model.suppressFrontmostNotifications },
                            set: { model.suppressFrontmostNotifications = $0 }
                        ))
                    }
                }
            }
            .padding(.horizontal, 26)
            .padding(.top, 4)
            .padding(.bottom, 28)
        }
        .background(AgentDeckSettingsStyle.background)
    }

    private func settingsToggleRow(_ title: String, systemImage: String, isOn: Binding<Bool>) -> some View {
        AgentDeckSettingsRow(title: title, systemImage: systemImage, tint: AgentDeckSettingsStyle.green) {
            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
        }
    }
}

// MARK: - Display

struct DisplaySettingsPane: View {
    var model: AppModel

    private var lang: LanguageManager { model.lang }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                AgentDeckSettingsSection(title: lang.t("settings.display.monitor")) {
                    AgentDeckSettingsRow(title: lang.t("settings.display.position"), systemImage: "display", tint: .cyan) {
                        Picker("", selection: Binding(
                            get: { model.overlayDisplaySelectionID },
                            set: { model.overlayDisplaySelectionID = $0 }
                        )) {
                            Text(lang.t("settings.general.automatic")).tag(OverlayDisplayOption.automaticID)
                            ForEach(model.overlayDisplayOptions) { option in
                                Text(option.title).tag(option.id)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 190)
                    }
                }

                if let diag = model.overlayPlacementDiagnostics {
                    AgentDeckSettingsSection(title: lang.t("settings.display.diagnostics")) {
                        VStack(spacing: 8) {
                            AgentDeckSettingsRow(title: lang.t("settings.display.currentScreen"), subtitle: diag.targetScreenName, systemImage: "rectangle.on.rectangle", tint: AgentDeckSettingsStyle.green) { EmptyView() }
                            AgentDeckSettingsRow(title: lang.t("settings.display.layoutMode"), subtitle: diag.modeDescription, systemImage: "ruler", tint: AgentDeckSettingsStyle.amber) { EmptyView() }
                        }
                    }
                }
            }
            .padding(.horizontal, 26)
            .padding(.top, 4)
            .padding(.bottom, 28)
        }
        .background(AgentDeckSettingsStyle.background)
    }
}

// MARK: - Sound

struct SoundSettingsPane: View {
    var model: AppModel

    private var lang: LanguageManager { model.lang }

    private var availableSounds: [String] {
        NotificationSoundService.availableSounds()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                AgentDeckSettingsSection(title: lang.t("settings.sound.notifications")) {
                    AgentDeckSettingsRow(title: lang.t("settings.sound.mute"), systemImage: "speaker.slash.fill", tint: AgentDeckSettingsStyle.amber) {
                        Toggle("", isOn: Binding(
                            get: { model.isSoundMuted },
                            set: { _ in model.toggleSoundMuted() }
                        ))
                        .labelsHidden()
                        .toggleStyle(.switch)
                    }
                }

                AgentDeckSettingsSection(title: lang.t("settings.sound.selectSound")) {
                    VStack(spacing: 8) {
                        ForEach(availableSounds, id: \.self) { name in
                            Button {
                                model.selectedSoundName = name
                                NotificationSoundService.play(name)
                            } label: {
                                AgentDeckSettingsRow(title: name, systemImage: "waveform", tint: name == model.selectedSoundName ? AgentDeckSettingsStyle.green : .white.opacity(0.5)) {
                                    if name == model.selectedSoundName {
                                        AgentDeckStatusPill(text: lang.t("settings.general.activated"), tint: AgentDeckSettingsStyle.green, systemImage: "checkmark")
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 26)
            .padding(.top, 4)
            .padding(.bottom, 28)
        }
        .background(AgentDeckSettingsStyle.background)
    }
}

// MARK: - About

struct AboutSettingsPane: View {
    var model: AppModel

    private var lang: LanguageManager { model.lang }
    private let primaryInk = Color.white.opacity(0.94)

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 8) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .frame(width: 56, height: 56)

                Text(lang.t("app.name"))
                    .font(.title.bold())

                Text(lang.t("app.description"))
                    .foregroundStyle(.secondary)

                if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                    Text(lang.t("settings.about.version", version))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.top, 30)

            AgentDeckSettingsSection(title: lang.t("settings.tab.about")) {
                aboutActionRow(
                    title: lang.t("settings.about.quitApp"),
                    systemImage: "rectangle.portrait.and.arrow.right",
                    tint: Color(red: 1.0, green: 0.29, blue: 0.29),
                    action: {
                        model.quitApplication()
                    }
                )
                .accessibilityIdentifier("settings.about.quitApp")
            }
            .padding(.horizontal, 26)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(AgentDeckSettingsStyle.background)
    }

    private func aboutActionRow(
        title: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            AgentDeckSettingsRow(title: title, systemImage: systemImage, tint: tint) {
                EmptyView()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Setup

struct SetupSettingsPane: View {
    var model: AppModel

    @State private var confirmingUninstallClaude = false
    @State private var confirmingUninstallCodex = false
    @State private var confirmingUninstallOpenCode = false
    @State private var confirmingUninstallQoder = false
    @State private var confirmingUninstallQwenCode = false
    @State private var confirmingUninstallFactory = false
    @State private var confirmingUninstallCodebuddy = false
    @State private var confirmingUninstallCursor = false
    @State private var confirmingUninstallGemini = false
    @State private var confirmingUninstallCatPaw = false
    @State private var confirmingUninstallClaudeUsage = false

    private var lang: LanguageManager { model.lang }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
            claudeConfigDirectorySection

            AgentDeckSettingsSection(
                title: lang.t("setup.section.hooks"),
                subtitle: model.hooksBinaryURL == nil ? lang.t("setup.binaryMissing") : lang.t("setup.binaryReady")
            ) {
                VStack(spacing: 8) {
                hookRow(
                    name: "Claude Code",
                    installed: model.claudeHooksInstalled,
                    busy: model.isClaudeHookSetupBusy,
                    configLocationURL: model.claudeHookStatus?.settingsURL,
                    installAction: { model.installClaudeHooks() },
                    uninstallAction: { confirmingUninstallClaude = true }
                )
                .alert(lang.t("settings.general.uninstallConfirmTitle"), isPresented: $confirmingUninstallClaude) {
                    Button(lang.t("settings.general.uninstallConfirmAction"), role: .destructive) {
                        model.uninstallClaudeHooks()
                    }
                    Button(lang.t("settings.general.cancel"), role: .cancel) {}
                } message: {
                    Text(lang.t("settings.general.uninstallConfirmMessage.claude"))
                }

                hookRow(
                    name: "Codex",
                    installed: model.codexHooksInstalled,
                    busy: model.isCodexSetupBusy,
                    configLocationURL: codexHookConfigURL,
                    installAction: { model.installCodexHooks() },
                    uninstallAction: { confirmingUninstallCodex = true }
                )
                .alert(lang.t("settings.general.uninstallConfirmTitle"), isPresented: $confirmingUninstallCodex) {
                    Button(lang.t("settings.general.uninstallConfirmAction"), role: .destructive) {
                        model.uninstallCodexHooks()
                    }
                    Button(lang.t("settings.general.cancel"), role: .cancel) {}
                } message: {
                    Text(lang.t("settings.general.uninstallConfirmMessage.codex"))
                }

                hookRow(
                    name: "OpenCode",
                    installed: model.openCodePluginInstalled,
                    busy: model.isOpenCodeSetupBusy,
                    requiresBinary: false,
                    configLocationURL: model.openCodePluginStatus?.configURL,
                    installAction: { model.installOpenCodePlugin() },
                    uninstallAction: { confirmingUninstallOpenCode = true }
                )
                .alert(lang.t("settings.general.uninstallConfirmTitle"), isPresented: $confirmingUninstallOpenCode) {
                    Button(lang.t("settings.general.uninstallConfirmAction"), role: .destructive) {
                        model.uninstallOpenCodePlugin()
                    }
                    Button(lang.t("settings.general.cancel"), role: .cancel) {}
                } message: {
                    Text("This will remove the Agent Deck plugin from ~/.config/opencode/plugins/.")
                }

                hookRow(
                    name: "Qoder",
                    installed: model.qoderHooksInstalled,
                    busy: model.isQoderHookSetupBusy,
                    configLocationURL: model.qoderHookStatus?.settingsURL,
                    installAction: { model.installQoderHooks() },
                    uninstallAction: { confirmingUninstallQoder = true }
                )
                .alert(lang.t("settings.general.uninstallConfirmTitle"), isPresented: $confirmingUninstallQoder) {
                    Button(lang.t("settings.general.uninstallConfirmAction"), role: .destructive) {
                        model.uninstallQoderHooks()
                    }
                    Button(lang.t("settings.general.cancel"), role: .cancel) {}
                } message: {
                    Text("This will remove Agent Deck hooks from ~/.qoder/settings.json.")
                }

                hookRow(
                    name: "Qwen Code",
                    installed: model.qwenCodeHooksInstalled,
                    busy: model.isQwenCodeHookSetupBusy,
                    configLocationURL: model.qwenCodeHookStatus?.settingsURL,
                    installAction: { model.installQwenCodeHooks() },
                    uninstallAction: { confirmingUninstallQwenCode = true }
                )
                .alert(lang.t("settings.general.uninstallConfirmTitle"), isPresented: $confirmingUninstallQwenCode) {
                    Button(lang.t("settings.general.uninstallConfirmAction"), role: .destructive) {
                        model.uninstallQwenCodeHooks()
                    }
                    Button(lang.t("settings.general.cancel"), role: .cancel) {}
                } message: {
                    Text("This will remove Agent Deck hooks from ~/.qwen/settings.json.")
                }

                hookRow(
                    name: "Factory",
                    installed: model.factoryHooksInstalled,
                    busy: model.isFactoryHookSetupBusy,
                    configLocationURL: model.factoryHookStatus?.settingsURL,
                    installAction: { model.installFactoryHooks() },
                    uninstallAction: { confirmingUninstallFactory = true }
                )
                .alert(lang.t("settings.general.uninstallConfirmTitle"), isPresented: $confirmingUninstallFactory) {
                    Button(lang.t("settings.general.uninstallConfirmAction"), role: .destructive) {
                        model.uninstallFactoryHooks()
                    }
                    Button(lang.t("settings.general.cancel"), role: .cancel) {}
                } message: {
                    Text("This will remove Agent Deck hooks from ~/.factory/settings.json.")
                }

                hookRow(
                    name: "CodeBuddy",
                    installed: model.codebuddyHooksInstalled,
                    busy: model.isCodebuddyHookSetupBusy,
                    configLocationURL: model.codebuddyHookStatus?.settingsURL,
                    installAction: { model.installCodebuddyHooks() },
                    uninstallAction: { confirmingUninstallCodebuddy = true }
                )
                .alert(lang.t("settings.general.uninstallConfirmTitle"), isPresented: $confirmingUninstallCodebuddy) {
                    Button(lang.t("settings.general.uninstallConfirmAction"), role: .destructive) {
                        model.uninstallCodebuddyHooks()
                    }
                    Button(lang.t("settings.general.cancel"), role: .cancel) {}
                } message: {
                    Text("This will remove Agent Deck hooks from ~/.codebuddy/settings.json.")
                }

                hookRow(
                    name: "Cursor",
                    installed: model.cursorHooksInstalled,
                    busy: model.isCursorHookSetupBusy,
                    requiresBinary: true,
                    configLocationURL: model.cursorHookStatus?.hooksURL,
                    installAction: { model.installCursorHooks() },
                    uninstallAction: { confirmingUninstallCursor = true }
                )
                .alert(lang.t("settings.general.uninstallConfirmTitle"), isPresented: $confirmingUninstallCursor) {
                    Button(lang.t("settings.general.uninstallConfirmAction"), role: .destructive) {
                        model.uninstallCursorHooks()
                    }
                    Button(lang.t("settings.general.cancel"), role: .cancel) {}
                } message: {
                    Text("This will remove the Agent Deck hooks from ~/.cursor/hooks.json.")
                }

                hookRow(
                    name: "Gemini CLI",
                    installed: model.geminiHooksInstalled,
                    busy: model.isGeminiHookSetupBusy,
                    configLocationURL: geminiHookConfigURL,
                    installAction: { model.installGeminiHooks() },
                    uninstallAction: { confirmingUninstallGemini = true }
                )
                .alert(lang.t("settings.general.uninstallConfirmTitle"), isPresented: $confirmingUninstallGemini) {
                    Button(lang.t("settings.general.uninstallConfirmAction"), role: .destructive) {
                        model.uninstallGeminiHooks()
                    }
                    Button(lang.t("settings.general.cancel"), role: .cancel) {}
                } message: {
                    Text("This will remove Agent Deck hooks from ~/.gemini/settings.json.")
                }

                hookRow(
                    name: "CatPaw",
                    installed: model.catPawHooksInstalled,
                    busy: model.isCatPawHookSetupBusy,
                    configLocationURL: model.catPawHookStatus?.hooksURL,
                    installAction: { model.installCatPawHooks() },
                    uninstallAction: { confirmingUninstallCatPaw = true }
                )
                .alert(lang.t("settings.general.uninstallConfirmTitle"), isPresented: $confirmingUninstallCatPaw) {
                    Button(lang.t("settings.general.uninstallConfirmAction"), role: .destructive) {
                        model.uninstallCatPawHooks()
                    }
                    Button(lang.t("settings.general.cancel"), role: .cancel) {}
                } message: {
                    Text("This will remove Agent Deck hooks from CatPaw's global hooks.json.")
                }
            }
            }

            AgentDeckSettingsSection(
                title: lang.t("setup.section.usage"),
                subtitle: lang.t("setup.optional")
            ) {
                VStack(spacing: 8) {
                    AgentDeckSettingsRow(
                        title: lang.t("setup.usageBridge"),
                        subtitle: model.claudeUsageStatusSummary,
                        systemImage: "chart.bar.fill",
                        tint: model.claudeUsageInstalled ? AgentDeckSettingsStyle.green : AgentDeckSettingsStyle.amber
                    ) {
                        HStack(spacing: 8) {
                            if model.claudeUsageInstalled {
                                AgentDeckStatusPill(
                                    text: lang.t("setup.usageBridgeReady"),
                                    tint: AgentDeckSettingsStyle.green,
                                    systemImage: "checkmark.circle.fill"
                                )
                                Button(lang.t("settings.general.uninstall")) {
                                    confirmingUninstallClaudeUsage = true
                                }
                                .buttonStyle(AgentDeckSettingsButtonStyle(kind: .destructive))
                            } else if model.isClaudeUsageSetupBusy {
                                ProgressView().controlSize(.small)
                            } else {
                                Button(lang.t("settings.general.install")) {
                                    model.installClaudeUsageBridge()
                                }
                                .buttonStyle(AgentDeckSettingsButtonStyle(kind: .primary))
                            }
                        }
                    }
                    .alert(lang.t("settings.general.uninstallConfirmTitle"), isPresented: $confirmingUninstallClaudeUsage) {
                        Button(lang.t("settings.general.uninstallConfirmAction"), role: .destructive) {
                            model.uninstallClaudeUsageBridge()
                        }
                        Button(lang.t("settings.general.cancel"), role: .cancel) {}
                    } message: {
                        Text(lang.t("settings.general.uninstallConfirmMessage.claudeUsage"))
                    }

                    AgentDeckSettingsRow(
                        title: lang.t("settings.general.showCodexUsage"),
                        subtitle: model.codexUsageStatusSummary,
                        systemImage: "chart.line.uptrend.xyaxis",
                        tint: .cyan
                    ) {
                        Toggle("", isOn: Binding(
                            get: { model.showCodexUsage },
                            set: { model.showCodexUsage = $0 }
                        ))
                        .toggleStyle(.switch)
                        .labelsHidden()
                    }
                }
            }

            AgentDeckSettingsSection(title: lang.t("setup.section.permissions")) {
                AgentDeckSettingsRow(
                    title: lang.t("setup.permissionsTitle"),
                    subtitle: lang.t("setup.permissionsDesc"),
                    systemImage: "lock.shield.fill",
                    tint: AgentDeckSettingsStyle.amber
                ) {
                    EmptyView()
                }
            }

            hookDiagnosticsSection

            RemoteConnectionSection(model: model)

            AgentDeckSettingsSection(title: "Actions") {
                HStack {
                    Spacer(minLength: 0)
                    Button(lang.t("setup.installAll")) {
                        if !model.claudeHooksInstalled { model.installClaudeHooks() }
                        if !model.codexHooksInstalled { model.installCodexHooks() }
                        if !model.openCodePluginInstalled { model.installOpenCodePlugin() }
                        if !model.qoderHooksInstalled { model.installQoderHooks() }
                        if !model.qwenCodeHooksInstalled { model.installQwenCodeHooks() }
                        if !model.factoryHooksInstalled { model.installFactoryHooks() }
                        if !model.codebuddyHooksInstalled { model.installCodebuddyHooks() }
                        if !model.cursorHooksInstalled { model.installCursorHooks() }
                        if !model.geminiHooksInstalled { model.installGeminiHooks() }
                        if !model.catPawHooksInstalled { model.installCatPawHooks() }
                        if !model.claudeUsageInstalled { model.installClaudeUsageBridge() }
                    }
                    .buttonStyle(AgentDeckSettingsButtonStyle(kind: .primary))
                    .disabled(model.hooksBinaryURL == nil || allReady)
                    Spacer(minLength: 0)
                }
            }
            }
            .padding(.horizontal, 26)
            .padding(.top, 4)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.visible)
        .background(AgentDeckSettingsStyle.background)
    }

    @ViewBuilder
    private var claudeConfigDirectorySection: some View {
        AgentDeckSettingsSection(
            title: lang.t("setup.claudeConfigDir.section"),
            subtitle: lang.t("setup.claudeConfigDir.footer")
        ) {
            AgentDeckSettingsRow(
                title: lang.t("setup.claudeConfigDir.title"),
                subtitle: ClaudeConfigDirectory.resolved().path,
                systemImage: "folder.fill",
                tint: .cyan
            ) {
                HStack(spacing: 8) {
                    if ClaudeConfigDirectory.customDirectory != nil {
                        Button(lang.t("setup.claudeConfigDir.reset")) {
                            model.updateClaudeConfigDirectory(to: nil)
                        }
                        .buttonStyle(AgentDeckSettingsButtonStyle(kind: .secondary))
                    }
                    Button(lang.t("setup.claudeConfigDir.choose")) {
                        let panel = NSOpenPanel()
                        panel.canChooseDirectories = true
                        panel.canChooseFiles = false
                        panel.canCreateDirectories = true
                        panel.prompt = lang.t("setup.claudeConfigDir.choose")
                        if panel.runModal() == .OK, let url = panel.url {
                            model.updateClaudeConfigDirectory(to: url)
                        }
                    }
                    .buttonStyle(AgentDeckSettingsButtonStyle(kind: .primary))
                }
            }
        }
    }

    private var allReady: Bool {
        model.claudeHooksInstalled && model.codexHooksInstalled && model.openCodePluginInstalled
            && model.qoderHooksInstalled && model.qwenCodeHooksInstalled && model.factoryHooksInstalled && model.codebuddyHooksInstalled
            && model.cursorHooksInstalled && model.geminiHooksInstalled && model.catPawHooksInstalled && model.claudeUsageInstalled
    }

    private var codexHookConfigURL: URL? {
        if let hooksURL = model.codexHookStatus?.hooksURL, FileManager.default.fileExists(atPath: hooksURL.path) {
            return hooksURL
        }
        return model.codexHookStatus?.configURL ?? model.codexHookStatus?.hooksURL
    }

    private var geminiHookConfigURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".gemini/settings.json")
    }

    private var hasErrors: Bool {
        let claudeErrors = model.claudeHealthReport?.errors.count ?? 0
        let codexErrors = model.codexHealthReport?.errors.count ?? 0
        return claudeErrors + codexErrors > 0
    }

    private var hasRepairableIssues: Bool {
        let claude = model.claudeHealthReport?.repairableIssues.isEmpty == false
        let codex = model.codexHealthReport?.repairableIssues.isEmpty == false
        return claude || codex
    }

    private var hasNotices: Bool {
        let claude = model.claudeHealthReport?.notices.isEmpty == false
        let codex = model.codexHealthReport?.notices.isEmpty == false
        return claude || codex
    }

    @ViewBuilder
    private var hookDiagnosticsSection: some View {
        AgentDeckSettingsSection(
            title: lang.t("setup.section.diagnostics"),
            subtitle: hasErrors ? nil : (hasNotices ? nil : lang.t("setup.diagnostics.allHealthy"))
        ) {
            VStack(alignment: .leading, spacing: 10) {
            if let claudeReport = model.claudeHealthReport, !claudeReport.issues.isEmpty {
                issueList(report: claudeReport)
            }
            if let codexReport = model.codexHealthReport, !codexReport.issues.isEmpty {
                issueList(report: codexReport)
            }

            if model.claudeHealthReport == nil && model.codexHealthReport == nil {
                HStack {
                    Text(lang.t("setup.diagnostics.notRun"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.52))
                    Spacer()
                    Button(lang.t("setup.diagnostics.runCheck")) {
                        model.runHealthChecks()
                    }
                    .buttonStyle(AgentDeckSettingsButtonStyle(kind: .primary))
                }
            } else if !hasErrors {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AgentDeckSettingsStyle.green)
                    Text(lang.t("setup.diagnostics.allHealthy"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.78))
                    Spacer()
                    Button(lang.t("setup.diagnostics.recheck")) {
                        model.runHealthChecks()
                    }
                    .buttonStyle(AgentDeckSettingsButtonStyle(kind: .secondary))
                }
            } else {
                HStack(spacing: 10) {
                    Spacer(minLength: 0)
                    Button(lang.t("setup.diagnostics.recheck")) {
                        model.runHealthChecks()
                    }
                    .buttonStyle(AgentDeckSettingsButtonStyle(kind: .secondary))

                    if hasRepairableIssues {
                        Button(lang.t("setup.diagnostics.repair")) {
                            model.repairHooks()
                        }
                        .buttonStyle(AgentDeckSettingsButtonStyle(kind: .primary))
                    }
                }
            }
            }
        }
    }

    @ViewBuilder
    private func issueList(report: HookHealthReport) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(report.agent == "claude" ? "Claude Code" : "Codex")
                .font(.departureMono(size: 10))
                .foregroundStyle(.white.opacity(0.46))

            ForEach(Array(report.issues.enumerated()), id: \.offset) { _, issue in
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: issueIcon(for: issue))
                        .font(.caption2)
                        .foregroundStyle(issueColor(for: issue))
                        .frame(width: 14)

                    Text(issue.description)
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(issue.severity == .info ? .white.opacity(0.52) : .white.opacity(0.82))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let binaryPath = report.binaryPath {
                Text("Binary: \(binaryPath)")
                    .font(.departureMono(size: 9))
                    .foregroundStyle(.white.opacity(0.34))
            }
        }
        .padding(10)
        .background(Color.black.opacity(0.25))
        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
    }

    private func issueIcon(for issue: HookHealthReport.Issue) -> String {
        switch issue.severity {
        case .info: "info.circle.fill"
        case .error: issue.isAutoRepairable ? "wrench.fill" : "exclamationmark.triangle.fill"
        }
    }

    private func issueColor(for issue: HookHealthReport.Issue) -> Color {
        switch issue.severity {
        case .info: .blue
        case .error: issue.isAutoRepairable ? .orange : .red
        }
    }

    @ViewBuilder
    private func hookRow(
        name: String,
        installed: Bool,
        busy: Bool,
        requiresBinary: Bool = true,
        configLocationURL: URL? = nil,
        installAction: @escaping () -> Void,
        uninstallAction: @escaping () -> Void
    ) -> some View {
        AgentDeckSettingsRow(
            title: name,
            subtitle: configLocationURL?.path ?? (installed ? lang.t("setup.hookReady") : lang.t("setup.hookMissing")),
            systemImage: hookIcon(for: name),
            tint: installed ? AgentDeckSettingsStyle.green : AgentDeckSettingsStyle.amber
        ) {
            if installed {
                HStack(spacing: 8) {
                    if let configLocationURL {
                        Button {
                            revealInFinder(configLocationURL)
                        } label: {
                            Image(systemName: "arrow.up.forward.square")
                        }
                        .buttonStyle(AgentDeckSettingsButtonStyle(kind: .secondary))
                        .help(lang.t("setup.revealConfigLocation"))
                    }
                    AgentDeckStatusPill(
                        text: lang.t("settings.general.activated"),
                        tint: AgentDeckSettingsStyle.green,
                        systemImage: "checkmark.circle.fill"
                    )
                    Button(lang.t("settings.general.uninstall")) {
                        uninstallAction()
                    }
                    .buttonStyle(AgentDeckSettingsButtonStyle(kind: .destructive))
                }
            } else if busy {
                ProgressView().controlSize(.small)
            } else {
                Button(lang.t("settings.general.install")) {
                    installAction()
                }
                .disabled(requiresBinary && model.hooksBinaryURL == nil)
                .buttonStyle(AgentDeckSettingsButtonStyle(kind: .primary))
            }
        }
    }

    private func hookIcon(for name: String) -> String {
        switch name {
        case "Cursor": "cursorarrow.click.2"
        case "OpenCode": "curlybraces"
        case "Gemini CLI": "sparkles"
        default: "terminal.fill"
        }
    }

    private func revealInFinder(_ url: URL) {
        let fileManager = FileManager.default
        let standardizedURL = url.standardizedFileURL

        if fileManager.fileExists(atPath: standardizedURL.path) {
            NSWorkspace.shared.activateFileViewerSelecting([standardizedURL])
            return
        }

        let directoryURL = standardizedURL.deletingLastPathComponent()
        if fileManager.fileExists(atPath: directoryURL.path) {
            NSWorkspace.shared.open(directoryURL)
        }
    }
}

// MARK: - Remote Connection

struct RemoteConnectionSection: View {
    var model: AppModel

    @State private var copiedCommand: String?

    private var remoteSessionCount: Int {
        model.state.sessions.filter(\.isRemote).count
    }

    private var socketName: String {
        "agent-deck-\(getuid()).sock"
    }

    private var setupCommand: String {
        "./scripts/remote-setup.sh user@host"
    }

    private var sshCommand: String {
        "ssh -R /tmp/\(socketName):/tmp/\(socketName) user@host"
    }

    private var sshConfigSnippet: String {
        """
        Host myserver
            RemoteForward /tmp/\(socketName) /tmp/\(socketName)
        """
    }

    var body: some View {
        AgentDeckSettingsSection(
            title: "Remote",
            subtitle: "Monitor Claude Code running on remote servers via SSH."
        ) {
            VStack(alignment: .leading, spacing: 12) {
                AgentDeckSettingsRow(
                    title: "SSH Remote",
                    subtitle: remoteSessionCount > 0 ? "\(remoteSessionCount) active remote sessions" : "No remote sessions",
                    systemImage: "network",
                    tint: remoteSessionCount > 0 ? AgentDeckSettingsStyle.green : .cyan
                ) {
                    AgentDeckStatusPill(
                        text: remoteSessionCount > 0 ? "\(remoteSessionCount) active" : "Beta",
                        tint: remoteSessionCount > 0 ? AgentDeckSettingsStyle.green : .cyan,
                        systemImage: remoteSessionCount > 0 ? "dot.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right"
                    )
                }

                // Step 1
                remoteSetupStep(
                    number: "1",
                    title: "Deploy hooks to remote server",
                    description: "Run from the Agent Deck repo directory:",
                    command: setupCommand
                )

                // Step 2
                remoteSetupStep(
                    number: "2",
                    title: "Connect with socket forwarding",
                    description: "Add to ~/.ssh/config (recommended):",
                    command: sshConfigSnippet,
                    multiline: true
                )

                // Step 2 alternative
                VStack(alignment: .leading, spacing: 4) {
                    Text("Or connect directly:")
                        .font(.system(size: 10.5))
                        .foregroundStyle(.tertiary)
                    copyableCommand(sshCommand)
                }

                // Tip
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 10))
                        .foregroundStyle(.cyan.opacity(0.8))
                        .padding(.top, 1)
                    Text("The remote sshd needs `StreamLocalBindUnlink yes` in /etc/ssh/sshd_config for reliable reconnects.")
                        .font(.system(size: 10.5))
                        .foregroundStyle(.white.opacity(0.48))
                }
            }
        }
    }

    @ViewBuilder
    private func remoteSetupStep(
        number: String,
        title: String,
        description: String,
        command: String,
        multiline: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(number)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                    .frame(width: 16, height: 16)
                    .background(RoundedRectangle(cornerRadius: 4, style: .continuous).fill(AgentDeckSettingsStyle.green))
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.82))
            }
            Text(description)
                .font(.system(size: 10.5))
                .foregroundStyle(.white.opacity(0.46))
            copyableCommand(command, multiline: multiline)
        }
    }

    @ViewBuilder
    private func copyableCommand(_ command: String, multiline: Bool = false) -> some View {
        let isCopied = copiedCommand == command
        HStack(alignment: multiline ? .top : .center) {
                Text(command)
                    .font(.departureMono(size: 10))
                    .foregroundStyle(.white.opacity(0.78))
                    .lineLimit(multiline ? nil : 1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
                Spacer(minLength: 8)
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(command, forType: .string)
                    copiedCommand = command
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        if copiedCommand == command {
                            copiedCommand = nil
                        }
                    }
                } label: {
                    Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 10))
                        .foregroundStyle(isCopied ? AgentDeckSettingsStyle.green : .white.opacity(0.45))
                }
                .buttonStyle(.plain)
            }
        .padding(10)
        .background(Color.black.opacity(0.36))
        .overlay(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .strokeBorder(Color.white.opacity(0.07))
        )
        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
    }
}
