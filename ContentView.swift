import SwiftUI

struct ContentView: View {
    @StateObject private var portScanner = PortScanner()
    @State private var searchText = ""
    @State private var selectedPortProtocol: PortInfo.PortProtocol? = nil
    @State private var showingKillConfirmation = false
    @State private var selectedProcess: ProcessInfo?
    @State private var expandedProcesses: Set<String> = []
    @State private var refreshInterval: TimeInterval = 5.0

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
            HStack(spacing: 16) {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.1))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "network")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.accentColor)
                    }
                    
                    Text("PentaKill")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                Spacer()

                // Refresh button
                Button(action: {
                    Task {
                        await portScanner.scanPorts()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .medium))
                            .rotationEffect(.degrees(portScanner.isScanning ? 360 : 0))
                            .animation(portScanner.isScanning ? .linear(duration: 1).repeatForever(autoreverses: false) : .easeOut(duration: 0.2), value: portScanner.isScanning)
                        
                        Text(portScanner.isScanning ? "Scanning..." : "Refresh")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.accentColor.opacity(0.1))
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.accentColor.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(portScanner.isScanning)

                // Quit button
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "power")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.red)
                        .frame(width: 28, height: 28)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Quit PentaKill")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial)
            
            Divider()

            // Search and Filter
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                    
                    TextField("Search processes, PIDs or ports...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.body)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 14))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(10)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )

                HStack {
                    Text("Filter:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    Picker("Protocol", selection: $selectedPortProtocol) {
                        Text("All").tag(nil as PortInfo.PortProtocol?)
                        ForEach(PortInfo.PortProtocol.allCases, id: \.self) { protocolType in
                            Text(protocolType.rawValue).tag(protocolType as PortInfo.PortProtocol?)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 200)
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(nsColor: .windowBackgroundColor))

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
                
                Menu {
                    Button("1s") { refreshInterval = 1.0 }
                    Button("3s") { refreshInterval = 3.0 }
                    Button("5s") { refreshInterval = 5.0 }
                    Button("10s") { refreshInterval = 10.0 }
                    Divider()
                    Button("Pause") { refreshInterval = 0 }
                } label: {
                    HStack(spacing: 4) {
                        Text(refreshInterval > 0 ? "Auto-refresh: \(Int(refreshInterval))s" : "Auto-refresh: Paused")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.up")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .frame(width: 400, height: 500)
        .onChange(of: refreshInterval) { newValue in
            portScanner.setRefreshInterval(newValue)
        }
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