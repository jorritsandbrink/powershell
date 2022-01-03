Param(
  [Parameter(Mandatory = $true)]
  [string]
  $ApplicationId,
  [Parameter(Mandatory = $true)]
  [SecureString]
  $ClientSecret
)

Write-Output $ApplicationId
Write-Output $ClientSecret
