//
//  ChatView.swift
//  agentkitten
//

import SwiftUI

struct ChatView: View {
    @ObservedObject var session: ClaudeSession
    @State private var input: String = ""
    @FocusState private var inputFocused: Bool

    private var promptLabel: String {
        URL(fileURLWithPath: session.workingDirectory).lastPathComponent
    }

    var body: some View {
        VStack(spacing: 0) {
            // Terminal output
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(session.lines) { line in
                            TerminalLine(line: line)
                        }
                        if session.isRunning {
                            Text("▋")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.green)
                                .opacity(0.8)
                        }
                        Color.clear.frame(height: 1).id("bottom")
                    }
                    .padding(10)
                }
                .onChange(of: session.lines.count) { _ in proxy.scrollTo("bottom") }
                .onChange(of: session.isRunning)   { _ in proxy.scrollTo("bottom") }
            }

            Divider().background(Color.green.opacity(0.3))

            // Input row
            HStack(spacing: 6) {
                Text(promptLabel)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.green.opacity(0.5))
                    .lineLimit(1)
                    .truncationMode(.head)

                Text("❯")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(session.isReady ? .green : .green.opacity(0.3))

                TextField("", text: $input)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.green)
                    .textFieldStyle(.plain)
                    .focused($inputFocused)
                    .onSubmit { sendMessage() }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.5))
        }
        .background(Color(red: 0.04, green: 0.04, blue: 0.04))
        .onAppear { inputFocused = true }
    }

    private func sendMessage() {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !session.isRunning else { return }
        guard session.isReady else {
            session.lines.append(.init(text: "Still starting… wait a moment", kind: .system))
            return
        }
        session.lines.append(.init(text: "\(promptLabel) ❯ \(trimmed)", kind: .system))
        input = ""
        session.send(prompt: trimmed)
        inputFocused = true
    }
}

struct TerminalLine: View {
    let line: ClaudeSession.OutputLine

    var body: some View {
        Text(line.text)
            .font(.system(size: 12, design: .monospaced))
            .foregroundColor(color)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var color: Color {
        switch line.kind {
        case .text:   return Color(red: 1.44, green: 2.38, blue: 1.44) //lightgreen
        case .tool:   return Color(red: 1.43, green: 1.88, blue: 1.43)   //darkseagreen for tools
        case .system: return Color(red: 1.44, green: 2.38, blue: 1.44).opacity(0.5)
        case .error:  return Color(red: 2.04, green: 2.55, blue: 2.55)   //lightblue for errors
        }
    }
}
