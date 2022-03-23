$PurviewAccountName = "adsgfpv"

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


    Invoke-RestMethod -Uri "https://$PurviewAccountName.catalog.purview.azure.com/api/browse?api-version=2021-05-01-preview" -Authentication "Bearer" -Token $token -ContentType 'application/json' -Method "POST" -Body ($Body | ConvertTo-Json) | ConvertTo-Json -depth 100 | Out-File "..\bin\purview\$FileName.json"

    #$_.Value.count
}


#By Datasource
#Scans
$Datasources = Get-Content ../bin/purview/scan_readDatasources_GET.json  | ConvertFrom-Json

$Datasources.value | foreach { 
    $DS = $_.name    
    
    $FileName = "Scan_ScansByDatasource_$DS"
    $Uri = "https://$PurviewAccountName.scan.purview.azure.com/datasources/$DS/scans?api-version=2018-12-01-preview"

    Invoke-RestMethod -Uri $Uri -Authentication "Bearer" -Token $Ptoken -ContentType 'application/json' -Method "GET" | ConvertTo-Json -depth 100 | Out-File "..\bin\purview\$FileName.json"

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

Invoke-RestMethod -Uri "https://$PurviewAccountName.catalog.purview.azure.com/api/search/query?api-version=2021-05-01-preview" -Authentication "Bearer" -Token $Ptoken -ContentType 'application/json' -Method "POST" -Body ($Body | ConvertTo-Json) 

#| ConvertTo-Json -depth 100 | Out-File "..\bin\purview\$FileName.json"


Invoke-RestMethod -Uri "https://$PurviewAccountName.catalog.purview.azure.com/api/atlas/v2/entity/guid/37f8a9f7-18b7-4287-b7dd-b9722a2e6e76?api-version=2021-05-01-preview" -Authentication "Bearer" -Token $Ptoken -ContentType 'application/json' -Method "GET" -Body ($Body | ConvertTo-Json) 


Invoke-RestMethod -Uri "https://$PurviewAccountName.catalog.purview.azure.com/api/atlas/v2/entity/guid/9a484533-9c23-4e91-85d7-51f6f6f60000?api-version=2021-05-01-preview" -Authentication "Bearer" -Token $Ptoken -ContentType 'application/json' -Method "GET" -Body ($Body | ConvertTo-Json) 


Invoke-RestMethod -Uri "https://$PurviewAccountName.catalog.purview.azure.com/api/atlas/v2/entity/guid/9a484533-9c23-4e91-85d7-51f6f6f60005?api-version=2021-05-01-preview" -Authentication "Bearer" -Token $Ptoken -ContentType 'application/json' -Method "GET" -Body ($Body | ConvertTo-Json) 


$Body = @"
{
    "entities": [
        {
            "typeName": "column",
            "attributes": {
                "owner": null,
                "replicatedTo": null,
                "replicatedFrom": null,
                "qualifiedName": "https://adsdevdlsadsbn6dadsl.dfs.core.windows.net/datalakeraw/Tests/Azure Storage to Azure Storage/{N}/SalesLT.Customer.parquet#__tabular_schema//CompanyName",
                "name": "CompanyName",
                "description": null,
                "type": "UTF8"
            },          
            "status": "ACTIVE",            
            "collectionId": "adsgfpv"
        },
        {
            "typeName": "column",
            "attributes": {
                "owner": null,
                "replicatedTo": null,
                "replicatedFrom": null,
                "qualifiedName": "https://adsdevdlsadsbn6dadsl.dfs.core.windows.net/datalakeraw/Tests/Azure Storage to Azure Storage/{N}/SalesLT.Customer.parquet#__tabular_schema//CompanyName1",
                "name": "CompanyName1",
                "description": null,
                "type": "UTF8"
            },          
            "status": "ACTIVE",            
            "collectionId": "adsgfpv"
        },
        {
            "typeName": "column",
            "attributes": {
                "owner": null,
                "replicatedTo": null,
                "replicatedFrom": null,
                "qualifiedName": "https://adsdevdlsadsbn6dadsl.dfs.core.windows.net/datalakeraw/Tests/Azure Storage to Azure Storage/{N}/SalesLT.Customer.parquet#__tabular_schema//CompanyName2",
                "name": "CompanyName2",
                "description": null,
                "type": "UTF8"
            },          
            "status": "ACTIVE",            
            "collectionId": "adsgfpv"
        },
        {
            "typeName": "column",
            "attributes": {
                "owner": null,
                "replicatedTo": null,
                "replicatedFrom": null,
                "qualifiedName": "https://adsdevdlsadsbn6dadsl.dfs.core.windows.net/datalakeraw/Tests/Azure Storage to Azure Storage/{N}/SalesLT.Customer.parquet#__tabular_schema//CompanyName3",
                "name": "CompanyName3",
                "description": null,
                "type": "UTF8"
            },          
            "status": "ACTIVE",            
            "collectionId": "adsgfpv"
        },
        {
            "typeName": "column",
            "attributes": {
                "owner": null,
                "replicatedTo": null,
                "replicatedFrom": null,
                "qualifiedName": "https://adsdevdlsadsbn6dadsl.dfs.core.windows.net/datalakeraw/Tests/Azure Storage to Azure Storage/{N}/SalesLT.Customer.parquet#__tabular_schema//CompanyName4",
                "name": "CompanyName4",
                "description": null,
                "type": "UTF8"
            },          
            "status": "ACTIVE",            
            "collectionId": "adsgfpv"
        }
    ]
}

"@

$Body = $Body | ConvertFrom-JSON -Depth 10

Invoke-RestMethod -Uri "https://$PurviewAccountName.catalog.purview.azure.com/api/atlas/v2/entity/bulk?api-version=2021-07-01" -Authentication "Bearer" -Token $Ptoken -ContentType 'application/json' -Method "POST" -Body ($Body | ConvertTo-Json -Depth 10) 
