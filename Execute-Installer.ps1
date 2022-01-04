[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)][string]$msiDownloadURL = "https://github.com/PowerShell/PowerShell/releases/download/v7.2.1/PowerShell-7.2.1-win-x64.msi",
    [Parameter(Mandatory = $false)][string]$msiFolder = "C:\Temp",
    [Parameter(Mandatory = $false)][string]$msiFileName = "installer.msi"
)

function Download-Installer([string]$downloadUrl, [string]$msiFolder, [string]$msiFileName)
{
    #Create folder if it does not exist
    if (-not (Test-Path $msiFolder)) {
       New-Item -Path $msiFolder -ItemType Directory | Out-Null
    }

    Write-Host "Downloading the MSI from $downloadUrl to $msiFolder on $ENV:COMPUTERNAME..." -ForegroundColor Cyan
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $downloadUrl -UseBasicParsing -OutFile $msiFolder\$msiFileName | Out-Null
    $ProgressPreference = 'Continue'
    return
}

function Execute-Installer([string] $msiPath)
{
    Write-Host "Start MSI execution"
    
    $process = Start-Process "msiexec.exe" "/i $msiPath /quiet /passive" -Wait -PassThru
    if ($process.ExitCode -ne 0)
    {
        throw "Failed to execute installer. msiexec exit code: $($process.ExitCode)"
    }
    Start-Sleep -Seconds 30	

    Write-Host "MSI executed succesfully"
}

Download-Installer $msiDownloadURL $msiFolder $msiFileName
Execute-Installer $msiFolder\$msiFileName
