import SwiftUI
import Combine
import HassWatchFramework

class WatchViewModel: ObservableObject {
    @Published var leftDoorClosed: Bool = true
    @Published var rightDoorClosed: Bool = true
    @Published var alarmOff: Bool = true
    @Published var errorMessage: String?

    private var restClient: HassRestClient?

    init() {
        print("[WatchViewModel] Initializing...")
        self.restClient = HassRestClient()
        print("[WatchViewModel] HassRestClient initialized.")

        if restClient == nil {
            print("[WatchViewModel] Failed to initialize HassRestClient.")
            self.errorMessage = "Failed to initialize HassRestClient"
        } else {
            print("[WatchViewModel] Fetching initial state.")
            fetchInitialState()
        }
    }

//class WatchViewModel: ObservableObject {
//    @Published var leftDoorClosed: Bool = true
//    @Published var rightDoorClosed: Bool = true
//    @Published var alarmOff: Bool = true
//    @Published var errorMessage: String?
//
//    private let restClient: HassRestClient?
//
//    init() {
//        restClient = HassRestClient()
//        if restClient == nil {
//            print("[WatchViewModel] Failed to initialize HassRestClient.")
//            self.errorMessage = "Failed to initialize HassRestClient"
//        } else {
//            fetchInitialState()
//        }
//    }

    func fetchInitialState() {
        fetchState(for: "binary_sensor.left_door_sensor") { self.leftDoorClosed = $0 }
        fetchState(for: "binary_sensor.right_door_sensor") { self.rightDoorClosed = $0 }
        fetchState(for: "binary_sensor.alarm_sensor") { self.alarmOff = $0 }
    }

    private func fetchState(for entityId: String, update: @escaping (Bool) -> Void) {
        guard let restClient = restClient else {
            print("[WatchViewModel] RestClient is nil.")
            return
        }

        restClient.fetchState(entityId: entityId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let entity):
                    print("[WatchViewModel] Fetched state for \(entityId): \(entity.state)")
                    update(entity.state == "off")
                case .failure(let error):
                    print("[WatchViewModel] Error fetching state for \(entityId): \(error)")
                    self.errorMessage = "Failed to fetch state for \(entityId)"
                }
            }
        }
    }

    func sendCommand(entityId: String, newState: String) {
        guard let restClient = restClient else {
            print("[WatchViewModel] RestClient is nil.")
            return
        }

        restClient.changeState(entityId: entityId, newState: newState) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let entity):
                    print("[WatchViewModel] Command sent successfully to \(entityId): \(entity.state)")
                    // Update UI based on the response
                    // ... (handle the update here)
                case .failure(let error):
                    print("[WatchViewModel] Error sending command to \(entityId): \(error)")
                    self.errorMessage = "Failed to send command to \(entityId)"
                }
            }
        }
    }
}
