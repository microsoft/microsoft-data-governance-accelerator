#az login 
#az account set -s "jorampon internal consumption"

#If you want to log in as the service principal
# $spcheck = az ad sp list --filter "displayname eq '$env:AdsOpts_CD_ServicePrincipals_DeploymentSP_Name'" | ConvertFrom-Json
# az login --service-principal -u $spcheck[0].appId -p '##########' --tenant microsoft.onmicrosoft.com


[Environment]::SetEnvironmentVariable("ENVIRONMENT_NAME", "development")
if (Test-Path -PathType Container -Path "../bin/"){New-Item -ItemType Directory -Force -Path "../bin"}
New-Item -Path "../bin/" -Name "GitEnv.txt" -type "file" -value "" -force   
. .\Steps\PushEnvFileIntoVariables.ps1
ParseEnvFile("$env:ENVIRONMENT_NAME")
Invoke-Expression -Command  ".\Steps\CD_SetResourceGroupHash.ps1"


#Load Secrets into Environment Variables 
ParseSecretsFile ($SecretFile)

