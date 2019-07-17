//
//  MPCManager.swift
//  MPCRevisited
//
//  Created by Gabriel Theodoropoulos on 11/1/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

import UIKit
import MultipeerConnectivity

protocol MPCManagerDelegate {
    
    func foundPeer()
    
    func lostPeer()
    
    func invitationWasReceived(fromPeer: String)
    
    func connectedWithPeer(peerID: MCPeerID)
    
    func didReceivedError(error: String)
}

class MPCManager: NSObject {

    var delegate: MPCManagerDelegate?
    
    var session: MCSession!
    
    var peer: MCPeerID!
    
    var browser: MCNearbyServiceBrowser!
    
    var advertiser: MCNearbyServiceAdvertiser!
    
    var foundPeers = [MCPeerID]()
    
    var invitationHandler: ((Bool, MCSession?)->Void)!
    
    
    override init() {
        super.init()
        
        peer = MCPeerID(displayName: UIDevice.current.name)
        
        session = MCSession(peer: peer)
        session.delegate = self
        
        browser = MCNearbyServiceBrowser(peer: peer, serviceType: "appcoda-mpc")
        browser.delegate = self
        
        advertiser = MCNearbyServiceAdvertiser(peer: peer, discoveryInfo: nil, serviceType: "appcoda-mpc")
        advertiser.delegate = self
    }
    
    // MARK: Custom method implementation

    func sendData(dictionaryWithData dictionary: Dictionary<String, String>, toPeer targetPeer: MCPeerID) -> Bool {
        
        let dataToSend = NSKeyedArchiver.archivedData(withRootObject: dictionary)
        
        do {
            try session.send(dataToSend, toPeers: [targetPeer], with: .reliable)
        } catch {
            delegate?.didReceivedError(error: error.localizedDescription)
            return false
        }
        return true
        
    }
    
}

// MARK: - MCSessionDelegate
extension MPCManager: MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        
        switch state {
        case MCSessionState.connected:
            debugPrint("Connected: \(peerID.displayName)")
            delegate?.connectedWithPeer(peerID: peerID)
            
        case MCSessionState.connecting:
            debugPrint("Connecting: \(peerID.displayName)")
            
        case MCSessionState.notConnected:
            debugPrint("Not Connected: \(peerID.displayName)")
            
        @unknown default:
            break
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
        let dictionary: [String: AnyObject] = ["data": data as AnyObject, "fromPeer": peerID]
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "receivedMPCDataNotification"), object: dictionary, userInfo: nil)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        do {
            try debugPrint("Received data: \(Data.init(reading: stream))")
        } catch {
            debugPrint(error.localizedDescription)
        }
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        debugPrint("Start Receiving Resource: \(resourceName) from \(peerID.displayName) progress: \(progress.completedUnitCount / progress.totalUnitCount)")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
        debugPrint("Finish Receiving Resource: \(resourceName) from \(peerID.displayName)")
        
        if let error = error {
            assertionFailure(error.localizedDescription)
        } else if let fileURL = localURL {
            debugPrint("File location: \(fileURL.absoluteString)")
        }
        
    }
    
}

// MARK: - MCNearbyServiceBrowserDelegate
extension MPCManager: MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        foundPeers.append(peerID)
        delegate?.foundPeer()
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        
        if let index = foundPeers.firstIndex(of: peerID) {
            foundPeers.remove(at: index)
        }
        delegate?.lostPeer()
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        delegate?.didReceivedError(error: error.localizedDescription)
    }
    
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension MPCManager: MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        
        self.invitationHandler = invitationHandler
        delegate?.invitationWasReceived(fromPeer: peerID.displayName)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        delegate?.didReceivedError(error: error.localizedDescription)
    }
    
}
