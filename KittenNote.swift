//
//  KittenNote.swift
//  agentkitten
//

import SwiftUI

struct KittenNote: View {
    @AppStorage("kitten.notes") private var notes: String = ""
    @State private var isSaved: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text("Notes")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Color(red: 1.44, green : 2.38, blue: 1.44))
                Spacer()
                if isSaved {
                    Text("saved")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(Color(red: 1.44, green : 2.38, blue: 1.44).opacity(0.5))
                        .transition(.opacity)
                }
                Button {
                    notes = ""
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(Color(red: 1.44, green : 2.38, blue: 1.44).opacity(0.5))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)

            Divider()
                .background(Color(red: 1.44, green : 2.38, blue: 1.44).opacity(0.3))

            // Editor
            TextEditor(text: $notes)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(Color(red: 1.44, green : 2.38, blue: 1.44))
                .scrollContentBackground(.hidden)
                .padding(10)
                .onChange(of: notes) { _ in flashSaved() }
        }
        .background(Color(red: 0.04, green: 0.04, blue: 0.04))
    }

    private func flashSaved() {
        withAnimation { isSaved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { isSaved = false }
        }
    }
}
