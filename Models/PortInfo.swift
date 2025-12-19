import Foundation

struct PortInfo: Identifiable, Equatable {
    let id = UUID()
    let port: Int
    let portProtocol: PortProtocol
    let processName: String
    let processID: Int
    let command: String
    let state: String?

    enum PortProtocol: String, CaseIterable {
        case tcp = "TCP"
        case udp = "UDP"
    }

    var displayText: String {
        "\(port) (\(portProtocol.rawValue))"
    }

    var processInfo: String {
        "\(processName) (PID: \(processID))"
    }
}