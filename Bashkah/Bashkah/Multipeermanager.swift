////
////  MultipeerManager.swift
////  Bashkah
////
////  Created by Hneen on 22/08/1447 AH.
////
//
//import Foundation
//import MultipeerConnectivity
//
//class MultipeerManager: NSObject, ObservableObject {
//    // MARK: - Published Properties
//    @Published var connectedPeers: [MCPeerID] = []
//    @Published var availableRooms: [String: MCPeerID] = [:]  // [RoomNumber: HostPeerID]
//    @Published var isHosting: Bool = false
//    @Published var connectionStatus: ConnectionStatus = .disconnected
//    
//    // MARK: - Multipeer Components
//    private var peerID: MCPeerID
//    private var session: MCSession
//    private var advertiser: MCNearbyServiceAdvertiser?
//    private var browser: MCNearbyServiceBrowser?
//    
//    // MARK: - Constants
//    private let serviceType = "bashkah-game"
//    private let maxPeers = 5  // Host + 7 players = 8 total
//    
//    // MARK: - Callbacks
//    var onMessageReceived: ((FunFactMessage) -> Void)?
//    var onPeerConnectionChanged: (() -> Void)?
//    
//    // MARK: - Current Room Info
//    private(set) var currentRoomNumber: String?
//    
//    // MARK: - Initialization
//    override init() {
//        // Create unique peer ID for this device
//        let deviceName = UIDevice.current.name
//        self.peerID = MCPeerID(displayName: deviceName)
//        
//        // Create session
//        self.session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .none)
//        
//        super.init()
//        
//        self.session.delegate = self
//    }
//    
//    // MARK: - Device ID
//    var deviceID: String {
//        return peerID.displayName
//    }
//    
//    // MARK: - Host Room
//    func hostRoom(roomNumber: String) {
//        currentRoomNumber = roomNumber
//        isHosting = true
//        connectionStatus = .hosting
//        
//        // Start advertising
//        let discoveryInfo = ["roomNumber": roomNumber]
//        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: discoveryInfo, serviceType: serviceType)
//        advertiser?.delegate = self
//        advertiser?.startAdvertisingPeer()
//        
//        print("🟢 Hosting room: \(roomNumber)")
//    }
//    
//    // MARK: - Browse Rooms
//    func startBrowsing() {
//        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
//        browser?.delegate = self
//        browser?.startBrowsingForPeers()
//        
//        connectionStatus = .browsing
//        print("🔍 Started browsing for rooms")
//    }
//    
//    // MARK: - Join Room
//    func joinRoom(roomNumber: String) {
//        currentRoomNumber = roomNumber
//        connectionStatus = .connecting
//        
//        // For dummy app: simulate successful connection after delay
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//            self.connectionStatus = .connected
//            print("✅ Dummy mode: Simulated join to room: \(roomNumber)")
//        }
//        
//        // Real multiplayer logic (won't work in dummy mode)
//        if let hostPeer = availableRooms[roomNumber] {
//            browser?.invitePeer(hostPeer, to: session, withContext: nil, timeout: 30)
//            print("📤 Sent join request to room: \(roomNumber)")
//        } else {
//            print("⚠️ Room \(roomNumber) not found in available rooms - using dummy mode")
//        }
//    }
//    
//    // MARK: - Send Message
//    func sendMessage(_ message: FunFactMessage, to peers: [MCPeerID]? = nil) {
//        guard !session.connectedPeers.isEmpty else {
//            print("⚠️ No connected peers")
//            return
//        }
//        
//        do {
//            let data = try JSONEncoder().encode(message)
//            let targetPeers = peers ?? session.connectedPeers
//            try session.send(data, toPeers: targetPeers, with: .reliable)
//            print("✅ Sent message: \(message.type.rawValue)")
//        } catch {
//            print("❌ Error sending message: \(error)")
//        }
//    }
//    
//    // MARK: - Broadcast Message (to all)
//    func broadcastMessage(_ message: FunFactMessage) {
//        sendMessage(message, to: session.connectedPeers)
//    }
//    
//    // MARK: - Disconnect
//    func disconnect() {
//        session.disconnect()
//        advertiser?.stopAdvertisingPeer()
//        browser?.stopBrowsingForPeers()
//        
//        advertiser = nil
//        browser = nil
//        currentRoomNumber = nil
//        isHosting = false
//        connectedPeers.removeAll()
//        availableRooms.removeAll()
//        connectionStatus = .disconnected
//        
//        print("🔴 Disconnected from session")
//    }
//    
//    // MARK: - Stop Browsing
//    func stopBrowsing() {
//        browser?.stopBrowsingForPeers()
//        browser = nil
//        availableRooms.removeAll()
//        print("🛑 Stopped browsing")
//    }
//}
//
//// MARK: - MCSessionDelegate
//extension MultipeerManager: MCSessionDelegate {
//    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
//        DispatchQueue.main.async {
//            switch state {
//            case .connected:
//                print("✅ Connected to: \(peerID.displayName)")
//                if !self.connectedPeers.contains(peerID) {
//                    self.connectedPeers.append(peerID)
//                }
//                self.connectionStatus = .connected
//                
//            case .connecting:
//                print("🔄 Connecting to: \(peerID.displayName)")
//                self.connectionStatus = .connecting
//                
//            case .notConnected:
//                print("❌ Disconnected from: \(peerID.displayName)")
//                self.connectedPeers.removeAll { $0 == peerID }
//                if self.connectedPeers.isEmpty && !self.isHosting {
//                    self.connectionStatus = .disconnected
//                }
//                
//            @unknown default:
//                break
//            }
//            
//            self.onPeerConnectionChanged?()
//        }
//    }
//    
//    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
//        do {
//            let message = try JSONDecoder().decode(FunFactMessage.self, from: data)
//            DispatchQueue.main.async {
//                print("📥 Received message: \(message.type.rawValue) from \(peerID.displayName)")
//                self.onMessageReceived?(message)
//            }
//        } catch {
//            print("❌ Error decoding message: \(error)")
//        }
//    }
//    
//    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
//        // Not used
//    }
//    
//    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
//        // Not used
//    }
//    
//    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
//        // Not used
//    }
//}
//
//// MARK: - MCNearbyServiceAdvertiserDelegate
//extension MultipeerManager: MCNearbyServiceAdvertiserDelegate {
//    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
//        // Auto accept if room not full
//        let accept = session.connectedPeers.count < maxPeers
//        invitationHandler(accept, accept ? session : nil)
//        
//        if accept {
//            print("✅ Accepted connection from: \(peerID.displayName)")
//        } else {
//            print("⚠️ Rejected connection (room full)")
//        }
//    }
//}
//
//// MARK: - MCNearbyServiceBrowserDelegate
//extension MultipeerManager: MCNearbyServiceBrowserDelegate {
//    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
//        DispatchQueue.main.async {
//            if let roomNumber = info?["roomNumber"] {
//                self.availableRooms[roomNumber] = peerID
//                print("🔍 Found room: \(roomNumber) (Host: \(peerID.displayName))")
//            }
//        }
//    }
//    
//    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
//        DispatchQueue.main.async {
//            // Remove room if it was this peer
//            self.availableRooms = self.availableRooms.filter { $0.value != peerID }
//            print("❌ Lost peer: \(peerID.displayName)")
//        }
//    }
//}
//
//// MARK: - Connection Status
//enum ConnectionStatus: String {
//    case disconnected = "غير متصل"
//    case browsing = "البحث عن غرف"
//    case hosting = "استضافة غرفة"
//    case connecting = "جاري الاتصال"
//    case connected = "متصل"
//}
