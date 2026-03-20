#!/usr/bin/env bash
# macos/defaults.sh — macOS system preferences
# Run with: make macos  (or: bash macos/defaults.sh)
#
# Changes take effect immediately for most settings.
# Some require logging out or restarting the affected app.
set -euo pipefail

echo "Applying macOS defaults..."

# ── System ────────────────────────────────────────────────────────────────────

# Disable the startup chime
sudo nvram StartupMute=%01

# Enable dark mode
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"

# Expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Expand print panel by default
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Save to disk (not iCloud) by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Disable automatic termination of inactive apps
defaults write NSGlobalDomain NSDisableAutomaticTermination -bool true

# ── Input ────────────────────────────────────────────────────────────────────

# Enable tap-to-click for the trackpad
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Enable full keyboard access for all controls (Tab through dialog buttons)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Disable press-and-hold for keys (enables key repeat)
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Fast key repeat
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Disable smart quotes and dashes (useful in terminal/code editors)
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Disable autocorrect
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# ── Finder ───────────────────────────────────────────────────────────────────

# Show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show hidden files by default
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show path bar and status bar
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true

# Use column view as default
defaults write com.apple.finder FXPreferredViewStyle -string "clmv"

# New Finder windows show the home folder
defaults write com.apple.finder NewWindowTarget -string "PfHm"
defaults write com.apple.finder NewWindowTargetPath -string "file://$HOME/"

# Keep folders on top when sorting
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# Disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Don't create .DS_Store files on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# ── Dock ─────────────────────────────────────────────────────────────────────

# Auto-hide the Dock
defaults write com.apple.dock autohide -bool true

# Remove the auto-hide delay
defaults write com.apple.dock autohide-delay -float 0

# Shorten the show/hide animation
defaults write com.apple.dock autohide-time-modifier -float 0.15

# Don't show recent apps in the Dock
defaults write com.apple.dock show-recents -bool false

# ── Screenshots ──────────────────────────────────────────────────────────────

# Save screenshots to Desktop
defaults write com.apple.screencapture location -string "$HOME/Desktop"

# Save as PNG (not jpg)
defaults write com.apple.screencapture type -string "png"

# Disable shadow in screenshots
defaults write com.apple.screencapture disable-shadow -bool true

# ── Safari ───────────────────────────────────────────────────────────────────

# Enable the developer menu and Web Inspector
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true

# Block pop-up windows
defaults write com.apple.Safari WebKitJavaScriptCanOpenWindowsAutomatically -bool false

# ── TextEdit ─────────────────────────────────────────────────────────────────

# Use plain text mode by default
defaults write com.apple.TextEdit RichText -int 0

# Open and save files as UTF-8
defaults write com.apple.TextEdit PlainTextEncoding -int 4
defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4

# ── Activity Monitor ─────────────────────────────────────────────────────────

# Show all processes
defaults write com.apple.ActivityMonitor ShowCategory -int 0

# ── Kill affected apps ────────────────────────────────────────────────────────

for app in "Finder" "Dock" "Safari" "SystemUIServer"; do
  killall "$app" &>/dev/null || true
done

echo "Done. Some changes require a logout or restart to take effect."
