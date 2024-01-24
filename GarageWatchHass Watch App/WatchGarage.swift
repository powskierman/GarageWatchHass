//
//  WatchGarageHassApp.swift
//  WatchGarageHass
//
//  Created by Michel Lapointe on 2023-11-16.
//

import SwiftUI

@main
struct WatchGarageHassApp: App {
    @StateObject var watchViewModel = WatchViewModel()
    var body: some Scene {
        WindowGroup {
            WatchView(watchViewModel: watchViewModel)
        }
    }
}
