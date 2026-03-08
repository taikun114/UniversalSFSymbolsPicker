//
//  USSPDemoApp.swift
//  USSPDemo
//
//  Created by 今浦大雅 on 2026/03/07.
//

import SwiftUI

@main
struct USSPDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        .windowResizability(.contentSize)
        .defaultSize(width: 400, height: 500)
        #elseif os(visionOS)
        .windowResizability(.contentSize)
        .defaultSize(width: 600, height: 800)
        #endif
    }
}
