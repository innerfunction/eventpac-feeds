#!/bin/bash

if [ -z "$1" ]; then
    echo "Please provide a new project name"
    exit 1
fi

if [ -f "$1" ]; then
    echo "Can't create project named '$1', a file of that name already exists"
    exit 1
fi

if [ -d "$1" ]; then
    echo "A project named '$1' already exists"
    exit 1
fi

echo "Creating client $1..."

start=$(pwd)

scriptPath="$(dirname "$0")"
path="$scriptPath/../$2"

# Copy empty project to new location.
echo "  * copying files to $path..."
mkdir -p $path
cp -r $scriptPath/../EmptyProject/* $path

# Rename iOS project directories
echo "  * editing Xcode project settings..."
cd $path/ios
mv EmptyProject $1
mv EmptyProject.xcodeproj $1.xcodeproj
#mv $1.xcodeproj/project.xcworkspace/xcshareddata/EmptyProject.xccheckout $1.xcodeproj/project.xcworkspace/xcshareddata/$1.xccheckout

# Edit xcode project settings
sed -i '' "s/\EmptyProject/$1/g" $1.xcodeproj/project.pbxproj 
sed -i '' "s/\EmptyProject/$1/g" $1.xcodeproj/project.xcworkspace/contents.xcworkspacedata
#sed -i '' "s/\EmptyProject/$1/g" $1.xcodeproj/project.xcworkspace/xcshareddata/$1.xccheckout
#sed -i '' "s/\EmptyProject/$1/g" $1/Base.lproj/LaunchScreen.xib
sed -i '' "s/\EmptyProject/$1/g" $1/main.m

# Create dirs symlinks
cd Externals
ln -s ../../../../EPCore/ios EPCore
cd ../$1
ln -s ../../common
mkdir images

# Change to Android project
echo "  * editing Eclipse project settings..."
cd $path/and

# Edit project manifest
packagename=$(echo $1|tr '[:upper:]' '[:lower:]')
sed -i '' "s/emptyproject/$packagename/g" AndroidManifest.xml
sed -i '' "s/EmptyProject/$1/g" .project
sed -i '' "s/EmptyProject/$1/g" res/values/strings.xml

# Create symlinks
cd assets
ln -s ../../common

# Rename project source code package
cd ../src/com/eventpac/client
mv emptyproject $packagename
cd $packagename
sed -i '' "s/emptyproject/$packagename/g" EPApplication.java

# Return to start directory
cd $start
echo "Done"
