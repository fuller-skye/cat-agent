//
//  agentkittenApp.swift
//  agentkitten
//
//  Created by Skye Fuller on 4/25/26.
//

import SwiftUI

@main
struct agentkittenApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: agentkittenDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}
