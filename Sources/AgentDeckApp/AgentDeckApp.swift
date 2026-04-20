import AppKit
import SwiftUI

@MainActor
final class AgentDeckAppDelegate: NSObject, NSApplicationDelegate {
    let model = AppModel()
    private let harnessLaunchConfiguration = HarnessLaunchConfiguration()
    private let launchedAt = Date()
    private lazy var harnessRuntimeMonitor = HarnessRuntimeMonitor(launchedAt: launchedAt)
    private var controlCenterWindowController: ControlCenterWindowController?
    private var settingsWindowController: NSWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        DepartureMono.registerBundledFont()
        ProcessInfo.processInfo.disableAutomaticTermination(
            "Agent Deck should remain active while monitoring local agent sessions."
        )
        ProcessInfo.processInfo.disableSuddenTermination()
        NSApp.setActivationPolicy(model.showDockIcon ? .regular : .accessory)
        harnessRuntimeMonitor.recordMilestone("applicationDidFinishLaunching")

        DispatchQueue.main.async { [self] in
            harnessRuntimeMonitor.recordMilestone("bootstrapStarted")
            model.harnessRuntimeMonitor = harnessRuntimeMonitor
            model.openSettingsWindow = { [weak self] in
                self?.showSettingsWindow()
            }
            model.openControlCenterWindow = { [weak self] in
                self?.showControlCenterWindow()
            }
            harnessRuntimeMonitor.recordLog(model.lastActionMessage)

            model.ignoresPointerExitDuringHarness = harnessLaunchConfiguration.scenario != nil
            model.disablesOverlayEventMonitoringDuringHarness = harnessLaunchConfiguration.scenario != nil
            model.startIfNeeded(
                startBridge: harnessLaunchConfiguration.shouldStartBridge,
                shouldPerformBootAnimation: harnessLaunchConfiguration.shouldPerformBootAnimation,
                loadRuntimeState: harnessLaunchConfiguration.scenario == nil
            )
            harnessRuntimeMonitor.recordMilestone("modelStarted")

            // Hide any restored app windows before loading harness snapshots so
            // closed overlay captures still keep the notch panel visible.
            AgentDeckAppDelegate.hideAllAppWindows()

            if let scenario = harnessLaunchConfiguration.scenario {
                model.loadDebugSnapshot(
                    scenario.snapshot(),
                    presentOverlay: harnessLaunchConfiguration.presentOverlay
                )
            }

            if harnessLaunchConfiguration.shouldShowControlCenter,
               harnessLaunchConfiguration.scenario != nil {
                model.showControlCenter()
                harnessRuntimeMonitor.recordMilestone("controlCenterConfigured", message: "shown")
            } else {
                harnessRuntimeMonitor.recordMilestone("controlCenterConfigured", message: "hidden")
            }

            var didShowSettingsWindow = false
            if harnessLaunchConfiguration.shouldShowSettings {
                showSettingsWindow(initialTab: harnessSettingsTab)
                didShowSettingsWindow = true
                harnessRuntimeMonitor.recordMilestone("settingsConfigured", message: "shown")
            }

            if !didShowSettingsWindow,
               harnessLaunchConfiguration.artifactDirectoryURL == nil,
               harnessLaunchConfiguration.scenario == nil,
               model.shouldShowInitialSettings {
                showSettingsWindow(initialTab: .setup)
                model.markInitialSettingsShown()
                harnessRuntimeMonitor.recordMilestone("settingsConfigured", message: "initial")
            }

            harnessRuntimeMonitor.recordMilestone("bootstrapCompleted")

            if let captureDelay = harnessLaunchConfiguration.captureDelay,
               harnessLaunchConfiguration.artifactDirectoryURL != nil {
                harnessRuntimeMonitor.recordMilestone(
                    "captureScheduled",
                    message: String(format: "%.3fs", captureDelay)
                )
                DispatchQueue.main.asyncAfter(deadline: .now() + captureDelay) { [self] in
                    harnessRuntimeMonitor.recordMilestone("captureStarted")
                    try? HarnessArtifactRecorder.record(
                        configuration: harnessLaunchConfiguration,
                        model: model,
                        launchedAt: launchedAt,
                        runtimeMonitor: harnessRuntimeMonitor
                    )
                }
            }

            if let autoExitAfter = harnessLaunchConfiguration.autoExitAfter {
                harnessRuntimeMonitor.recordMilestone(
                    "autoExitScheduled",
                    message: String(format: "%.3fs", autoExitAfter)
                )
                DispatchQueue.main.asyncAfter(deadline: .now() + autoExitAfter) {
                    NSApp.terminate(nil)
                }
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private static func hideAllAppWindows() {
        for window in NSApp.windows where !window.className.contains("MenuBarExtra") {
            window.orderOut(nil)
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        model.showSettings()
        return false
    }

    private var harnessSettingsTab: SettingsTab {
        guard let rawValue = harnessLaunchConfiguration.settingsTabRawValue,
              let tab = SettingsTab(rawValue: rawValue) else {
            return .general
        }
        return tab
    }

    private func showSettingsWindow(initialTab: SettingsTab = .general) {
        if let window = settingsWindowController?.window {
            window.orderFrontRegardless()
            window.makeKey()
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let hostingController = NSHostingController(rootView: SettingsView(model: model, initialTab: initialTab))
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 640),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Agent Deck Settings"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.backgroundColor = .black
        window.contentViewController = hostingController
        window.center()
        window.setFrameAutosaveName("AgentDeckSettingsWindow")

        let controller = NSWindowController(window: window)
        settingsWindowController = controller
        controller.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func showControlCenterWindow() {
        let controller = controlCenterWindowController ?? ControlCenterWindowController(model: model)
        controlCenterWindowController = controller
        controller.show()
    }
}

@main
struct AgentDeckApp: App {
    @NSApplicationDelegateAdaptor(AgentDeckAppDelegate.self)
    private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView(model: appDelegate.model)
        } label: {
            MenuBarBearIcon(size: 18)
                .accessibilityLabel("Agent Deck")
        }
        .menuBarExtraStyle(.window)
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Settings…") {
                    appDelegate.model.showSettings()
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}
