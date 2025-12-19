import Foundation

class ProcessManager {
    static func terminateProcess(_ portInfo: PortInfo) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            // First try SIGTERM (15) for graceful termination
            let process = Process()
            process.launchPath = "/bin/kill"
            process.arguments = ["-15", String(portInfo.processID)]

            do {
                try process.run()
                process.waitUntilExit()

                if process.terminationStatus == 0 {
                    continuation.resume()
                } else {
                    // If SIGTERM fails, explain why
                    let error = NSError(
                        domain: "ProcessManager",
                        code: Int(process.terminationStatus),
                        userInfo: [
                            NSLocalizedDescriptionKey: "Failed to terminate process \(portInfo.processName) (PID: \(portInfo.processID)). You may not have sufficient permissions."
                        ]
                    )
                    continuation.resume(throwing: error)
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    static func forceTerminateProcess(_ portInfo: PortInfo) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            // Use SIGKILL (9) for force termination
            let process = Process()
            process.launchPath = "/bin/kill"
            process.arguments = ["-9", String(portInfo.processID)]

            do {
                try process.run()
                process.waitUntilExit()

                if process.terminationStatus == 0 {
                    continuation.resume()
                } else {
                    let error = NSError(
                        domain: "ProcessManager",
                        code: Int(process.terminationStatus),
                        userInfo: [
                            NSLocalizedDescriptionKey: "Failed to force terminate process \(portInfo.processName) (PID: \(portInfo.processID))."
                        ]
                    )
                    continuation.resume(throwing: error)
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    static func isSystemProcess(_ portInfo: PortInfo) -> Bool {
        // List of known system process names that shouldn't be terminated
        let systemProcesses = [
            "kernel_task",
            "launchd",
            "syslogd",
            "mDNSResponder",
            "configd",
            "distnoted",
            "loginwindow",
            "WindowServer",
            "UserEventAgent",
            "taskgated"
        ]

        return systemProcesses.contains(portInfo.processName.lowercased()) ||
               portInfo.processID < 100 // Generally low PIDs are system processes
    }
}