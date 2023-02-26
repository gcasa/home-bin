#!/bin/sh

# Update brew...

export PATH=/usr/local/bin:${PATH}

echo "Updating..."
brew update
brew upgrade
brew cleanup
echo "Done..."
