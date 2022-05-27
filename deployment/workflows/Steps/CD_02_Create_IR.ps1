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

      #Get Purview Token - For Destination Purview Account
      $RequestAccessTokenUri = "https://login.microsoftonline.com/$TenantId/oauth2/token"
      $Resource = "https://purview.azure.net"
      $Body = "grant_type=client_credentials&client_id=$ClientId&client_secret=$ClientSecret&resource=$Resource"
      $Ptoken= Invoke-RestMethod -Method Post -Uri $RequestAccessTokenUri -Body $Body
      $token = $Ptoken.access_token | ConvertTo-SecureString -AsPlainText -Force
            
      #Create IR   
                  write-host "Creating SHIR"
                  $IR_name=$Destination_IR
                  $IR_Description = "SHIR for " + $Destination_Purview_Account
                  write-host  $IR_name
                  $Body_IR = @{  
                              "name" = $IR_name
                              "properties" = @{
                                              "description" = $IR_Description
                                              "type" =  "SelfHosted"
                                      }
                              }
                  $CurrentIR_Record = $Body_IR |ConvertTo-Json -Depth 100
                  $URI_CreateIR = "https://" + $Destination_Purview_Account + ".purview.azure.com/proxy/integrationRuntimes/" + $IR_name + "?api-version=2020-12-01-preview"
                                              
                  Invoke-RestMethod -Uri $URI_CreateIR -Authentication "Bearer" -Token $token -ContentType 'application/json' -Method "PUT" -Body ($CurrentIR_Record ) | ConvertTo-Json -depth 100 
                  write-host "Please register the authentication keys for the SHIR created on the VM before running the script CD_03_Create_Purview_ Objects_Excluding_Glossary"