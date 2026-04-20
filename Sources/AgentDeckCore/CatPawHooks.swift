import Foundation

public enum CatPawHookEventName: String, Codable, Sendable, CaseIterable {
    case beforeShellExecution
    case afterShellExecution
    case beforeMCPExecution
    case afterMCPExecution
    case beforeReadFile
    case afterFileEdit
    case beforeSubmitPrompt
    case stop
    case afterAgentResponse
    case afterAgentThought

    public var isBeforeHook: Bool {
        switch self {
        case .beforeShellExecution, .beforeMCPExecution, .beforeReadFile, .beforeSubmitPrompt:
            true
        case .afterShellExecution, .afterMCPExecution, .afterFileEdit, .stop, .afterAgentResponse, .afterAgentThought:
            false
        }
    }
}

public struct CatPawAttachment: Equatable, Codable, Sendable {
    public var type: String?
    public var filePath: String?

    public init(type: String? = nil, filePath: String? = nil) {
        self.type = type
        self.filePath = filePath
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case filePath = "file_path"
    }
}

public struct CatPawHookPayload: Equatable, Codable, Sendable {
    public var hookEventName: CatPawHookEventName
    public var conversationId: String
    public var suggestUuid: String
    public var model: String?
    public var workspaceRoots: [String]
    public var mis: String?
    public var agentName: String?
    public var isSubAgent: Bool

    public var command: String?
    public var cwd: String?
    public var output: String?
    public var duration: Double?
    public var toolName: String?
    public var toolInput: String?
    public var url: String?
    public var resultJSON: String?
    public var filePath: String?
    public var edits: CatPawHookJSONValue?
    public var prompt: String?
    public var attachments: [CatPawAttachment]?
    public var status: String?
    public var loopCount: Int?
    public var text: String?

    private enum CodingKeys: String, CodingKey {
        case hookEventName = "hook_event_name"
        case conversationId = "conversation_id"
        case suggestUuid = "suggest_uuid"
        case model
        case workspaceRoots = "workspace_roots"
        case mis
        case agentName = "agent_name"
        case isSubAgent = "is_sub_agent"
        case command
        case cwd
        case output
        case duration
        case toolName = "tool_name"
        case toolInput = "tool_input"
        case url
        case resultJSON = "result_json"
        case filePath = "file_path"
        case edits
        case prompt
        case attachments
        case status
        case loopCount = "loop_count"
        case text
    }

    public init(
        hookEventName: CatPawHookEventName,
        conversationId: String,
        suggestUuid: String,
        model: String? = nil,
        workspaceRoots: [String] = [],
        mis: String? = nil,
        agentName: String? = nil,
        isSubAgent: Bool = false,
        command: String? = nil,
        cwd: String? = nil,
        output: String? = nil,
        duration: Double? = nil,
        toolName: String? = nil,
        toolInput: String? = nil,
        url: String? = nil,
        resultJSON: String? = nil,
        filePath: String? = nil,
        edits: CatPawHookJSONValue? = nil,
        prompt: String? = nil,
        attachments: [CatPawAttachment]? = nil,
        status: String? = nil,
        loopCount: Int? = nil,
        text: String? = nil
    ) {
        self.hookEventName = hookEventName
        self.conversationId = conversationId
        self.suggestUuid = suggestUuid
        self.model = model
        self.workspaceRoots = workspaceRoots
        self.mis = mis
        self.agentName = agentName
        self.isSubAgent = isSubAgent
        self.command = command
        self.cwd = cwd
        self.output = output
        self.duration = duration
        self.toolName = toolName
        self.toolInput = toolInput
        self.url = url
        self.resultJSON = resultJSON
        self.filePath = filePath
        self.edits = edits
        self.prompt = prompt
        self.attachments = attachments
        self.status = status
        self.loopCount = loopCount
        self.text = text
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.hookEventName = try container.decode(CatPawHookEventName.self, forKey: .hookEventName)

        let decodedConversationId = try container.decodeIfPresent(String.self, forKey: .conversationId)
        let decodedSuggestUuid = try container.decodeIfPresent(String.self, forKey: .suggestUuid)
        self.conversationId = decodedConversationId ?? decodedSuggestUuid ?? UUID().uuidString
        self.suggestUuid = decodedSuggestUuid ?? self.conversationId

        self.model = try container.decodeIfPresent(String.self, forKey: .model)
        self.workspaceRoots = (try? container.decodeIfPresent([String].self, forKey: .workspaceRoots)) ?? []
        self.mis = try container.decodeIfPresent(String.self, forKey: .mis)
        self.agentName = try container.decodeIfPresent(String.self, forKey: .agentName)
        self.isSubAgent = (try? container.decodeIfPresent(Bool.self, forKey: .isSubAgent)) ?? false
        self.command = try container.decodeIfPresent(String.self, forKey: .command)
        self.cwd = try container.decodeIfPresent(String.self, forKey: .cwd)
        self.output = try container.decodeIfPresent(String.self, forKey: .output)
        self.duration = try container.decodeIfPresent(Double.self, forKey: .duration)
        self.toolName = try container.decodeIfPresent(String.self, forKey: .toolName)
        self.toolInput = try container.decodeIfPresent(String.self, forKey: .toolInput)
        self.url = try container.decodeIfPresent(String.self, forKey: .url)
        self.resultJSON = try container.decodeIfPresent(String.self, forKey: .resultJSON)
        self.filePath = try container.decodeIfPresent(String.self, forKey: .filePath)
        self.edits = try container.decodeIfPresent(CatPawHookJSONValue.self, forKey: .edits)
        self.prompt = try container.decodeIfPresent(String.self, forKey: .prompt)
        self.attachments = try container.decodeIfPresent([CatPawAttachment].self, forKey: .attachments)
        self.status = try container.decodeIfPresent(String.self, forKey: .status)
        self.loopCount = try container.decodeIfPresent(Int.self, forKey: .loopCount)
        self.text = try container.decodeIfPresent(String.self, forKey: .text)
    }
}

public struct CatPawHookDirective: Equatable, Codable, Sendable {
    public var `continue`: Bool?
    public var userMessage: String?
    public var agentMessage: String?
    public var followupMessage: String?

    public init(
        `continue`: Bool? = true,
        userMessage: String? = nil,
        agentMessage: String? = nil,
        followupMessage: String? = nil
    ) {
        self.`continue` = `continue`
        self.userMessage = userMessage
        self.agentMessage = agentMessage
        self.followupMessage = followupMessage
    }

    public static var allow: CatPawHookDirective {
        CatPawHookDirective(continue: true)
    }

    private enum CodingKeys: String, CodingKey {
        case `continue`
        case userMessage = "user_message"
        case agentMessage = "agent_message"
        case followupMessage = "followup_message"
    }
}

public enum CatPawHookOutputEncoder {
    public static func standardOutput(
        for response: BridgeResponse?,
        hookEventName: CatPawHookEventName
    ) throws -> Data? {
        switch hookEventName {
        case .beforeShellExecution, .beforeMCPExecution, .beforeReadFile, .beforeSubmitPrompt:
            let directive: CatPawHookDirective
            if case let .catPawHookDirective(responseDirective) = response {
                directive = responseDirective
            } else {
                directive = .allow
            }
            return try encode(directive)

        case .stop:
            let directive: CatPawHookDirective
            if case let .catPawHookDirective(responseDirective) = response {
                directive = responseDirective
            } else {
                directive = CatPawHookDirective(continue: nil, followupMessage: "")
            }
            return try encode(directive)

        case .afterShellExecution, .afterMCPExecution, .afterFileEdit, .afterAgentResponse, .afterAgentThought:
            return nil
        }
    }

    private static func encode(_ directive: CatPawHookDirective) throws -> Data {
        let encoder = JSONEncoder()
        var data = try encoder.encode(directive)
        data.append(UInt8(ascii: "\n"))
        return data
    }
}

public struct CatPawSessionMetadata: Equatable, Codable, Sendable {
    public var conversationId: String?
    public var suggestUuid: String?
    public var workspaceRoots: [String]?
    public var initialUserPrompt: String?
    public var lastUserPrompt: String?
    public var lastAssistantMessage: String?
    public var currentTool: String?
    public var currentToolInputPreview: String?
    public var currentCommandPreview: String?
    public var model: String?
    public var agentName: String?
    public var mis: String?

    public init(
        conversationId: String? = nil,
        suggestUuid: String? = nil,
        workspaceRoots: [String]? = nil,
        initialUserPrompt: String? = nil,
        lastUserPrompt: String? = nil,
        lastAssistantMessage: String? = nil,
        currentTool: String? = nil,
        currentToolInputPreview: String? = nil,
        currentCommandPreview: String? = nil,
        model: String? = nil,
        agentName: String? = nil,
        mis: String? = nil
    ) {
        self.conversationId = conversationId
        self.suggestUuid = suggestUuid
        self.workspaceRoots = workspaceRoots
        self.initialUserPrompt = initialUserPrompt
        self.lastUserPrompt = lastUserPrompt
        self.lastAssistantMessage = lastAssistantMessage
        self.currentTool = currentTool
        self.currentToolInputPreview = currentToolInputPreview
        self.currentCommandPreview = currentCommandPreview
        self.model = model
        self.agentName = agentName
        self.mis = mis
    }

    public var isEmpty: Bool {
        conversationId == nil
            && suggestUuid == nil
            && workspaceRoots == nil
            && initialUserPrompt == nil
            && lastUserPrompt == nil
            && lastAssistantMessage == nil
            && currentTool == nil
            && currentToolInputPreview == nil
            && currentCommandPreview == nil
            && model == nil
            && agentName == nil
            && mis == nil
    }
}

public typealias CatPawHookJSONValue = CodexHookJSONValue

public extension CatPawHookPayload {
    var primaryWorkspaceRoot: String {
        workspaceRoots.first ?? cwd ?? "Unknown"
    }

    var workspaceName: String {
        WorkspaceNameResolver.workspaceName(for: primaryWorkspaceRoot)
    }

    var sessionID: String {
        conversationId
    }

    var sessionTitle: String {
        "CatPaw · \(workspaceName)"
    }

    var defaultJumpTarget: JumpTarget {
        JumpTarget(
            terminalApp: "CatPaw",
            workspaceName: workspaceName,
            paneTitle: "CatPaw \(conversationId.prefix(8))",
            workingDirectory: primaryWorkspaceRoot
        )
    }

    var defaultCatPawMetadata: CatPawSessionMetadata {
        CatPawSessionMetadata(
            conversationId: conversationId,
            suggestUuid: suggestUuid,
            workspaceRoots: workspaceRoots.isEmpty ? nil : workspaceRoots,
            initialUserPrompt: promptPreview,
            lastUserPrompt: promptPreview,
            lastAssistantMessage: assistantTextPreview,
            currentTool: currentToolName,
            currentToolInputPreview: toolInputPreview,
            currentCommandPreview: commandPreview,
            model: model,
            agentName: agentName,
            mis: mis
        )
    }

    var currentToolName: String? {
        switch hookEventName {
        case .beforeShellExecution, .afterShellExecution:
            return "Shell"
        case .beforeMCPExecution, .afterMCPExecution:
            return toolName ?? "MCP"
        case .beforeReadFile:
            return "Read"
        case .afterFileEdit:
            return "Edit"
        case .afterAgentThought:
            return "Thought"
        case .beforeSubmitPrompt, .stop, .afterAgentResponse:
            return nil
        }
    }

    var implicitStartSummary: String {
        switch hookEventName {
        case .beforeSubmitPrompt:
            return "CatPaw received a new prompt in \(workspaceName)."
        case .beforeShellExecution:
            return "CatPaw is preparing a shell command in \(workspaceName)."
        case .afterShellExecution:
            return "CatPaw finished a shell command in \(workspaceName)."
        case .beforeMCPExecution:
            return "CatPaw is calling \(toolName ?? "an MCP tool") in \(workspaceName)."
        case .afterMCPExecution:
            return "CatPaw finished \(toolName ?? "an MCP tool") in \(workspaceName)."
        case .beforeReadFile:
            return "CatPaw is reading \(filePath ?? "a file") in \(workspaceName)."
        case .afterFileEdit:
            return "CatPaw edited \(filePath ?? "a file") in \(workspaceName)."
        case .stop:
            return "CatPaw completed a turn in \(workspaceName)."
        case .afterAgentResponse:
            return assistantTextPreview ?? "CatPaw completed a response in \(workspaceName)."
        case .afterAgentThought:
            return thoughtPreview.map { "Thinking: \($0)" } ?? "CatPaw is thinking in \(workspaceName)."
        }
    }

    var promptPreview: String? {
        clipped(prompt)
    }

    var commandPreview: String? {
        clipped(command)
    }

    var outputPreview: String? {
        clipped(output, limit: 160)
    }

    var toolInputPreview: String? {
        clipped(toolInput)
    }

    var resultPreview: String? {
        clipped(resultJSON, limit: 160)
    }

    var assistantTextPreview: String? {
        guard hookEventName == .afterAgentResponse else { return nil }
        return clipped(text, limit: 180)
    }

    var thoughtPreview: String? {
        guard hookEventName == .afterAgentThought else { return nil }
        return clipped(text, limit: 140)
    }

    private func clipped(_ value: String?, limit: Int = 110) -> String? {
        guard let value else { return nil }

        let collapsed = value
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
            .split(separator: " ", omittingEmptySubsequences: true)
            .joined(separator: " ")

        guard !collapsed.isEmpty else { return nil }
        guard collapsed.count > limit else { return collapsed }

        let endIndex = collapsed.index(collapsed.startIndex, offsetBy: limit - 1)
        return "\(collapsed[..<endIndex])…"
    }
}
