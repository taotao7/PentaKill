import Foundation
import Combine

class PortScanner: ObservableObject {
    @Published var ports: [PortInfo] = []
    @Published var processes: [ProcessInfo] = []
    @Published var isScanning = false
    @Published var error: String?

    private var processOrder: [String: Int] = [:] // Track process order by uniqueId
    private var nextOrder: Int = 0

    private var scanTimer: Timer?
    private let refreshInterval: TimeInterval = 5.0 // seconds

    init() {
        startPeriodicScanning()
    }

    deinit {
        scanTimer?.invalidate()
    }

    func startPeriodicScanning() {
        scanTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { _ in
            Task {
                await self.scanPorts()
            }
        }
        // Initial scan
        Task {
            await scanPorts()
        }
    }

    func scanPorts() async {
        await MainActor.run {
            isScanning = true
            error = nil
        }

        do {
            let portInfos = try await executePortScan()
            let processInfos = ProcessInfo.groupPorts(portInfos, order: processOrder)

            // Update order for any new processes
            processInfos.forEach { process in
                if processOrder[process.uniqueId] == nil {
                    processOrder[process.uniqueId] = nextOrder
                    nextOrder += 1
                }
            }

            await MainActor.run {
                self.ports = portInfos.sorted { $0.port < $1.port }
                self.processes = processInfos
                self.isScanning = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isScanning = false
            }
        }
    }

    private func executePortScan() async throws -> [PortInfo] {
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.launchPath = "/usr/sbin/lsof"
            process.arguments = ["-i", "-P", "-n"] // Don't resolve hostnames, show port numbers

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = Pipe()

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
                return
            }

            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""

            if process.terminationStatus != 0 {
                continuation.resume(throwing: NSError(domain: "PortScanner", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "Failed to execute lsof"]))
                return
            }

            let portInfos = parseLsofOutput(output)
            continuation.resume(returning: portInfos)
        }
    }

    private func parseLsofOutput(_ output: String) -> [PortInfo] {
        var portInfos: [PortInfo] = []
        let lines = output.components(separatedBy: .newlines)

        // Skip header line
        guard lines.count > 1 else { return [] }

        for line in lines.dropFirst() {
            let components = line.trimmingCharacters(in: .whitespaces)
                .components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }

            guard components.count >= 9 else { continue }

            // lsof output format:
            // COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME
            // Chrome  1234 user  IPv4 TCP 192.168.1.1:8080 (LISTEN)

            let command = components[0]
            let pidString = components[1]
            let _ = components[4]  // type field not used anymore
            let name = components[8]

            // Parse PID
            guard let pid = Int(pidString) else { continue }

            // Find protocol in components (it should be TCP or UDP)
            let protocolType: PortInfo.PortProtocol
            if components.count > 4 {
                // Check for TCP/UDP in components
                if components.contains("TCP") {
                    protocolType = .tcp
                } else if components.contains("UDP") {
                    protocolType = .udp
                } else {
                    protocolType = .tcp // Default to TCP if not found
                }
            } else {
                protocolType = .tcp // Default to TCP
            }

            // Parse port from NAME field
            guard let port = extractPort(from: name) else { continue }

            // Extract state if available
            let state = components.count > 9 ? components[9].trimmingCharacters(in: CharacterSet(charactersIn: "()")) : nil

            // Get process name
            let processName = extractProcessName(from: command)

            let portInfo = PortInfo(
                port: port,
                portProtocol: protocolType,
                processName: processName,
                processID: pid,
                command: command,
                state: state
            )

            portInfos.append(portInfo)
        }

        return portInfos
    }

    private func extractPort(from name: String) -> Int? {
        // Examples of name field:
        // "127.0.0.1:3000"
        // "*:22"
        // "192.168.1.1:8080"
        // "fe80::1:5353"
        // "::1:631"

        // Use regex to extract port number
        let pattern = ":(\\d+)"
        guard let range = name.range(of: pattern, options: .regularExpression),
              let portString = name[range].components(separatedBy: ":").last,
              let port = Int(portString) else { return nil }

        return port
    }

    private func extractProcessName(from command: String) -> String {
        // Remove common application suffixes and get clean name
        let cleanName = command.components(separatedBy: "/").last ?? command
        var name = cleanName.replacingOccurrences(of: ".app", with: "")

        // Remove hexadecimal encoded characters (like \x20H) - note: lsof sometimes adds extra chars
        name = name.replacingOccurrences(of: "\\x[0-9a-fA-F]{2}[a-zA-Z]*", with: "", options: .regularExpression)

        // Also handle standard hex escapes
        let pattern = "\\\\(x[0-9a-fA-F]{2})"
        while let range = name.range(of: pattern, options: .regularExpression) {
            let hexStr = String(name[range])
            let hexChars = hexStr.dropFirst(2) // Remove \x
            if let hexValue = Int(hexChars, radix: 16),
               let unicodeScalar = UnicodeScalar(hexValue) {
                name.replaceSubrange(range, with: String(Character(unicodeScalar)))
            }
        }

        // Trim whitespace and trailing characters
        name = name.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove any trailing non-alphanumeric characters that might be left
        while let lastChar = name.last, !lastChar.isLetter && !lastChar.isNumber {
            name = String(name.dropLast())
        }

        return name
    }
}