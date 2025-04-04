#!/bin/bash
# My first script
echo Downloading zip!
wget https://ia800208.us.archive.org/29/items/Open_Sonic/OpenSonicWin.zip
unzip OpenSonicWin.zip -d ~/Desktop/opensonic
cd ~/desktop/opensonic	
wine opensonic.exe
