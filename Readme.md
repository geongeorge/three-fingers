# Three fingers

- 3 finger tap for middle click on macos

## Test homebrew formula locally

```bash
# Navigate to your release directory
cd release

# Install directly from the local formula
brew install --build-from-source ./threefingers.rb

# Test the binary
threefingers --help

# Test permissions setup
threefingers
# (This should add it to accessibility list and show instructions)

# Test as service
brew services start threefingers
brew services list | grep threefingers

# Test functionality
# Do a 3-finger tap on your trackpad!

# Check logs
tail -f $(brew --prefix)/var/log/threefingers.log

# Clean up when done
brew services stop threefingers
brew uninstall threefingers
```