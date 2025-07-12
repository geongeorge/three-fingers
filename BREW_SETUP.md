# ThreeFingers Homebrew Setup

## Step 1: Upload Release to GitHub

1. Go to: https://github.com/geongeorge/three-fingers/releases
2. Create new release: v1.0.0
3. Upload: `release/threefingers-1.0.0.tar.gz`

## Step 2: Test Formula Locally

```bash
# Test install from local file
brew install --build-from-source ./threefingers.rb

# Set up permissions
threefingers  # Run once to add to accessibility list
# Then: System Preferences → Privacy & Security → Privacy → Accessibility
# Enable 'threefingers' checkbox

# Start service
brew services start threefingers

# Test: Do 3-finger tap on trackpad

# Clean up
brew services stop threefingers
brew uninstall threefingers
```

## Step 3: Create Homebrew Tap

1. Create GitHub repo: `homebrew-threefingers`
2. Create folder: `Formula/`
3. Copy `threefingers.rb` to `Formula/threefingers.rb`
4. Commit and push

## Step 4: Users Install

```bash
# Add tap
brew tap geongeorge/threefingers

# Install
brew install threefingers

# Setup permissions (first time only)
threefingers  # Adds to accessibility list
# System Preferences → Privacy & Security → Privacy → Accessibility
# Enable 'threefingers'

# Start service
brew services start threefingers

# Test 3-finger tap!
```

## Troubleshooting

```bash
# Check service status
brew services list | grep threefingers

# View logs
tail -f $(brew --prefix)/var/log/threefingers.log

# Restart service
brew services restart threefingers
```
