
######################################################
### Continuous Deployment                         ####
######################################################Write-Host ([Environment]::GetEnvironmentVariable("AdsOpts_CI_Enable"))
if (([Environment]::GetEnvironmentVariable("AdsOpts_CD_EnableDeploy")) -eq "True")
{
    Write-Host "Starting CD.."

    Invoke-Expression -Command  "./Steps/CD_DeployPurview.ps1"

    Write-Host "Finishing CD.."
}
else 
{

    Write-Host "CD_1a_DeployServices.ps1 skipped as flag in environment file is set to false" -ForegroundColor Yellow
}

 #Invoke-Expression -Command  ".\Cleanup_RemoveAll.ps1"