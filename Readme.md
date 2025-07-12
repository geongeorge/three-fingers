# ThreeFingers

A macOS CLI tool that detects 3-finger trackpad gestures and generates middle-click events.

## ✨ Features

- **3-finger tap** → Middle click
- **Background service** - Runs automatically at startup
- **Easy setup** - Guided Accessibility permissions
- **Universal binary** - Works on Intel and Apple Silicon Macs

## 🚀 Installation

```bash
# Add the tap
brew tap geongeorge/tap

# Install threefingers
brew install threefingers

# Grant permissions (follow the prompts)
threefingers setup

# Start the service
brew services start threefingers
```

## 📖 Usage

- **Setup**: `threefingers setup` - Grant required Accessibility permissions
- **Start**: `brew services start threefingers` - Run as background service
- **Stop**: `brew services stop threefingers` - Stop the background service
- **Manual**: `threefingers daemon` - Run in foreground (for testing)

## 🔧 Requirements

- macOS 13.0 or later
- Accessibility permissions (granted during setup)

## 📝 License

MIT License - see LICENSE file for details.

---

*Made with ❤️ for Mac users who miss middle-click*