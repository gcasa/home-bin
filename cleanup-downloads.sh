#!/bin/sh

echo "Cleaning up... Downloads"
echo " "

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
mv 2> /dev/null *.pkg* ~/Archives

# Documents
echo "Documents..."
mv 2> /dev/null *.pdf* ~/Archives
mv 2> /dev/null *.doc* ~/Archives
mv 2> /dev/null *.txt* ~/Archives

# Apps
echo "Applications..."
mv 2> /dev/null *.app ~/Applications

# All else in trash...
echo "Trash..."
mv 2> /dev/null * ~/.Trash

echo " "
popd

echo "Cleaning up... Desktop"
echo " "

pushd ~/Desktop

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
mv 2> /dev/null *.pkg* ~/Archives

# Documents
echo "Documents..."
mv 2> /dev/null *.pdf* ~/Archives
mv 2> /dev/null *.doc* ~/Archives
mv 2> /dev/null *.txt* ~/Archives

# Apps
echo "Applications..."
mv 2> /dev/null *.app ~/Applications

popd

echo "Done"
exit 0
