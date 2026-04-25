//
//  ContentView.swift
//  agentkitten
//
//  Created by Skye Fuller on 4/25/26.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: agentkittenDocument

    var body: some View {
        TextEditor(text: $document.text)
    }
}

#Preview {
    ContentView(document: .constant(agentkittenDocument()))
}
