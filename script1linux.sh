#!/bin/bash
# My first script
echo Downloading zip!
wget https://archive.org/download/Open_Sonic/OpenSonicWin.zip
unzip OpenSonicWin.zip -d ~/Desktop/opensonic
cd ~/Desktop/opensonic	
wine opensonic.exe
