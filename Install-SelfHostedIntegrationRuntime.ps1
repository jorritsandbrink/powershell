[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)][string]$msiDownloadURL = "https://download.microsoft.com/download/E/4/7/E4771905-1079-445B-8BF9-8A1A075D8A10/IntegrationRuntime_5.13.8013.1.msi",
    [Parameter(Mandatory = $false)][string]$msiFolder = "C:\Temp",
    [Parameter(Mandatory = $false)][string]$msiFileName = "IntegrationRuntime.msi",
    [Parameter(Mandatory=$true)][string]$authKey,
    [Alias("port")][Parameter(Mandatory=$false)][string]$remoteAccessPort,
    [Alias("cert")][Parameter(Mandatory=$false)][string]$remoteAccessCertThumbprint
)

function Download-Installer([string]$downloadUrl, [string]$msiFolder, [string]$msiFileName)
{
    #Create folder if it does not exist
    if (-not (Test-Path $msiFolder)) {
       New-Item -Path $msiFolder -ItemType Directory | Out-Null
    }

    Write-Host "Downloading the MSI to $msiFolder on $ENV:COMPUTERNAME..." -ForegroundColor Cyan
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $downloadUrl -UseBasicParsing -OutFile $msiFolder\$msiFileName | Out-Null
    $ProgressPreference = 'Continue'
    return
}

function Install-Gateway([string] $msiPath)
{
    # uninstall any existing gateway
    UnInstall-Gateway

    Write-Host "Start Microsoft Integration Runtime installation"
    
    $process = Start-Process "msiexec.exe" "/i $msiPath /quiet /passive" -Wait -PassThru
    if ($process.ExitCode -ne 0)
    {
        throw "Failed to install Microsoft Integration Runtime. msiexec exit code: $($process.ExitCode)"
    }
    Start-Sleep -Seconds 30	

    Write-Host "Succeed to install Microsoft Integration Runtime"
}

function Register-Gateway([string] $key, [string] $port, [string] $cert)
{
    $cmd = Get-CmdFilePath

    if (![string]::IsNullOrEmpty($port))
    {
        Write-Host "Start to enable remote access."
        $process = Start-Process $cmd "-era $port $cert" -Wait -PassThru -NoNewWindow
        if ($process.ExitCode -ne 0)
        {
            throw "Failed to enable remote access. Exit code: $($process.ExitCode)"
        }
        Write-Host "Succeed to enable remote access."
    }

    Write-Host "Start to register Microsoft Integration Runtime with key: $key."
    $process = Start-Process $cmd "-k $key" -Wait -PassThru -NoNewWindow
    if ($process.ExitCode -ne 0)
    {
        throw "Failed to register Microsoft Integration Runtime. Exit code: $($process.ExitCode)"
    }
    Write-Host "Succeed to register Microsoft Integration Runtime."
}

function Check-WhetherGatewayInstalled([string]$name)
{
    $installedSoftwares = Get-ChildItem "hklm:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
    foreach ($installedSoftware in $installedSoftwares)
    {
        $displayName = $installedSoftware.GetValue("DisplayName")
        if($DisplayName -eq "$name Preview" -or  $DisplayName -eq "$name")
        {
            return $true
        }
    }

    return $false
}

function UnInstall-Gateway()
{
    $installed = $false
    if (Check-WhetherGatewayInstalled("Microsoft Integration Runtime"))
    {
        [void](Get-WmiObject -Class Win32_Product -Filter "Name='Microsoft Integration Runtime Preview' or Name='Microsoft Integration Runtime'" -ComputerName $env:COMPUTERNAME).Uninstall()
        $installed = $true
    }

    if (Check-WhetherGatewayInstalled("Microsoft Integration Runtime"))
    {
        [void](Get-WmiObject -Class Win32_Product -Filter "Name='Microsoft Integration Runtime Preview' or Name='Microsoft Integration Runtime'" -ComputerName $env:COMPUTERNAME).Uninstall()
        $installed = $true
    }

    if ($installed -eq $false)
    {
        Write-Host "Microsoft Integration Runtime is not installed."
        return
    }

    Write-Host "Microsoft Integration Runtime has been uninstalled from this machine."
}

function Get-CmdFilePath()
{
    $filePath = Get-ItemPropertyValue "hklm:\Software\Microsoft\DataTransfer\DataManagementGateway\ConfigurationManager" "DiacmdPath"
    if ([string]::IsNullOrEmpty($filePath))
    {
        throw "Get-InstalledFilePath: Cannot find installed File Path"
    }

    return (Split-Path -Parent $filePath) + "\dmgcmd.exe"
}

If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"
    Break
}

Download-Installer $msiDownloadURL $msiFolder $msiFileName
Install-Gateway $msiFolder\$msiFileName
Register-Gateway $authKey $remoteAccessPort $remoteAccessCertThumbprint
