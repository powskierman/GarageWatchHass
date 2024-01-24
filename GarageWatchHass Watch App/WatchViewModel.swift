//
//  WatchViewModel.swift
//  GarageWatchHass Watch App
//
//  Created by Michel Lapointe on 2024-01-23.
//

import Foundation
import WatchConnectivity

class WatchViewModel: NSObject, ObservableObject, WCSessionDelegate {
    
    @Published var leftDoorClosed: Bool = true
    @Published var rightDoorClosed: Bool = true
    @Published var alarmOff: Bool = true
    @Published var errorMessage: String?
    
    override init() {
        super.init()
        print("[WatchViewModel] Initializing and setting up WatchConnectivity")
        setupWatchConnectivity()
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("[WatchViewModel] WCSession activation did complete. State: \(activationState), Error: \(String(describing: error))")
        if activationState == .activated {
            print("[WatchViewModel] Session activated, requesting initial state.")
            requestInitialState()
        }
    }
    
    private func requestInitialState() {
        // Check if the session is reachable before sending a message
        if WCSession.default.isReachable {
            sendInitialStateRequest()
        } else {
            // Retry after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.sendInitialStateRequest()
            }
        }
    }
    
    private func sendInitialStateRequest() {
        print("[Watch] Requesting initial state from iPhone app")
        let message = ["request": "initialState"]
        WCSession.default.sendMessage(message, replyHandler: { response in
            // Process the response here
            self.processInitialStateResponse(response)
        }, errorHandler: { error in
            print("[Watch] Error requesting initial state: \(error.localizedDescription)")
        })
    }
    
    private func processInitialStateResponse(_ response: [String: Any]) {
        DispatchQueue.main.async {
            print("[Watch] Processing initial state response")
            if let leftDoorClosedValue = response["leftDoorClosed"] as? Bool {
                self.leftDoorClosed = leftDoorClosedValue
                print("[Watch] Left door initial state: \(leftDoorClosedValue)")
            }
            if let rightDoorClosedValue = response["rightDoorClosed"] as? Bool {
                self.rightDoorClosed = rightDoorClosedValue
                print("[Watch] Right door initial state: \(rightDoorClosedValue)")
            }
            if let alarmOffValue = response["alarmOff"] as? Bool {
                self.alarmOff = alarmOffValue
                print("[Watch] Alarm initial state: \(alarmOffValue)")
            }
        }
    }
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
            print("Watch Connectivity setup initiated.")
        } else {
            print("Watch Connectivity not supported on this device.")
        }
    }
    
    func sendCommandToPhone(entityId: String, newState: String) {
        print("[WatchViewModel] Attempting to send command to iPhone: \(entityId), newState: \(newState)")

        let session = WCSession.default
        guard session.isReachable else {
            print("[WatchViewModel] WCSession is not reachable. Command not sent.")
            return
        }

        let message = ["entityId": entityId, "newState": newState]
        session.sendMessage(message, replyHandler: { response in
            // Handle the response here if needed
            print("[WatchViewModel] Received reply from phone: \(response)")
        }, errorHandler: { error in
            print("[WatchViewModel] Error sending command to phone: \(error.localizedDescription)")
        })
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("[WatchViewModel] Received message from phone: \(message)")
        DispatchQueue.main.async {
            self.processReceivedMessage(message)
        }
    }

    private func processReceivedMessage(_ message: [String: Any]) {
        print("[WatchViewModel] Processing received message: \(message)")

        if let isInitialState = message["isInitialState"] as? Bool, isInitialState {
            print("[WatchViewModel] Processing as initial state message")
            self.processInitialStateResponse(message)
        } else if let entityId = message["entityId"] as? String, let newState = message["newState"] as? String {
            print("[WatchViewModel] Processing as regular update message")
            self.updateStateBasedOnMessage(entityId: entityId, newState: newState)
        } else if message["request"] as? String == "initialState" {
            print("[WatchViewModel] Processing as initialState request")
            self.processInitialStateResponse(message)
        }
    }


    private func updateLeftDoorState(newState: String) {
        let isClosed = newState == "off"
        print("[WatchViewModel] Updating Left Door Sensor State (Current: \(leftDoorClosed), New: \(isClosed))")
        leftDoorClosed = isClosed
    }

    private func updateRightDoorState(newState: String) {
        let isClosed = newState == "off"
        print("[WatchViewModel] Updating Right Door Sensor State (Current: \(rightDoorClosed), New: \(isClosed))")
        rightDoorClosed = isClosed
    }

    private func updateAlarmState(newState: String) {
        let isAlarmOff = newState == "off"
        print("[WatchViewModel] Updating Alarm State (Current: \(alarmOff), New: \(isAlarmOff))")
        alarmOff = isAlarmOff
    }

    private func updateStateBasedOnMessage(entityId: String, newState: String) {
            switch entityId {
            case "binary_sensor.left_door_sensor":
                self.updateLeftDoorState(newState: newState)
            case "binary_sensor.right_door_sensor":
                self.updateRightDoorState(newState: newState)
            case "binary_sensor.alarm_sensor":
                self.updateAlarmState(newState: newState)
            default:
                print("[WatchViewModel] Unknown entity ID: \(entityId)")
            }
        }
    

    func sessionReachabilityDidChange(_ session: WCSession) {
        print("[Watch] WCSession reachability changed. Is now reachable: \(session.isReachable)")
        if session.isReachable {
            requestInitialState() // Attempt to request initial state when session becomes reachable
        }
    }
    
    func checkiPhoneAppStatus(performAction action: @escaping () -> Void) {
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(["request": "appStatus"], replyHandler: { response in
                if let appStatus = response["appStatus"] as? Bool, appStatus {
                    self.checkWebSocketConnection(performAction: action)
                } else {
                    self.displayErrorMessage("iPhone app is not running")
                }
            }, errorHandler: { error in
                self.displayErrorMessage("Error communicating with iPhone: \(error.localizedDescription)")
            })
        } else {
            self.displayErrorMessage("iPhone is not reachable")
        }
    }

    func checkWebSocketConnection(performAction action: @escaping () -> Void) {
        WCSession.default.sendMessage(["request": "webSocketStatus"], replyHandler: { response in
            if let webSocketStatus = response["webSocketStatus"] as? Bool, webSocketStatus {
                action() // Perform the defined action
            } else {
                self.displayErrorMessage("WebSocket is not connected")
            }
        }, errorHandler: { error in
            self.displayErrorMessage("Error communicating with iPhone: \(error.localizedDescription)")
        })
    }

    
    func displayErrorMessage(_ message: String) {
            DispatchQueue.main.async {
                self.errorMessage = message
                // Reset the error message after a certain duration
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) { // 5 seconds delay
                self.errorMessage = nil
                }
            }
        }
}

