# Homebrew Distribution Setup Guide

This guide will help you set up Homebrew distribution for ThreeFingers.

## 📋 Prerequisites

1. ✅ GitHub repository for ThreeFingers
2. ✅ Release tarball created (`threefingers-v1.0.0.tar.gz`)
3. ✅ Homebrew formula ready (`threefingers.rb`)

## 🚀 Step 1: Create GitHub Release

1. Go to your GitHub repository
2. Click "Releases" → "Create a new release"
3. Tag: `v1.0.0`
4. Title: `ThreeFingers v1.0.0`
5. Upload the tarball: `/tmp/threefingers-v1.0.0.tar.gz`
6. Publish the release

## 🍺 Step 2: Set Up Homebrew Tap

### Option A: Personal Tap (Recommended for start)

```bash
# Create a new repository called 'homebrew-tap'
# On GitHub: Create new repo → geongeorge/homebrew-tap

# Clone and set up
git clone https://github.com/geongeorge/homebrew-tap.git
cd homebrew-tap

# Copy the formula
cp /path/to/threefingers/threefingers.rb Formula/threefingers.rb

# Commit and push
git add Formula/threefingers.rb
git commit -m "Add ThreeFingers formula"
git push origin main
```

### Option B: Submit to Homebrew Core (For mature projects)

```bash
# Fork homebrew-core
# Add your formula to Formula/threefingers.rb
# Submit PR
```

## 🧪 Step 3: Test Installation

```bash
# Add your tap
brew tap geongeorge/tap

# Install ThreeFingers
brew install threefingers

# Test the installation
threefingers --help
threefingers setup
```

## 📦 Step 4: User Installation Experience

Once set up, users can install with:

```bash
# Add tap (one-time)
brew tap geongeorge/tap

# Install
brew install threefingers

# Setup permissions (interactive)
threefingers setup

# Start as service
brew services start threefingers
```

## 🔧 Formula Features

Your Homebrew formula includes:

✅ **Automatic Framework Installation**: Bundles OpenMultitouchSupportXCF.xcframework  
✅ **Service Integration**: `brew services start/stop/restart threefingers`  
✅ **Post-install Instructions**: Guides users through setup  
✅ **Proper Testing**: Validates installation works  
✅ **Logging**: Service logs to `/opt/homebrew/var/log/threefingers.log`  

## 🔄 Updating the Formula

When you release new versions:

1. Run `./create-release.sh` (updates version in script if needed)
2. Upload new tarball to GitHub releases
3. Update `threefingers.rb`:
   - Change `url` to new release
   - Update `sha256` with new hash
   - Update `version`
4. Commit and push to your homebrew-tap

## 📝 Advanced: Automatic Formula Updates

Consider setting up GitHub Actions to automatically update the formula when you create releases:

```yaml
# .github/workflows/update-formula.yml
name: Update Homebrew Formula
on:
  release:
    types: [published]
jobs:
  update-formula:
    runs-on: ubuntu-latest
    steps:
      - name: Update Homebrew Formula
        uses: dawidd6/action-homebrew-bump-formula@v3
        with:
          token: ${{ secrets.HOMEBREW_GITHUB_API_TOKEN }}
          tap: geongeorge/homebrew-tap
          formula: threefingers
```

## 🎯 Benefits of This Setup

- **Easy Installation**: One command install for users
- **Automatic Updates**: `brew upgrade` handles updates
- **Service Management**: Built-in service controls
- **Permission Handling**: Guided setup process
- **Framework Bundling**: No missing dependencies
- **Professional Distribution**: Follows Homebrew best practices

Your ThreeFingers app is now ready for professional distribution! 🎉
