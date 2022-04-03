#!/usr/bin/env bash

# $ crontab -e
# 0 0 25 * * * ~/bin/rubymine-reset-eval.sh

# Delete the JetBrains dir
rm -rf ~/Library/Application\ Support/JetBrains

# Directories
LIB=${HOME}/Library
PREFS=${LIB}/Preferences
CACHE=${LIB}/Caches
ASUPP=${LIB}/Application\ Support
SAPPS=${LIB}/Saved\ Application\ State
LOGS=${LIB}/Logs

# Remove all records in preferences and cached values
rm -rf ${PREFS}/RubyMine*
rm -rf ${PREFS}/JetBrains*
rm -rf ${PREFS}/WebStorm*
rm -rf ${PREFS}/com.jetbrains.*
rm -rf ${PREFS}/jetbrains.*
rm -rf ${CACHE}/RubyMine*
rm -rf ${CACHE}/JetBrains*
rm -rf ${CACHE}/WebStorm*
rm -rf ${ASUPP}/RubyMine*
rm -rf ${ASUPP}/JetBrains*
rm -rf ${ASUPP}/WebStorm*
rm -rf ${LOGS}/RubyMine*
rm -rf ${SAPPS}/*jetbrains*
rm -rf ${LOGS}/WebStorm*
rm -rf ${LIB}/JetBrains*

# Refresh the daemons which cache the preference values...
killall -9 cfprefsd
killall -9 Finder

echo "RubyMine, IntelliJ, WebStorm evaluation period has been reset. Please, buy it if you like it!"
exit 0
