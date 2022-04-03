#!/bin/sh

echo "Cleaning up..."

pushd ~/Downloads
echo " "

# pictures...
echo "Images/Pictures..."
mv 2> /dev/null *.jpg* ~/Pictures
mv 2> /dev/null *.png* ~/Pictures
mv 2> /dev/null *.tiff* ~/Pictures

# archives
echo "Archives..."
mv 2> /dev/null *.zip* ~/Archives
mv 2> /dev/null *.tar* ~/Archives
mv 2> /dev/null *.dmg* ~/Archives
mv 2> /dev/null *.iso* ~/Archives

# documents
echo "Documents..."
mv 2> /dev/null *.pdf* ~/Archives
mv 2> /dev/null *.doc* ~/Archives
mv 2> /dev/null *.txt* ~/Archives

# dev...
mv 2> /dev/null * ~/Development

echo " "
popd

echo "Done"
exit 0
