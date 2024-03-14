//
//  WatchEntityView.swift
//  GarageWatchHass Watch App
//
//  Created by Michel Lapointe on 2024-01-23.
//

import SwiftUI
import HassWatchFramework

struct WatchEntityView: View {
    @ObservedObject var viewModel: WatchManager
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
            let entityId = doorType == .left ? "switch.left_garage_door" : "switch.right_garage_door"
            toggleSwitch(entityId: entityId)        
        case .alarm:
            self.showingAlarmConfirmation = true
        }
    }
    
    private func callScript(_ scriptId: String) {
        let entityId = "script.\(scriptId)"
        WatchManager.shared.handleScriptAction(entityId: entityId)
    }
    
    private func toggleSwitch(entityId: String) {
        print("[WatchEntityView] Toggling switch for \(entityId)")
  //      lastCallStatus = .pending
        HassRestClient.shared.callService(domain: "switch", service: "toggle", entityId: entityId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success():
                    print("[GarageRestManager] Successfully toggled switch \(entityId)")
                    viewModel.lastCallStatus = .success
                    // Optionally fetch state if needed to update UI or confirm change
                    viewModel.fetchInitialState()
                case .failure(let error):
                    print("[GarageRestManager] Error toggling switch \(entityId): \(error)")
                    viewModel.lastCallStatus = .failure
                    viewModel.error = error
                    viewModel.hasErrorOccurred = true
                }
            }
        }
    }
    private func toggleAlarmState() {
        let entityId = viewModel.alarmOff ? "switch.alarm_on" : "switch.alarm_off"
        toggleSwitch(entityId: entityId)
    }
}
