import Foundation

struct ProcessInfo: Identifiable, Hashable {
    static func == (lhs: ProcessInfo, rhs: ProcessInfo) -> Bool {
        return lhs.processID == rhs.processID && lhs.processName == rhs.processName
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(processID)
        hasher.combine(processName)
    }
    let id = UUID()
  var uniqueId: String {
    "\(processName)-\(processID)"
  }
    let processName: String
    let processID: Int
    let command: String
    let ports: [PortInfo]

    var displayText: String {
        "\(processName) (PID: \(processID))"
    }

    var portCount: Int {
        ports.count
    }

    var portSummary: String {
        let sortedPorts = ports.sorted { $0.port < $1.port }
        let portStrings = sortedPorts.prefix(3).map { "\($0.port)" }
        let mainPorts = portStrings.joined(separator: ", ")

        if ports.count > 3 {
            return "\(mainPorts)..."
        } else {
            return mainPorts
        }
    }

    var protocols: Set<PortInfo.PortProtocol> {
        Set(ports.map { $0.portProtocol })
    }

    var hasTCPPorts: Bool {
        protocols.contains(.tcp)
    }

    var hasUDPPorts: Bool {
        protocols.contains(.udp)
    }

    var isSystemProcess: Bool {
        ProcessManager.isSystemProcess(PortInfo(
            port: 0,
            portProtocol: .tcp,
            processName: processName,
            processID: processID,
            command: command,
            state: nil
        ))
    }

    static func groupPorts(_ ports: [PortInfo], order: [String: Int] = [:]) -> [ProcessInfo] {
        let grouped = Dictionary(grouping: ports) { port in
            "\(port.processName)-\(port.processID)"
        }

        var processInfos = grouped.values.map { portList in
            guard let firstPort = portList.first else {
                fatalError("Empty port list in grouping")
            }

            return ProcessInfo(
                processName: firstPort.processName,
                processID: firstPort.processID,
                command: firstPort.command,
                ports: portList
            )
        }

        // Sort by provided order, then by process name and PID for new processes
        processInfos.sort { lhs, rhs in
            let lhsOrder = order[lhs.uniqueId] ?? Int.max
            let rhsOrder = order[rhs.uniqueId] ?? Int.max

            if lhsOrder != rhsOrder {
                return lhsOrder < rhsOrder
            }

            if lhs.processName != rhs.processName {
                return lhs.processName < rhs.processName
            }
            return lhs.processID < rhs.processID
        }

        return processInfos
    }
}