      param(
            [string]$TenantId,
            [string]$ClientId,
            [string]$ClientSecret,
            [string]$Source_ClientId,
            [string]$Source_ClientSecret,
            [string]$Source_ServicePrincipal_ObjectId,
            [string]$Destination_ServicePrincipal_ObjectId,
            [string]$Create_Purview_Account_Flag,
            [string]$Source_Purview_Account,
            [string]$Destination_Purview_Account,
            [string]$Destination_Purview_Location,
            [string]$Destination_Purview_ResourceGroup,
            [string]$KeyVault,
            [string]$Source_IR,
            [string]$Destination_IR,
            [string]$SubscriptionId,
            [string]$Source_SQL_Endpoint,
            [string]$Destination_SQL_Endpoint,
            [string]$Source_Oracle_Host,
            [string]$Destination_Oracle_Host,
            [string]$Source_Oracle_Port,
            [string]$Destination_Oracle_Port,
            [string]$Source_Oracle_Service,
            [string]$Destination_Oracle_Service
      )
     
      #1. Get Token to Access Tenant
      write-host "Getting Token to Access Tenant"

      #Get Az ManagementToken
      $Aztoken = az account get-access-token --resource=https://management.azure.com --query accessToken --output tsv
      $Aztoken = $Aztoken | ConvertTo-SecureString -AsPlainText -Force
      
      #Get Purview Token - For Destination Purview Account
      $RequestAccessTokenUri = "https://login.microsoftonline.com/$TenantId/oauth2/token"
      $Resource = "https://purview.azure.net"
      $Body = "grant_type=client_credentials&client_id=$ClientId&client_secret=$ClientSecret&resource=$Resource"
      $Ptoken= Invoke-RestMethod -Method Post -Uri $RequestAccessTokenUri -Body $Body
      $token = $Ptoken.access_token | ConvertTo-SecureString -AsPlainText -Force
            
      #2. Get Objects from Source Purview Account 
      write-host "Getting Objects from Source Purview Account"

      #Get token to access source purview account            
      #$Source_ClientId = "$(Source_ServicePrincipalId)" # Service Principal ID
      #$Source_ClientSecret = "$(Source_ServicePrincipalSecret)" # Service Principal Secret
      #$RequestAccessTokenUri = "https://login.microsoftonline.com/$TenantId/oauth2/token"
      #$Resource = "https://purview.azure.net"
      $Source_Body = "grant_type=client_credentials&client_id=$Source_ClientId&client_secret=$Source_ClientSecret&resource=$Resource"
      $Source_PToken= Invoke-RestMethod -Method Post -Uri $RequestAccessTokenUri -Body $Source_Body
      $Source_Token = $Source_Ptoken.access_token | ConvertTo-SecureString -AsPlainText -Force
      
      #Level 0 Gets
      #$Level0Gets = Import-Csv .\Scripts\PurviewRestApi.csv |  Where-Object {($_.Level -eq 0) -and ($_.Enable -eq 1)}
      $Level0Gets = Import-Csv .\Deployment_Pipelines\PurviewRestApi.csv |  Where-Object {($_.Level -eq 0) -and ($_.Enable -eq 1)}
      
      foreach ($l in $Level0Gets){
    
          $Source_Token = $Source_Ptoken.access_token | ConvertTo-SecureString -AsPlainText -Force

          $URI = "https://" + $Source_Purview_Account + $l.APIURIDomain + $l.APIURIPath + "?" + $l.APIVersion
          if ($l.APIURIDomain -eq "management.azure.com")
          {
              $Source_Token = $Aztoken
              $URI = "https://" + $l.APIURIDomain + $l.APIURIPath + "?" + $l.APIVersion
          }    
        
          $FileName = $l.Category + "_" + $l.Command + "_" + $l.Method
          write-host $FileName.json
         
          write-host $URI

          if($l.Method -ne "POST") 
         {
            Invoke-RestMethod -Uri $URI -Authentication "Bearer" -Token $Source_Token -Method $l.Method | ConvertTo-Json -depth 100 | Out-File "$FileName.json"
         }
         
      }

      #3. Create Collections
      write-host "Creating collections"

      $Collections = Get-Content collections_readAllCollections_GET.json     
      $Collections_Replaced =  $Collections -replace $Source_Purview_Account, $Destination_Purview_Account
      $Collections_Converted = $Collections_Replaced | ConvertFrom-Json

  
      $Collections_Converted.value | foreach { 
      
           if ($_.description -ne "The root collection.")
          {
               $collection_name = $_.name
               write-host  $collection_name
                $Body = @{  
                 "description" = $_.description
                 "friendlyName" = $_.friendlyName
                 "parentCollection" = @{
                                "referenceName" = $_.parentCollection.referenceName
                                "type" = "CollectionReference" 
                           }
                }
               $CurrentCollection_Record = $Body |ConvertTo-Json -Depth 100

               $URI_CreateCollection = "https://" + $Destination_Purview_Account +  ".purview.azure.com/account/collections/" + $collection_name + "?api-version=2019-11-01-preview"
                    
               Invoke-RestMethod -Uri $URI_CreateCollection -Authentication "Bearer" -Token $token -ContentType 'application/json' -Method "PUT" -Body ($CurrentCollection_Record ) | ConvertTo-Json -depth 100 
          }
      }


      #4. Grant permissions on collections 
      write-host "Creating collection permissions"

      $CollectionPermission = (Get-Content metadatapolicy_readAllMetadataPolicies_GET.json)
      $CollectionPermission_Replaced =  $CollectionPermission -replace $Source_Purview_Account, $Destination_Purview_Account
      $CollectionPermission_Replaced =  $CollectionPermission_Replaced -replace $Source_ServicePrincipal_ObjectId, $Destination_ServicePrincipal_ObjectId
      $CollectionPermission_Converted = $CollectionPermission_Replaced | ConvertFrom-Json

      #Get the metadata policy from destination
      $Destination_URI =  "https://" + $Destination_Purview_Account + ".purview.azure.com/policystore/metadataPolicies?&api-version=2021-07-01"  
      Invoke-RestMethod -Uri $Destination_URI -Authentication "Bearer" -Token $token -Method GET | ConvertTo-Json -depth 100 | Out-File "Destination_Metadatapolicies.json"
      $Destination_CollectionPermission = Get-Content Destination_Metadatapolicies.json | ConvertFrom-Json
      $Destination_CollectionPermission_Json = Get-Content Destination_Metadatapolicies.json
      write-host $Destination_CollectionPermission_Json
      
      #Replace metadata policy id with destination ids
      $CollectionPermission_Converted.values | foreach {  
           $Collection = $_.properties.collection.referenceName
      
           foreach ($d in $Destination_CollectionPermission.values)
           {
               $Destination_CollectionRef = $d.properties.collection.referenceName 
               $Destination_Id = $d.id
               $Destination_Version = $d.version
              
               if ($Collection -eq $Destination_CollectionRef)
               {
                   $Id = $Destination_Id
                   $Version = $Destination_Version
                   $_.id = $Id
                   $_.version = $Version
                   $CurrentRecord = $_ |ConvertTo-Json -Depth 100

                   $URI_CollectionPermission = "https://" + $Destination_Purview_Account + ".purview.azure.com/policystore/metadataPolicies/" + $Id +"?api-version=2021-07-01" 
           
                  write-host "Creating permissions " + $Collection
                  Invoke-RestMethod -Uri $URI_CollectionPermission -Authentication "Bearer" -Token $token -ContentType 'application/json' -Method "PUT" -Body ($CurrentRecord)
               }
           }
      }
           
 
      #5. Create Data sources on collections 
      
      write-host "Creating data sources"
      
      $Datasources = (Get-Content scan_readDatasources_GET.json)
      $Datasources_Json = $Datasources | ConvertFrom-Json -Depth 100


      $Datasources_Json.value | foreach {  
           
           write-host "Data Source " + $_.name
           $kind = $_.Kind

           $CurrentRecord = $_ |ConvertTo-Json -Depth 100
           $CurrentRecord_DS = $CurrentRecord
           
           if ($kind -eq "Oracle")
           {  
             write-host "Oracle"
              $CurrentRecord_Host_Replaced = $CurrentRecord -replace $Source_Oracle_Host, $Destination_Oracle_Host
              $CurrentRecord_Port_Replaced = $CurrentRecord_Host_Replaced -replace $Source_Oracle_Port, $Destination_Oracle_Port
              $CurrentRecord_Service_Replaced = $CurrentRecord_Port_Replaced -replace $Source_Oracle_Service, $Destination_Oracle_Service
              $CurrentRecord_DS = $CurrentRecord_Service_Replaced
              write-host $CurrentRecord_DS 
           }

          if ($kind -eq "SqlServerDatabase")
           {  
              write-host "SQL"
              $CurrentRecord_DS = $CurrentRecord -replace $Source_SQL_Endpoint, $Destination_SQL_Endpoint
              
           }
           
              $URI_Datasources = "https://" + $Destination_Purview_Account + ".scan.purview.azure.com/datasources/" + $_.name + "?api-version=2018-12-01-preview"
              try
              {
                Invoke-RestMethod -Uri $URI_Datasources -Authentication "Bearer" -Token $token -ContentType 'application/json' -Method "PUT" -Body ($CurrentRecord_DS)
              }
              catch
              {
                Write-Host $_.ErrorDetails.Message  | ConvertFrom-Json
              }
           }
      
           
      
      #6. Create Classification Labels
      write-host "Creating classification labels"

      $ClassificationLabels = Get-Content types_readTypeDefs_GET.json  | ConvertFrom-Json
      
      $ClassificationLabels.classificationDefs | foreach { 

         if ($_.createdBy -ne "admin")
         {    
             $Body = @{  
                        "enumDefs"= @( )
                        "structDefs"= @( )
                        "classificationDefs"= @(
                                                 @{
                                                    "name"= $_.name
                                                    "description"= $_.description
                                                 }
                                              )
                         "entityDefs"= @( )
                         "relationshipDefs"= @( )
                    }
         
             $Url = "https://" + $Destination_Purview_Account + ".purview.azure.com/catalog/api/atlas/v2/types/typedefs" 
            
             try 
             {
                Invoke-RestMethod -Method "POST" -Uri $Url -Authentication "Bearer" -Token $token  -ContentType 'application/json'  -Body ($Body | ConvertTo-Json -Depth 100)
             } 
             catch
             {
                Write-Host $_.ErrorDetails.Message
             }          
         }
      }       

      #7. Create Classification Rules
      write-host "Creating classifications rules"

      $ClassificationRules = Get-Content scan_readClassificationRules_GET.json  | ConvertFrom-Json
      
      $ClassificationRules.value | foreach { 
                                             
                                             $recdata = $_.properties.dataPatterns                                            
                                             $reccolumn = $_.properties.columnPatterns 
                                         
                                            if ($recdata.count -ne 0)
                                             {
                                                  $minimumPercentageMatch= $_.properties.minimumPercentageMatch
                                             }
                                             else { $minimumPercentageMatch = $null}
                                            
                                             $Body = @{
                                                          "kind"= "Custom"
                                                          "id"= $_.id
                                                          "name"= $_.name
                                                          "properties"= @{
                                                                            "minimumPercentageMatch"= $minimumPercentageMatch
                                                                            "classificationAction"= $_.properties.classificationAction
                                                                            "description" = $_.properties.description
                                                                            "version"= $_.properties.version
                                                                            "classificationName"= $_.properties.classificationName
                                                                            "ruleStatus"= $_.properties.ruleStatus
                                                                            "owner"= $_.properties.owner
                                                                            "dataPatterns" = $recdata 
                                                                             "columnPatterns"=  $reccolumn
                                                                         }
                                                       }

                                               $Url = "https://" + $Destination_Purview_Account + ".scan.purview.azure.com/classificationrules/" + $_.name + "?api-version=2018-12-01-preview"
                                               Invoke-RestMethod -Method "PUT" -Uri $Url -Authentication "Bearer" -Token $token  -ContentType 'application/json'  -Body ($Body | ConvertTo-Json -Depth 100)
            }
   
      #8. Create Scanrulesets
      write-host "Creating Scan rulesets"

      $ScanRuleSets = Get-Content scan_readScanRulesets_GET.json | ConvertFrom-Json 
  
      $ScanRuleSets.value | foreach { 
      
        $Body = @{  
                    "name"= $_.name
                    "kind"= $_.kind
                    "properties"= @{
                                      "excludedSystemClassifications"= $_.properties.excludeSystemClassifications
                                      "includedCustomClassificationRuleNames"= $_.properties.includedCustomClassificationRuleNames
                                      "temporaryResourceFilters"= $_temporaryResourceFilters
                                   }
                 }

        $URI_CreateScanRuleSets = "https://" + $Destination_Purview_Account + ".purview.azure.com/scan/scanrulesets/" + $_.name +"?api-version=2018-12-01-preview" 
      
        Invoke-RestMethod -Uri $URI_CreateScanRuleSets -Authentication "Bearer" -Token $token -ContentType 'application/json' -Method "PUT" -Body ($Body | ConvertTo-Json -Depth 100)  
      
      }


      #9. Create Key Vault instances
      write-host "Creating Key Vault Instances "

                                   $Body_KV = @{
                                              "properties"= @{
                                                               "baseUrl"= "https://" + $KeyVault + ".vault.azure.net/" #$_.properties.baseUrl
                                                               "description" = "This is the Key Vault for Data Sources Secrets"
                                                             }
                                            }
                                   $URI_KV = "https://" + $Destination_Purview_Account + ".scan.purview.azure.com/azureKeyVaults/" + $KeyVault + "?api-version=2018-12-01-preview"
                                   
                                   try {
                                          Invoke-RestMethod -Uri $URI_KV -Authentication "Bearer" -Token $token -ContentType 'application/json' -Method "PUT" -Body ($Body_KV | ConvertTo-Json -Depth 100)
                                   }
                                   catch {
                                     Write-Host $_.ErrorDetails.Message
                                   }  
                                        
      
      #10. Create Credentials
      write-host "Creating Credentials"

      #Get Credentials
      write-host "Credentials"
      $URI_Get_Credentials  = "https://" + $Source_Purview_Account + ".purview.azure.com/proxy/credentials/?api-version=2020-12-01-preview"
      $SourceCredentials = Invoke-RestMethod -Uri $URI_Get_Credentials -Authentication "Bearer" -Token $Source_Token -Method "GET"
      $SourceCredentials_conv = $SourceCredentials |ConvertTo-Json -Depth 100
      write-host $SourceCredentials_conv
      
      #Create Credentials
      $SourceCredentials.value |foreach{

        $credentialName = $_.name

        $CredBody = @{
                  "name" = $credentialName
                  "properties"= @{  
                                   "type"= $_.properties.type
                                   "typeProperties"= @{
                                                        "user"= $_.properties.typeProperties.user
                                                        "password" = @{
                                                                        "type" = $_.properties.typeProperties.password.type
                                                                        "secretName"= $_.properties.typeProperties.password.secretName
                                                                        "secretVersion"= "" #$_.properties.typeProperties.password.secretVersion
                                                                        "store" =@{
                                                                                   "referenceName"= $KeyVault #$_.properties.typeProperties.password.store.referenceName
                                                                                   "type"= $_.properties.typeProperties.password.store.type
                                                                                }
                                                                    }
                                                      }
                                 }
                }

         $URI_Credentials = "https://" + $Destination_Purview_Account + ".purview.azure.com/proxy/credentials/" + $credentialName + "?api-version=2020-12-01-preview"
                                           
         Invoke-RestMethod -Uri $URI_Credentials -Authentication "Bearer" -Token $token -ContentType 'application/json' -Method "PUT" -Body ($CredBody | ConvertTo-Json -Depth 100) 
      }

      #11. Create Scans
      write-host "Creating Scans"     

      #Get Datasources 
      $Datasources = Get-Content scan_readDatasources_GET.json  | ConvertFrom-Json
      Write-Host $Datasources.value |convertTo-Json -Depth 100
      
      #Create Scans
      $Datasources.value | foreach {

                                      $dataSource = $_.name
                                      write-host $datasource
                                      $Url = "https://" + $Source_Purview_Account + ".scan.purview.azure.com/datasources/" + $dataSource + "/scans?api-version=2018-12-01-preview"
                                      $Scans = Invoke-RestMethod -Uri $URl -Authentication "Bearer" -Token $Source_Token -Method GET  | ConvertTo-Json -depth 100 
                                      $Scans_Replaced =  $Scans -replace $Source_IR, $Destination_IR
                                      #write-host $Scans_Replaced
                                      $Scans_Converted = $Scans_Replaced | ConvertFrom-Json -Depth 100

                                      foreach ($s in $Scans_Converted.value) {                                       
                                        $scanName = $s.name
                                        $CurrentRecord_Scan = $s | ConvertTo-Json -Depth 100
                                        write-host $scanName
                                        write-host $Current_RecordScan
                                        $URI_Scans = "https://" + $Destination_Purview_Account + ".scan.purview.azure.com/datasources/" + $dataSource + "/scans/" + $scanName + "?api-version=2018-12-01-preview"
                                        write-host $CurrentRecord_Scan
                                       try {
                                             Invoke-RestMethod -Uri $URI_Scans -Authentication "Bearer" -Token $token -ContentType 'application/json' -Method "PUT" -Body ($CurrentRecord_Scan)
                                        }
                                       catch{
                                              Write-Host $_.ErrorDetails.Message
                                       }
                                      }
                                }

       #12. Create Triggers
       write-host "Creating Triggers"
       
       $Datasources.value | foreach {
        $dataSource = $_.name
        #Get list of scans
        $URI_ScanList = "https://" + $Source_Purview_Account + ".scan.purview.azure.com/datasources/" + $dataSource + "/scans?api-version=2018-12-01-preview"
        $ScanList = Invoke-RestMethod -Uri $URI_ScanList -Authentication "Bearer" -Token $Source_Token -Method GET  
        $ScanList_Conv = $ScanList |ConvertTo-Json -depth 100 
        Write-Host "The scan list is " +$ScanList_Conv
        foreach( $t in $ScanList.value){
           $scanName = $t.name
           write-host $ScanName

           $URI_GetTrigger = "https://" + $Source_Purview_Account + ".scan.purview.azure.com/datasources/" + $dataSource + "/scans/" + $scanName + "/triggers/default?api-version=2018-12-01-preview"
           try{
                $Trigger = Invoke-RestMethod -Uri $URI_GetTrigger -Authentication "Bearer" -Token $Source_Token -Method GET  | ConvertTo-Json -depth 100        
                write-host "this is the trigger "  + $trigger
                $URI_PUTTrigger = "https://" + $Destination_Purview_Account + ".scan.purview.azure.com/datasources/" + $dataSource + "/scans/" + $ScanName + "/triggers/default?api-version=2018-12-01-preview"
                Invoke-RestMethod -Uri $URI_PUTTrigger -Authentication "Bearer" -Token $token -ContentType 'application/json' -Method "PUT" -Body ($Trigger)
           }
           catch{
              Write-Host $_.ErrorDetails.Message
           }   
        }
      }

 