//
//  AppDelegate+VoIPPush.swift
//  QuickStart
//
//  Created by Jaesung Lee on 2020/09/18.
//  Copyright © 2020 Sendbird Inc. All rights reserved.
//

import UIKit
import CallKit
import PushKit
import SendBirdCalls

// MARK: VoIP Push
extension AppDelegate: PKPushRegistryDelegate {
    func voipRegistration() {
        self.voipRegistry = PKPushRegistry(queue: DispatchQueue.main)
        self.voipRegistry?.delegate = self
        self.voipRegistry?.desiredPushTypes = [.voIP]
    }
    
    // MARK: - SendBirdCalls - Registering push token.
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        UserDefaults.standard.voipPushToken = pushCredentials.token
        print("Push token is \(pushCredentials.token.toHexString())")
        
        guard SendBirdCall.currentUser != nil else {
            print("No logged in user.")
            return
        }
        self.registerVoIPPushToken(token: pushCredentials.token)
    }
    
    func registerVoIPPushToken(token: Data) {
        SendBirdCall.registerVoIPPush(token: token, unique: true) { error in
            if let error {
                print("Error registering VoIP push token: \(error.localizedDescription)")
                return
            }
            print("Successfully registered VoIP push token.")
        }
    }
    
    // MARK: - SendBirdCalls - Receive incoming push event
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType) {
        SendBirdCall.pushRegistry(registry, didReceiveIncomingPushWith: payload, for: type, completionHandler: nil)
    }
    
    // MARK: - SendBirdCalls - Handling incoming call
    // Please refer to `AppDelegate+SendBirdCallsDelegates.swift` file.
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        SendBirdCall.pushRegistry(registry, didReceiveIncomingPushWith: payload, for: type) { uuid in
            guard uuid != nil else {
                let update = CXCallUpdate()
                update.remoteHandle = CXHandle(type: .generic, value: "invalid")
                let randomUUID = UUID()
                
                CXCallManager.shared.reportIncomingCall(with: randomUUID, update: update) { _ in
                    CXCallManager.shared.endCall(for: randomUUID, endedAt: Date(), reason: .acceptFailed)
                }
                completion()
                return
            }
            
            completion()
        }
    }
}
