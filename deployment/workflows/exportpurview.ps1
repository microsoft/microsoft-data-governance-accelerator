$PurviewAccountName = "purviewtest12"

#Get Az ManagementToken
$Aztoken = az account get-access-token --resource=https://management.azure.com --query accessToken --output tsv
$Aztoken = $Aztoken | ConvertTo-SecureString -AsPlainText -Force

#Get Purview Token
$Ptoken = az account get-access-token --resource=https://purview.azure.net --query accessToken --output tsv
$Ptoken = $Ptoken | ConvertTo-SecureString -AsPlainText -Force


#Level 0 Gets
$Level0Gets = Import-Csv .\PurviewRestApi.csv |  Where-Object {($_.Level -eq 0) -and ($_.Enable -eq 1)}
foreach ($l in $Level0Gets){
    
    $token = $Ptoken
    $URI = "https://" + $PurviewAccountName + $l.APIURIDomain + $l.APIURIPath + "?" + $l.APIVersion
    if ($l.APIURIDomain -eq "management.azure.com")
    {
        $token = $Aztoken
        $URI = "https://" + $l.APIURIDomain + $l.APIURIPath + "?" + $l.APIVersion
    }    
        
    $FileName = $l.Category + "_" + $l.Command + "_" + $l.Method

    Write-Host $URI
    if($l.Method -eq "POST")
    {
        Invoke-RestMethod -Uri $URI -Authentication "Bearer" -Token $token -Method $l.Method -ContentType 'application/json' -Body "{}" | ConvertTo-Json -depth 100 | Out-File "..\bin\purview\$FileName.json"
    }
    else 
    {
        Invoke-RestMethod -Uri $URI -Authentication "Bearer" -Token $token -Method $l.Method | ConvertTo-Json -depth 100 | Out-File "..\bin\purview\$FileName.json"
    }
}


#By Entity Type
#Entities By Type
$TypeStats = Get-Content ../bin/purview/types_readStatistics_GET.json  | ConvertFrom-Json

$TypeStats.typeStatistics.PSObject.Properties | foreach { 
    $EntityType = $_.Name
    $Body = @{  "entityType"= $EntityType
                "limit"= 10
            }
    
    $FileName = "Discover_Browse_POST_$EntityType"


    Invoke-RestMethod -Uri "https://purviewtest12.catalog.purview.azure.com/api/browse?api-version=2021-05-01-preview" -Authentication "Bearer" -Token $token -ContentType 'application/json' -Method "POST" -Body ($Body | ConvertTo-Json) | ConvertTo-Json -depth 100 | Out-File "..\bin\purview\$FileName.json"

    #$_.Value.count
}


#By Datasource
#Scans
$Datasources = Get-Content ../bin/purview/scan_readDatasources_GET.json  | ConvertFrom-Json

$Datasources.value | foreach { 
    $DS = $_.name    
    
    $FileName = "Scan_ScansByDatasource_$DS"
    $Uri = "https://purviewtest12.scan.purview.azure.com/datasources/$DS/scans?api-version=2018-12-01-preview"

    Invoke-RestMethod -Uri $Uri -Authentication "Bearer" -Token $token -ContentType 'application/json' -Method "GET" | ConvertTo-Json -depth 100 | Out-File "..\bin\purview\$FileName.json"

    #$_.Value.count
}


$Body = @"
{
    "keywords": null,
    "limit": 1000,
    "filter": {
        "attributeName": "updateTime",
        "operator": "gt",
        "attributeValue": 00
    }
  }
"@

$Body = $Body | ConvertFrom-JSON

Invoke-RestMethod -Uri "https://purviewtest12.catalog.purview.azure.com/api/search/query?api-version=2021-05-01-preview" -Authentication "Bearer" -Token $token -ContentType 'application/json' -Method "POST" -Body ($Body | ConvertTo-Json) 

#| ConvertTo-Json -depth 100 | Out-File "..\bin\purview\$FileName.json"



