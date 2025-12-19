import SwiftUI

struct ProcessGroupView: View {
    let process: ProcessInfo
    let onTerminate: () -> Void
    @Binding var isExpanded: Bool

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            LazyVStack(alignment: .leading, spacing: 4) {
                ForEach(process.ports.sorted { $0.port < $1.port }, id: \.id) { port in
                    PortDetailRowView(port: port)
                }
            }
            .padding(.leading, 16)
        } label: {
            ProcessRowView(process: process) {
                onTerminate()
            }
        }
        }
}

struct ProcessRowView: View {
    let process: ProcessInfo
    let onTerminate: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(process.displayText)
                        .font(.body)
                        .fontWeight(.medium)

                    Spacer()

                    HStack(spacing: 4) {
                        if process.hasTCPPorts {
                            Text("TCP")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(3)
                        }
                        if process.hasUDPPorts {
                            Text("UDP")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.green)
                                .cornerRadius(3)
                        }
                    }
                }

                HStack {
                    if process.portCount > 0 {
                        Text(process.portSummary)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .monospacedDigit()

                        if process.portCount > 3 {
                            Text("(\(process.portCount) ports)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }

                    if !process.command.isEmpty && process.command != process.processName {
                        Text(process.command)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()
                }
            }

            Button(action: onTerminate) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.title2)
            }
            .buttonStyle(.borderless)
            .disabled(process.isSystemProcess)
            .help(process.isSystemProcess ? "System process - cannot terminate" : "Terminate process")
        }
        .padding(.vertical, 4)
    }
}

struct PortDetailRowView: View {
    let port: PortInfo

    var body: some View {
        HStack {
            Text(String(port.port))
                .font(.monospaced(.body)())
                .fontWeight(.medium)
                .frame(minWidth: 50, alignment: .leading)

            Text(port.portProtocol.rawValue)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(port.portProtocol == .tcp ? Color.blue.opacity(0.2) : Color.green.opacity(0.2))
                .foregroundColor(port.portProtocol == .tcp ? .blue : .green)
                .cornerRadius(4)

            if let state = port.state {
                Text(state)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(3)
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }
}