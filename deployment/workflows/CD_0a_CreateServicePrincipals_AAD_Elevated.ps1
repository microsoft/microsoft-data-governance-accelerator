$error.clear()
#First Create the Resource Group 
Invoke-Expression -Command  ".\Steps\CD_DeployResourceGroup.ps1" 

########################################################################

###      SetUp Service Principals Required.. Need to run this part with elevated privileges

#########################################################################
if($env:AdsOpts_CD_ServicePrincipals_DeploymentSP_Enable -eq "True")
{
    Write-Host "Creating Deployment Service Principal" -ForegroundColor Yellow
    $subid =  ((az account show -s $env:AdsOpts_CD_ResourceGroup_Subscription) | ConvertFrom-Json).id

    $spcheck = az ad sp list --filter "displayname eq '$env:AdsOpts_CD_ServicePrincipals_DeploymentSP_Name'" | ConvertFrom-Json
    if ($null -eq $spcheck)
    {
        Write-Host "Deployment Principal does not exist so creating now." -ForegroundColor Yellow
        $SP = az ad sp create-for-rbac --name $env:AdsOpts_CD_ServicePrincipals_DeploymentSP_Name --role contributor --scopes /subscriptions/$subid/resourceGroups/$env:AdsOpts_CD_ResourceGroup_Name    
    }
    else {
        Write-Host "Deployment Prinicpal Already Exists So Just Adding Contributor Role on Resource Group" -ForegroundColor Yellow
        az role assignment create --assignee $spcheck[0].objectId --role "Contributor" --scope  /subscriptions/$subid/resourceGroups/$env:AdsOpts_CD_ResourceGroup_Name   
    }
}


#Check Status of Errors 

Write-Host "Script Complete Please Check below for Errors:" -ForegroundColor Yellow
Write-Host $error