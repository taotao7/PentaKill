import SwiftUI

struct ContentView: View {
    @StateObject private var portScanner = PortScanner()
    @State private var searchText = ""
    @State private var selectedPortProtocol: PortInfo.PortProtocol? = nil
    @State private var showingKillConfirmation = false
    @State private var selectedProcess: ProcessInfo?
    @State private var expandedProcesses: Set<String> = []

    private var filteredProcesses: [ProcessInfo] {
        var filtered = portScanner.processes

        if !searchText.isEmpty {
            filtered = filtered.filter { process in
                // Check if search matches process name, command, or any port
                process.processName.localizedCaseInsensitiveContains(searchText) ||
                process.command.localizedCaseInsensitiveContains(searchText) ||
                process.ports.contains { port in
                    String(port.port).contains(searchText)
                }
            }
        }

        if let portProtocol = selectedPortProtocol {
            filtered = filtered.filter { process in
                process.ports.contains { $0.portProtocol == portProtocol }
            }
        }

        return filtered
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "network")
                    .foregroundColor(.accentColor)
                Text("PentaKill")
                    .font(.headline)
                Spacer()

                // Refresh button
                Button(action: {
                    Task {
                        await portScanner.scanPorts()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .rotationEffect(.degrees(portScanner.isScanning ? 360 : 0))
                        .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: portScanner.isScanning)
                }
                .buttonStyle(.borderless)
                .disabled(portScanner.isScanning)

                // Quit button
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.borderless)
                .help("Quit PentaKill")
            }
            .padding()

            Divider()

            // Search and Filter
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search processes or ports...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal)

                HStack {
                    Text("Filter:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Picker("Protocol", selection: $selectedPortProtocol) {
                        Text("All").tag(nil as PortInfo.PortProtocol?)
                        ForEach(PortInfo.PortProtocol.allCases, id: \.self) { protocolType in
                            Text(protocolType.rawValue).tag(protocolType as PortInfo.PortProtocol?)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)

            Divider()

            // Process List
            if portScanner.isScanning && filteredProcesses.isEmpty {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Scanning ports...")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = portScanner.error {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text("Scan Error")
                        .font(.headline)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        Task {
                            await portScanner.scanPorts()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredProcesses.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "network.slash")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No Active Processes")
                        .font(.headline)
                    Text("No processes are currently using network ports")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filteredProcesses, id: \.id) { process in
                    ProcessGroupView(
                        process: process,
                        onTerminate: {
                            selectedProcess = process
                            showingKillConfirmation = true
                        },
                        isExpanded: Binding(
                            get: { expandedProcesses.contains(process.uniqueId) },
                            set: { isExpanded in
                                if isExpanded {
                                    expandedProcesses.insert(process.uniqueId)
                                } else {
                                    expandedProcesses.remove(process.uniqueId)
                                }
                            }
                        )
                    )
                }
                .listStyle(PlainListStyle())
            }

            // Footer
            Divider()
            HStack {
                Text("\(filteredProcesses.count) processes")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Auto-refresh: 5s")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
        }
        .frame(width: 400, height: 500)
        .alert("Terminate Process", isPresented: $showingKillConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Terminate", role: .destructive) {
                if let process = selectedProcess {
                    Task {
                        await terminateProcess(process)
                    }
                }
            }
        } message: {
            if let process = selectedProcess {
                Text("Are you sure you want to terminate \(process.processName) (PID: \(process.processID))? This will close \(process.portCount) ports.")
            }
        }
    }

    private func terminateProcess(_ process: ProcessInfo) async {
        do {
            // Terminate the process using any of its ports (they all have the same PID)
            if let firstPort = process.ports.first {
                try await ProcessManager.terminateProcess(firstPort)
                // Refresh the list after a short delay
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                await portScanner.scanPorts()
            }
        } catch {
            print("Failed to terminate process: \(error)")
            // You could show an error dialog here
        }
    }
}