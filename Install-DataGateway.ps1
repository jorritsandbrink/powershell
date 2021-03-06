# Script based on https://www.powershellgallery.com/packages/DataGateway/3000.37.39/Content/Samples%5CInstallAndAddDataGateway-Sample.ps1
# Requires Service Principal with proper permissions – see https://docs.microsoft.com/en-us/powershell/module/datagateway.profile/connect-datagatewayserviceaccount?view=datagateway-ps#creating-an-azure-ad-application

Param(
  [Parameter(Mandatory = $true)]
  [string]
  $ApplicationId,
  [Parameter(Mandatory = $true)]
  [string]
  $TenantId,
  [Parameter(Mandatory = $true)]
  [string]
  $ClientSecret,
  [Parameter(Mandatory = $true)]
  [string]
  $RecoveryKey,
  [Parameter(Mandatory = $true)]
  [string]
  $GatewayName,
  [Parameter()]
  [Guid]
  $AdminObjectId
)

$VerbosePreference = "Continue"

$transcriptfile = Join-Path -Path $PSScriptRoot -ChildPath 'transcript0.txt'
if (Test-Path -Path $transcriptfile) {
	Start-Transcript -Path $transcriptfile -Append -Force
}
else {
	Start-Transcript -Path $transcriptfile -Force
}

# Create SecureString objects
$ClientSecretSecure = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
$RecoveryKeySecure = ConvertTo-SecureString $RecoveryKey -AsPlainText -Force

# Install DataGateway module
Write-Host "Install powershell module 'DataGateway'"
$module = Get-InstalledModule -Name DataGateway -ErrorAction SilentlyContinue
if($module) {
	Write-Verbose ("Module 'DataGateway' already installed: {0}" -f $module.InstalledLocation)
} else {
	Write-Verbose ("Module 'DataGateway' not found.")
	Install-Module -Name DataGateway -Scope AllUsers -Force
}

Write-Host "Import powershell module 'DataGateway'"
Import-Module -Name DataGateway

# Connect Service Principal
Write-Host "Connect Service Principal"
Connect-DataGatewayServiceAccount -ApplicationId $ApplicationId -ClientSecret $ClientSecretSecure -Tenant $TenantId | Out-Null

# Download and run gateway installer
Install-DataGateway -AcceptConditions

# Thrown an error if not logged in
Get-DataGatewayAccessToken | Out-Null

# Create a gateway cluster
Write-Host "Create gateway cluster"
$addDataGatewayClusterArguments = @{
  RecoveryKey = $RecoveryKeySecure;
  GatewayName = $GatewayName;
}
$newGatewayClusterId = (Add-DataGatewayCluster @addDataGatewayClusterArguments).GatewayObjectId

# Add gateway cluster admin
Write-Host "Add gateway cluster admin"
if ($null -ne $AdminObjectId) {
  $addDataGatewayClusterUserArguments = @{
    GatewayClusterId       = $newGatewayClusterId;
    PrincipalObjectId      = $AdminObjectId;
    Role                   = "Admin";
    AllowedDataSourceTypes = $null;
  }
  Add-DataGatewayClusterUser @addDataGatewayClusterUserArguments
}

Stop-Transcript
