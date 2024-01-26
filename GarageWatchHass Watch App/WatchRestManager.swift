//
//  WatchRestManager.swift
//  GarageWatchHass Watch App
//
//  Created by Michel Lapointe on 2024-01-23.
//

import Foundation
import Combine
import HassWatchFramework

class WatchRestManager: ObservableObject {
    static let shared = WatchRestManager()
    
    @Published var leftDoorClosed: Bool = true
    @Published var rightDoorClosed: Bool = true
    @Published var alarmOff: Bool = true
    @Published var error: Error?
    @Published var hasErrorOccurred: Bool = false
    @Published var lastCallStatus: CallStatus = .pending
    
    private var restClient: HassRestClient?
    private var cancellables = Set<AnyCancellable>()
    private var initializationFailed = false

    init() {
        self.restClient = HassRestClient()
        print("[GarageRestManager] Initialized with REST client.")
    }
    
    func fetchInitialState() {
        print("[WatchRestManager] Fetching initial state.")
        lastCallStatus = .pending
        let doorSensors = ["binary_sensor.left_door_sensor", "binary_sensor.right_door_sensor", "binary_sensor.alarm_sensor"]
        doorSensors.forEach { entityId in
            restClient?.fetchState(entityId: entityId) { [weak self] result in
                DispatchQueue.main.async {
                    print("[WatchRestManager] REST call completed for entityId: \(entityId). Result: \(result)")
                    switch result {
                    case .success(let entity):
                        print("[WatchRestManager] Success fetching state for \(entityId): \(entity)")
                        self?.lastCallStatus = .success
                        self?.processState(entity)
                    case .failure(let error):
                        print("[WatchRestManager] Failure fetching state for \(entityId): \(error)")
                        self?.lastCallStatus = .failure
                        self?.error = error
                        self?.hasErrorOccurred = true
                    }
                }
            }
        }
    }
    
    func processState(_ entity: HAEntity) {
        print("[WatchRestManager] Processing state for entity: \(entity)")
        switch entity.entityId {
        case "binary_sensor.left_door_sensor":
            print("[WatchRestManager] Updating leftDoorClosed to: \(entity.state == "off")")
            leftDoorClosed = entity.state == "off"
        case "binary_sensor.right_door_sensor":
            print("[WatchRestManager] Updating rightDoorClosed to: \(entity.state == "off")")
            rightDoorClosed = entity.state == "off"
        case "binary_sensor.alarm_sensor":
            print("[WatchRestManager] Updating alarmOff to: \(entity.state == "off")")
            alarmOff = entity.state == "off"
        default:
            print("[WatchRestManager] Unrecognized entity: \(entity.entityId)")
            break
        }
    }
    
    func fetchData() {
        guard restClient != nil else {
            print("[WatchRestManager] REST client is not initialized.")
            return
        }
        
        func handleEntityAction(entityId: String, newState: String) {
            print("[WatchRestManager] Handling entity action for \(entityId), new state: \(newState)")
            lastCallStatus = .pending
            restClient?.changeState(entityId: entityId, newState: newState) { [weak self] result in
                DispatchQueue.main.async {
                    print("[WatchRestManager] REST call completed for entity action: \(entityId).")
                    switch result {
                    case .success(let entity):
                        print("[WatchRestManager] Success changing state for \(entityId): \(entity)")
                        self?.lastCallStatus = .success
                        self?.processState(entity)
                    case .failure(let error):
                        print("[WatchRestManager] Failure changing state for \(entityId): \(error)")
                        self?.lastCallStatus = .failure
                        self?.error = error
                        self?.hasErrorOccurred = true
                    }
                }
            }
        }
    }
        public func handleScriptAction(entityId: String) {
            print("[WatchRestManager] Handling script action for \(entityId)")
            lastCallStatus = .pending
            restClient?.callScript(entityId: entityId) { [weak self] (result: Result<Void, Error>) in
                DispatchQueue.main.async {
                    switch result {
                    case .success():
                        print("[WatchRestManager] Script executed successfully")
                        self?.lastCallStatus = .success
                    case .failure(let error):
                        print("[WatchRestManager] Error executing script \(entityId): \(error)")
                        self?.lastCallStatus = .failure
                        self?.error = error
                        self?.hasErrorOccurred = true
                    }
                }
            }
        }
    }

