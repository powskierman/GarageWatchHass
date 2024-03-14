//
//  WatchManager.swift
//  GarageWatchHass Watch App
//
//  Created by Michel Lapointe on 2024-02-13.
//

import SwiftUI
import Combine
import HassWatchFramework

class WatchManager: ObservableObject {
    @Published var leftDoorClosed: Bool = true
    @Published var rightDoorClosed: Bool = true
    @Published var alarmOff: Bool = true
    @Published var error: Error?
    @Published var hasErrorOccurred: Bool = false
    @Published var errorMessage: String?
    @Published var lastCallStatus: CallStatus = .pending
    
    private var restClient: HassRestClient?
    private var cancellables = Set<AnyCancellable>()
    private var initializationFailed = false
    
    static let shared = WatchManager()

    init() {
        self.restClient = HassRestClient.shared
        print("[WatchManager] Initialized with REST client.")

        if restClient == nil {
            print("[WatchManager] Failed to initialize HassRestClient.")
            self.errorMessage = "Failed to initialize HassRestClient"
        } else {
            print("[WatchManager] Fetching initial state.")
            fetchInitialState()
        }
    }

    func fetchInitialState() {
        fetchState(for: "binary_sensor.left_door_sensor") { self.leftDoorClosed = $0 }
        print("[WatchManager 41] ")
        fetchState(for: "binary_sensor.right_door_sensor") { self.rightDoorClosed = $0 }
        fetchState(for: "binary_sensor.alarm_sensor") { self.alarmOff = $0 }
    }

    private func fetchState(for entityId: String, update: @escaping (Bool) -> Void) {
        guard let restClient = restClient else {
            print("[WatchManager] RestClient is nil.")
            return
        }

        restClient.fetchState(entityId: entityId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let entity):
                    print("[WatchManager] Fetched state for \(entityId): \(entity.state)")
                    update(entity.state == "off")
                case .failure(let error):
                    print("[WatchManager] Error fetching state for \(entityId): \(error)")
                    self.errorMessage = "Failed to fetch state for \(entityId)"
                }
            }
        }
    }

    func sendCommand(entityId: String, newState: Int) {
        guard let restClient = restClient else {
            print("[WatchManager] RestClient is nil.")
            return
        }

        restClient.changeState(entityId: entityId, newState: newState) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let entity):
                    print("[WatchManager] Command sent successfully to \(entityId): \(entity.state)")
                    // Update UI based on the response
                    // ... (handle the update here)
                case .failure(let error):
                    print("[WatchManager] Error sending command to \(entityId): \(error)")
                    self.errorMessage = "Failed to send command to \(entityId)"
                }
            }
        }
    }

    func handleScriptAction(entityId: String) {
        print("[WatchManager] Handling script action for \(entityId)")
        lastCallStatus = .pending
        restClient?.callScript(entityId: entityId) { [weak self] (result: Result<Void, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success():
                    print("[WatchManager] Script executed successfully")
                    self?.lastCallStatus = .success
                case .failure(let error):
                    print("[WatchManager] Error executing script \(entityId): \(error)")
                    self?.lastCallStatus = .failure
                    self?.errorMessage = "Failed to execute script \(entityId)"
                }
            }
        }
    }
}
