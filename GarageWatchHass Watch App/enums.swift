//
//  enums.swift
//  GarageWatchHass Watch App
//
//  Created by Michel Lapointe on 2024-01-23.
//

import Foundation

enum EntityType {
    case door(Door)
    case alarm
}

enum Door {
    case left
    case right
}

// Enum to represent the status of a REST API call
enum CallStatus {
    case success
    case failure
    case pending
}

