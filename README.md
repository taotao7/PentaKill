# PentaKill

A macOS system tray application for monitoring and managing network ports used by applications.

## Preview

![Example](https://github.com/taotao7/PentaKill/blob/main/example.png)

## Features

- **Real-time Port Monitoring**: Automatically scans and displays all active network ports
- **System Tray Integration**: Quick access from the macOS menu bar
- **Process Management**: Terminate applications directly from the interface
- **Search & Filter**: Find specific processes or ports quickly
- **Protocol Support**: Monitor both TCP and UDP ports
- **Dark Mode**: Adapts to your macOS appearance settings

## Requirements

- macOS 13.0 or later
- Permission to access system information (will be requested on first launch)

## Building

### Using Xcode

1. Open `PentaKill.xcodeproj` in Xcode
2. Build and run the project

### Using Swift Package Manager

```bash
cd PentaKill
swift build
```

## Usage

1. Launch the application - it will appear in your menu bar
2. Click the network icon to view active ports
3. Use the search bar to find specific processes or ports
4. Click the X button next to any process to terminate it
5. The list automatically refreshes every 5 seconds

## Permissions

The application requires system permissions to:
- List network connections
- Terminate processes

These permissions will be requested automatically when needed.

## Security Notes

- System processes are protected and cannot be terminated
- All process terminations require confirmation
- The app uses standard macOS APIs for security

## Troubleshooting

### No ports showing
- Make sure you've granted the necessary permissions
- Try clicking the refresh button
- Check if any applications are actually using network ports

### Can't terminate a process
- Check if it's a system process (these are protected)
- Make sure you have sufficient permissions
- Some processes may require administrator rights

## Development

Built with:
- Swift 5.9
- SwiftUI for the interface
- Combine for reactive updates
- Native macOS APIs

## License

MIT License