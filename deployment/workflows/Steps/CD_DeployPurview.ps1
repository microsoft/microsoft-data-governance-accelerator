
if ($env:AdsOpts_CD_Services_Purview_Enable -eq "True")
{
    Write-Host "Creating Data Purview"
    az deployment group create -g $env:AdsOpts_CD_Services_Purview_ResourceGroup --template-file ./../arm/purview.bicep --parameters location=$env:AdsOpts_CD_Services_Purview_Location purviewAccountName=$env:AdsOpts_CD_Services_Purview_Name 
}
else 
{
    Write-Host "Skipped Creation of Puview"
}


#Add Collection Admin
$cu = (az ad signed-in-user show | ConvertFrom-Json).objectId
$subid = (az account show -s $env:AdsOpts_CD_ResourceGroup_Subscription | ConvertFrom-Json).id
$token = (az account get-access-token --query accessToken --output tsv) | ConvertTo-SecureString -AsPlainText -Force
$restreply = Invoke-RestMethod -Uri "https://management.azure.com/subscriptions/$subid/resourceGroups/$env:AdsOpts_CD_Services_Purview_ResourceGroup/providers/Microsoft.Purview/accounts/$env:AdsOpts_CD_Services_Purview_Name/addRootCollectionAdmin?api-version=2021-07-01" -Authentication "Bearer" -Token $token -Method "POST" -Body "{'objectId': '$cu'}" -ContentType "application/json"


#Logic for getting token and calling Purview APIs below.
$token = az account get-access-token --resource=https://purview.azure.net --query accessToken --output tsv
$token = $token | ConvertTo-SecureString -AsPlainText -Force
$Params = @{
          Uri = "https://purviewtest12.scan.purview.azure.com/systemScanRulesets?api-version=2018-12-01-preview"
          Authentication = "Bearer"
          Token = $token
      }

Invoke-RestMethod @Params

$body = @{
    keywords = ''
    offset = 10
    limit =  10
    filter = ''
  }
  

$Params = @{
        Uri = "https://purviewtest12.catalog.purview.azure.com/api/atlas/v2/search/advanced"
        Authentication = "Bearer"
        Token = $token
        #ContentType = 'application/json' 
        #Body = ($body | ConvertTo-Json)
        Method = "POST"
    }


# Export Collections
Invoke-RestMethod -Uri "https://purviewtest12.purview.azure.com/collections?api-version=2019-11-01-preview" -Authentication "Bearer" -Token $token -Method "GET" | ConvertTo-Json -depth 100 | Out-File '.\bin\purview\ListCollections.json'


#Glossary
Invoke-RestMethod -Uri "https://purviewtest12.catalog.purview.azure.com/api/atlas/v2/glossary" -Authentication "Bearer" -Token $token -Method "GET" | ConvertTo-Json -depth 100 | Out-File '.\bin\purview\ListGlossaries.json'

Invoke-RestMethod -Uri "https://purviewtest12.catalog.purview.azure.com/api/atlas/v2/types/typedefs" -Authentication "Bearer" -Token $token -Method "GET" | ConvertTo-Json -depth 100 | Out-File '.\bin\purview\ListTypeDefs.json'

#Level 0 Gets
$Level0Gets = Import-Csv .\PurviewRestApi.csv |  Where-Object {$_.Level -eq 0}
foreach ($l in $Level0Gets){
    $URI = "https://purviewtest12" + $l.APIURIDomain + $l.APIURIPath + "?" + $l.APIVersion
    $FileName = $l.Category + "_" + $l.Command + "_" + $l.Method

    Write-Host $URI
    Invoke-RestMethod -Uri $URI -Authentication "Bearer" -Token $token -Method $l.Method | ConvertTo-Json -depth 100 | Out-File ".\bin\purview\$FileName.json"
}



# Export Catalog    
Invoke-RestMethod -Uri "https://purviewtest12.catalog.purview.azure.com/api/atlas/v2/search/advanced" -Authentication "Bearer" -Token $token -ContentType 'application/json' -Method "POST" -Body "{}" | ConvertTo-Json -depth 100 | Out-File '.\bin\purview\catalog.json'


# Export Classification Rules
Invoke-RestMethod -Uri "https://purviewtest12.scan.purview.azure.com/classificationrules?api-version=2018-12-01-preview" -Authentication "Bearer" -Token $token -Method "GET" | ConvertTo-Json -depth 100 | Out-File '.\bin\purview\classrules.json'

Invoke-RestMethod -Uri "https://purviewtest12.scan.purview.azure.com/scanrulesets?api-version=2018-12-01-preview" -Authentication "Bearer" -Token $token -Method "GET" | ConvertTo-Json -depth 100 | Out-File '.\bin\purview\ScanRuleSets.json'

Invoke-RestMethod -Uri "https://purviewtest12.scan.purview.azure.com/systemScanRulesets?api-version=2018-12-01-preview" -Authentication "Bearer" -Token $token -Method "GET" | ConvertTo-Json -depth 100 | Out-File '.\bin\purview\systemScanRulesets.json'

Invoke-RestMethod -Uri "https://purviewtest12.scan.purview.azure.com/systemScanRulesets?api-version=2018-12-01-preview" -Authentication "Bearer" -Token $token -Method "GET" | ConvertTo-Json -depth 100 | Out-File '.\bin\purview\systemScanRulesets.json'

Invoke-RestMethod -Uri "https://purviewtest12.scan.purview.azure.com/datasources?api-version=2018-12-01-preview" -Authentication "Bearer" -Token $token -Method "GET" | ConvertTo-Json -depth 100 | Out-File '.\bin\purview\datasources.json'

