import Foundation
import Testing
@testable import AgentDeckCore

struct CatPawHooksTests {
    @Test
    func catPawHookPayloadDecodesFromJSON() throws {
        let json = """
        {
            "hook_event_name": "beforeSubmitPrompt",
            "conversation_id": "conv-123",
            "suggest_uuid": "suggest-456",
            "model": "catpaw-model",
            "workspace_roots": ["/Users/test/project"],
            "mis": "xilong",
            "agent_name": "CatPaw",
            "is_sub_agent": false,
            "prompt": "Fix the failing test",
            "attachments": [
                { "type": "file", "file_path": "Sources/App.swift" }
            ]
        }
        """.data(using: .utf8)!

        let payload = try JSONDecoder().decode(CatPawHookPayload.self, from: json)

        #expect(payload.hookEventName == .beforeSubmitPrompt)
        #expect(payload.conversationId == "conv-123")
        #expect(payload.suggestUuid == "suggest-456")
        #expect(payload.workspaceRoots == ["/Users/test/project"])
        #expect(payload.mis == "xilong")
        #expect(payload.agentName == "CatPaw")
        #expect(payload.prompt == "Fix the failing test")
        #expect(payload.attachments?.first?.filePath == "Sources/App.swift")
        #expect(payload.sessionID == "conv-123")
        #expect(payload.defaultJumpTarget.terminalApp == "CatPaw")
        #expect(payload.defaultCatPawMetadata.lastUserPrompt == "Fix the failing test")
    }

    @Test
    func catPawHookOutputEncoderWritesOnlyForBlockingHooksAndStop() throws {
        let rawBeforeOutput = try CatPawHookOutputEncoder.standardOutput(
            for: .catPawHookDirective(.allow),
            hookEventName: .beforeShellExecution
        )
        let beforeOutput = try #require(rawBeforeOutput)
        let beforeObject = try JSONSerialization.jsonObject(with: beforeOutput) as! [String: Any]
        #expect(beforeObject["continue"] as? Bool == true)

        let rawStopOutput = try CatPawHookOutputEncoder.standardOutput(for: nil, hookEventName: .stop)
        let stopOutput = try #require(rawStopOutput)
        let stopObject = try JSONSerialization.jsonObject(with: stopOutput) as! [String: Any]
        #expect(stopObject["followup_message"] as? String == "")
        #expect(stopObject["continue"] == nil)

        let afterOutput = try CatPawHookOutputEncoder.standardOutput(
            for: .acknowledged,
            hookEventName: .afterShellExecution
        )
        #expect(afterOutput == nil)
    }

    @Test
    func catPawHookInstallerInstallsAllEventsIntoEmptyFile() throws {
        let mutation = try CatPawHookInstaller.installHooksJSON(
            existingData: nil,
            hookCommand: "/usr/local/bin/AgentDeckHooks --source catpaw"
        )

        #expect(mutation.changed)
        #expect(mutation.managedHooksPresent)

        let data = try #require(mutation.contents)
        let object = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let hooks = object["hooks"] as! [String: Any]

        #expect(hooks.keys.count == CatPawHookEventName.allCases.count)
        #expect(hooks.keys.contains("beforeShellExecution"))
        #expect(hooks.keys.contains("afterAgentThought"))
        #expect(hooks.keys.contains("stop"))

        let shellEntries = hooks["beforeShellExecution"] as! [[String: Any]]
        #expect(shellEntries.count == 1)
        #expect(shellEntries[0]["command"] as? String == "/usr/local/bin/AgentDeckHooks --source catpaw")
    }

    @Test
    func catPawHookInstallerPreservesExistingHooks() throws {
        let existing = """
        {
            "hooks": {
                "beforeShellExecution": [
                    { "command": "/usr/local/bin/custom-catpaw-hook" }
                ]
            }
        }
        """.data(using: .utf8)!

        let mutation = try CatPawHookInstaller.installHooksJSON(
            existingData: existing,
            hookCommand: "/usr/local/bin/AgentDeckHooks --source catpaw"
        )

        let data = try #require(mutation.contents)
        let object = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let hooks = object["hooks"] as! [String: Any]
        let shellEntries = hooks["beforeShellExecution"] as! [[String: Any]]

        #expect(shellEntries.count == 2)
        #expect(shellEntries[0]["command"] as? String == "/usr/local/bin/custom-catpaw-hook")
        #expect(shellEntries[1]["command"] as? String == "/usr/local/bin/AgentDeckHooks --source catpaw")
    }

    @Test
    func catPawHookInstallerUninstallsManagedHooksOnly() throws {
        let installed = try CatPawHookInstaller.installHooksJSON(
            existingData: nil,
            hookCommand: "/usr/local/bin/AgentDeckHooks --source catpaw"
        )

        let uninstalled = try CatPawHookInstaller.uninstallHooksJSON(
            existingData: installed.contents,
            managedCommand: "/usr/local/bin/AgentDeckHooks --source catpaw"
        )

        #expect(uninstalled.changed)
        #expect(uninstalled.managedHooksPresent)
        #expect(uninstalled.contents == nil)
    }

    @Test
    func catPawHookInstallationManagerRoundTripsInstallAndUninstall() throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("agent-deck-catpaw-hooks-\(UUID().uuidString)", isDirectory: true)
        let settingsDirectory = rootURL.appendingPathComponent("settings", isDirectory: true)
        let managedHooksBinaryURL = rootURL
            .appendingPathComponent("managed", isDirectory: true)
            .appendingPathComponent("AgentDeckHooks")
        let hooksBinaryURL = rootURL
            .appendingPathComponent("build", isDirectory: true)
            .appendingPathComponent("AgentDeckHooks")
        let manager = CatPawHookInstallationManager(
            catPawSettingsDirectory: settingsDirectory,
            managedHooksBinaryURL: managedHooksBinaryURL
        )

        defer {
            try? FileManager.default.removeItem(at: rootURL)
        }

        try FileManager.default.createDirectory(at: hooksBinaryURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("catpaw-hook".utf8).write(to: hooksBinaryURL)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: hooksBinaryURL.path)

        let installStatus = try manager.install(hooksBinaryURL: hooksBinaryURL)
        #expect(installStatus.managedHooksPresent)
        #expect(FileManager.default.fileExists(atPath: settingsDirectory.appendingPathComponent("hooks.json").path))
        #expect(FileManager.default.fileExists(
            atPath: settingsDirectory.appendingPathComponent(CatPawHookInstallerManifest.fileName).path
        ))

        let hooksData = try Data(contentsOf: settingsDirectory.appendingPathComponent("hooks.json"))
        let hooksObject = try JSONSerialization.jsonObject(with: hooksData) as! [String: Any]
        let hooks = hooksObject["hooks"] as! [String: Any]
        #expect(hooks.keys.count == CatPawHookEventName.allCases.count)

        let uninstallStatus = try manager.uninstall()
        #expect(!uninstallStatus.managedHooksPresent)
        #expect(!FileManager.default.fileExists(
            atPath: settingsDirectory.appendingPathComponent(CatPawHookInstallerManifest.fileName).path
        ))
    }

    @Test
    func catPawAfterAgentResponseKeepsSessionRunning() async throws {
        let socketURL = BridgeSocketLocation.uniqueTestURL()
        let server = BridgeServer(socketURL: socketURL)
        try server.start()
        defer { server.stop() }

        let observer = LocalBridgeClient(socketURL: socketURL)
        let stream = try observer.connect()
        defer { observer.disconnect() }
        try await observer.send(.registerClient(role: .observer))

        let payload = CatPawHookPayload(
            hookEventName: .afterAgentResponse,
            conversationId: "catpaw-session-1",
            suggestUuid: "suggest-1",
            model: "catpaw-model",
            workspaceRoots: ["/tmp/worktree"],
            text: "Done with the CatPaw task."
        )

        let response = try BridgeCommandClient(socketURL: socketURL).send(.processCatPawHook(payload))
        #expect(response == .acknowledged)

        var iterator = stream.makeAsyncIterator()
        let event = try await nextMatchingCatPawEvent(from: &iterator, maxEvents: 8) { event in
            if case .activityUpdated = event {
                return true
            }
            return false
        }

        guard case let .activityUpdated(payload) = event else {
            Issue.record("Expected CatPaw running activity update")
            return
        }

        #expect(payload.sessionID == "catpaw-session-1")
        #expect(payload.summary == "Done with the CatPaw task.")
        #expect(payload.phase == .running)
    }

    @Test
    func catPawStopCompletesSession() async throws {
        let socketURL = BridgeSocketLocation.uniqueTestURL()
        let server = BridgeServer(socketURL: socketURL)
        try server.start()
        defer { server.stop() }

        let observer = LocalBridgeClient(socketURL: socketURL)
        let stream = try observer.connect()
        defer { observer.disconnect() }
        try await observer.send(.registerClient(role: .observer))

        let payload = CatPawHookPayload(
            hookEventName: .stop,
            conversationId: "catpaw-session-1",
            suggestUuid: "suggest-1",
            model: "catpaw-model",
            workspaceRoots: ["/tmp/worktree"],
            status: "completed"
        )

        let response = try BridgeCommandClient(socketURL: socketURL).send(.processCatPawHook(payload))
        #expect(response == .catPawHookDirective(CatPawHookDirective(continue: nil, followupMessage: "")))

        var iterator = stream.makeAsyncIterator()
        let event = try await nextMatchingCatPawEvent(from: &iterator, maxEvents: 8) { event in
            if case .sessionCompleted = event {
                return true
            }
            return false
        }

        guard case let .sessionCompleted(payload) = event else {
            Issue.record("Expected CatPaw session completion")
            return
        }

        #expect(payload.sessionID == "catpaw-session-1")
        #expect(payload.summary == "CatPaw completed the turn.")
    }

    @Test
    func catPawLateAfterAgentResponseDoesNotReopenCompletedSessionAfterStaleSnapshot() async throws {
        let socketURL = BridgeSocketLocation.uniqueTestURL()
        let server = BridgeServer(socketURL: socketURL)
        try server.start()
        defer { server.stop() }

        let observer = LocalBridgeClient(socketURL: socketURL)
        let stream = try observer.connect()
        defer { observer.disconnect() }
        try await observer.send(.registerClient(role: .observer))

        let sessionID = "catpaw-session-late-response"
        let startPayload = CatPawHookPayload(
            hookEventName: .beforeSubmitPrompt,
            conversationId: sessionID,
            suggestUuid: "suggest-late",
            model: "catpaw-model",
            workspaceRoots: ["/tmp/worktree"],
            prompt: "Finish the task"
        )
        let stopPayload = CatPawHookPayload(
            hookEventName: .stop,
            conversationId: sessionID,
            suggestUuid: "suggest-late",
            model: "catpaw-model",
            workspaceRoots: ["/tmp/worktree"],
            status: "completed"
        )

        _ = try BridgeCommandClient(socketURL: socketURL).send(.processCatPawHook(startPayload))
        _ = try BridgeCommandClient(socketURL: socketURL).send(.processCatPawHook(stopPayload))

        var iterator = stream.makeAsyncIterator()
        _ = try await nextMatchingCatPawEvent(from: &iterator, maxEvents: 8) { event in
            if case let .sessionCompleted(payload) = event {
                return payload.sessionID == sessionID
            }
            return false
        }

        let staleRunningSession = AgentSession(
            id: sessionID,
            title: "CatPaw · worktree",
            tool: .catPaw,
            origin: .live,
            attachmentState: .attached,
            phase: .running,
            summary: "Stale running update",
            updatedAt: .now,
            catPawMetadata: CatPawSessionMetadata(
                conversationId: sessionID,
                suggestUuid: "suggest-late",
                workspaceRoots: ["/tmp/worktree"],
                lastUserPrompt: "Finish the task",
                model: "catpaw-model"
            )
        )
        server.updateStateSnapshot(SessionState(sessions: [staleRunningSession]))

        let flushPrompt = QuestionPrompt(title: "flush", options: ["ok"])
        _ = try BridgeCommandClient(socketURL: socketURL).send(
            .requestQuestion(sessionID: "missing-catpaw-session", prompt: flushPrompt)
        )

        let lateResponsePayload = CatPawHookPayload(
            hookEventName: .afterAgentResponse,
            conversationId: sessionID,
            suggestUuid: "suggest-late",
            model: "catpaw-model",
            workspaceRoots: ["/tmp/worktree"],
            text: "Final answer arrived after stop."
        )
        let lateResponse = try BridgeCommandClient(socketURL: socketURL).send(.processCatPawHook(lateResponsePayload))
        #expect(lateResponse == .acknowledged)

        let sentinelPayload = CatPawHookPayload(
            hookEventName: .beforeSubmitPrompt,
            conversationId: "catpaw-sentinel-session",
            suggestUuid: "suggest-sentinel",
            model: "catpaw-model",
            workspaceRoots: ["/tmp/worktree"],
            prompt: "Sentinel prompt"
        )
        _ = try BridgeCommandClient(socketURL: socketURL).send(.processCatPawHook(sentinelPayload))

        var sawLateMetadata = false
        for _ in 0..<8 {
            guard let event = try await iterator.next() else {
                break
            }

            switch event {
            case let .activityUpdated(payload) where payload.sessionID == sessionID:
                Issue.record("Late CatPaw afterAgentResponse should not reopen a completed session.")
                return
            case let .catPawSessionMetadataUpdated(payload) where payload.sessionID == sessionID:
                sawLateMetadata = payload.catPawMetadata.lastAssistantMessage == "Final answer arrived after stop."
            case let .sessionStarted(payload) where payload.sessionID == "catpaw-sentinel-session":
                #expect(sawLateMetadata)
                return
            default:
                continue
            }
        }

        Issue.record("Expected sentinel event after late CatPaw response.")
    }
}

private func nextMatchingCatPawEvent(
    from iterator: inout AsyncThrowingStream<AgentEvent, Error>.AsyncIterator,
    maxEvents: Int = 8,
    predicate: (AgentEvent) -> Bool
) async throws -> AgentEvent {
    for _ in 0..<maxEvents {
        guard let event = try await iterator.next() else {
            break
        }
        if predicate(event) {
            return event
        }
    }

    Issue.record("Expected matching event within \(maxEvents) events")
    throw CancellationError()
}
