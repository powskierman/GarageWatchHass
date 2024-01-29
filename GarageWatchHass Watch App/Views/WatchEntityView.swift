//
//  WatchEntityView.swift
//  GarageWatchHass Watch App
//
//  Created by Michel Lapointe on 2024-01-23.
//

import SwiftUI

struct WatchEntityView: View {
    @ObservedObject var viewModel: WatchViewModel
    let entityType: EntityType
    @State private var showingAlarmConfirmation = false
    @State private var isPressed = false // New state variable for color change

    var body: some View {
        Button(action: {
            isPressed = true // Change color when pressed
            handleButtonPress()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isPressed = false // Revert color back after 500ms
            }
        }) {
            VStack {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                entityImage
                Text(entityLabel)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(isPressed ? Color.yellow : entityBackgroundColor) // Use isPressed to determine background color
        .confirmationDialog("Confirm Alarm Change", isPresented: $showingAlarmConfirmation) {
            Button("Confirm", role: .destructive) {
                toggleAlarmState()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
    
    private var entityImage: some View {
        switch entityType {
        case .door(let doorType):
            let isClosed = doorType == .left ? viewModel.leftDoorClosed : viewModel.rightDoorClosed
            return Image(systemName: isClosed ? "door.garage.closed" : "door.garage.open")
                .resizable()
                .scaledToFit()
        case .alarm:
            return Image(systemName: viewModel.alarmOff ? "alarm" : "alarm.waves.left.and.right.fill")
                .resizable()
                .scaledToFit()
        }
    }
    
    private var entityLabel: String {
        switch entityType {
        case .door(let doorType):
            return doorType == .left ? "Left Door" : "Right Door"
        case .alarm:
            return "Alarm"
        }
    }
    
    private var entityBackgroundColor: Color {
        switch entityType {
        case .door(let doorType):
            let isClosed = doorType == .left ? viewModel.leftDoorClosed : viewModel.rightDoorClosed
            return isClosed ? Color.teal : Color.pink
        case .alarm:
            return viewModel.alarmOff ? Color.teal : Color.pink
        }
    }
    
    private func handleButtonPress() {
        switch self.entityType {
        case .door(let doorType):
            let scriptId = doorType == .left ? "toggle_left_door" : "toggle_right_door"
            callScript(scriptId)
        case .alarm:
            self.showingAlarmConfirmation = true
        }
    }
    
    private func callScript(_ scriptId: String) {
        let entityId = "script.\(scriptId)"
        WatchRestManager.shared.handleScriptAction(entityId: entityId)
    }
    
    
    private func toggleAlarmState() {
        let scriptId = viewModel.alarmOff ? "toggle_alarm_on" : "toggle_alarm_off"
        callScript(scriptId)
    }
}
