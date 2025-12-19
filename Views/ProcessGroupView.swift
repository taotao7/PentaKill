import SwiftUI

struct ProcessGroupView: View {
    let process: ProcessInfo
    let onTerminate: () -> Void
    @Binding var isExpanded: Bool

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(process.ports.sorted { $0.port < $1.port }, id: \.id) { port in
                    PortDetailRowView(port: port)
                    if port.id != process.ports.sorted(by: { $0.port < $1.port }).last?.id {
                        Divider()
                            .padding(.leading, 36)
                    }
                }
            }
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .cornerRadius(8)
            .padding(.top, 4)
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
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: "gearshape.2")
                    .font(.system(size: 18))
                    .foregroundColor(.accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center) {
                    Text(process.displayText)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    HStack(spacing: 6) {
                        if process.hasTCPPorts {
                            Text("TCP")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.15))
                                .foregroundColor(.blue)
                                .clipShape(Capsule())
                        }
                        if process.hasUDPPorts {
                            Text("UDP")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.15))
                                .foregroundColor(.green)
                                .clipShape(Capsule())
                        }
                    }
                }

                HStack(spacing: 12) {
                    Label {
                        Text(process.portSummary)
                            .monospacedDigit()
                    } icon: {
                        Image(systemName: "network")
                            .font(.caption2)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)

                    if !process.command.isEmpty && process.command != process.processName {
                        Label {
                            Text(process.command)
                                .lineLimit(1)
                        } icon: {
                            Image(systemName: "terminal")
                                .font(.caption2)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }

            Button(action: onTerminate) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(Color.red.opacity(0.8))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(process.isSystemProcess)
            .opacity(process.isSystemProcess ? 0.3 : 1.0)
            .help(process.isSystemProcess ? "System process - cannot terminate" : "Terminate process")
        }
        .padding(.vertical, 8)
    }
}

struct PortDetailRowView: View {
    let port: PortInfo

    var body: some View {
        HStack {
            Image(systemName: "arrow.turn.down.right")
                .foregroundColor(.secondary.opacity(0.3))
                .padding(.leading, 8)
            
            Text(String(port.port))
                .font(.monospaced(.callout)())
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .frame(minWidth: 50, alignment: .leading)

            Text(port.portProtocol.rawValue)
                .font(.caption)
                .fontWeight(.bold)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(port.portProtocol == .tcp ? Color.blue.opacity(0.1) : Color.green.opacity(0.1))
                .foregroundColor(port.portProtocol == .tcp ? .blue : .green)
                .clipShape(RoundedRectangle(cornerRadius: 4))

            if let state = port.state {
                Text(state)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
    }
}