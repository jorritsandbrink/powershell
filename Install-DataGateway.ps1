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

# Create SecureString objects
$ClientSecretSecure = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
$RecoveryKeySecure = ConvertTo-SecureString $RecoveryKey -AsPlainText -Force

# Install DataGateway module
Write-Host "Install DataGateway powershell module"
Install-Module -Name DataGateway -Force

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
