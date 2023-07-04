#!/bin/sh

echo "Uninstalling Visual Studio Code"

sudo rm -rf "/Applications/Visual Studio.app"

rm -rf ~/Library/Caches/VisualStudio
rm -rf ~/Library/Preferences/VisualStudio
rm -rf ~/Library/Preferences/Visual\ Studio
rm -rf ~/Library/Logs/VisualStudio
rm -rf ~/Library/VisualStudio
rm -rf ~/Library/Preferences/Xamarin/
rm -rf ~/Library/Application\ Support/VisualStudio
rm -rf ~/.vscode

brew uninstall visual-studio-code

echo "Done..."

exit 0
