Param(
  [Parameter(Mandatory = $true)]
  [string]
  $ApplicationId,
  [Parameter(Mandatory = $true)]
  [string]
  $ClientSecret
)

Write-Output $ApplicationId
Write-Output $ClientSecret
