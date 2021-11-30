
workspace "Big Bank plc" "This is an example workspace to illustrate the key features of Structurizr, via the DSL, based around a fictional online banking system." {

    model {
       

            enterprise "Smart Enterprise Pty Ltd" {
                DataEngineer = person "Data Engineer" "..." "DataEngineer"
                InformationConsumer = person "Data / Report Consumer" "" ""
                InformationWorker = person "Information Worker" "" ""
                DataStewards = person "Data Stewards" "" ""
                SecurityOfficer = person "Security Admin" "" ""
                CISO = person "Chief Information Security Officer" "" ""
                CDO = person "Chief Data Officer" "" ""
                
        
                group "Azure" {
                    AdsGoFastCore = softwaresystem "AdsGoFastCore" "..." {
                         group "Azur2e" {
                        adlsLanding = container "ADLS - Landing" "..." "...."
                        adlsBronze = container "ADLS - Bronze" "..." "...."
                        adlsSilver = container "ADLS - Silver" "..." "...."
                        adlsGold = container "ADLS - Gold" "..." "...."
                         }
                    }
                }

                group "Microsoft Power Platform" {
                    PowerBI = softwaresystem "PowerBi" "...."
                    PowerApps = softwaresystem "Power Apps" "...." 
                }
                group "Microsoft Office 365" {
                    OfficeDocuments = softwaresystem "Documents" "...." 
                    Emails = softwaresystem "Email" "...." 
                    Chats = softwaresystem "Chat / Posts" "...." 
                    WebPages = softwaresystem "Wikis & Webpages" "...." 
                }
                group "Microsoft Dynamics 365" {
                    DynamicsCE = softwaresystem "Dynamics C & E" "...." 
                    DynamicsFO = softwaresystem "Dynamics F & O" "...." 
                    Dataverse = softwaresystem "Dataverse" "...." 
                }

                group "On Premise" {
                    OnPremiseSourcesSystem = softwaresystem "On Premise Source Systems" "...." {
                            database_op_sql = container "Database - SQL" "" "Oracle Database Schema" "Database"
                    }
                }

                group "Other Clouds" {
                    AWS = softwaresystem "AWS" "...." {
                            RDS = container "AWS RDS" "" "Oracle Database Schema" "Database"
                    }
                    Google = softwaresystem "Google" "...." {
                        BigQuery = container "Big Query" "" "Oracle Database Schema" "Database"
                    }
                }
                
            }
    
            # relationships between people and software systems


            # relationships to/from containers
            


            # relationships to/from components
            
    }
    
    views {
        systemLandscape "SystemLandscape" {
            include *
            autoLayout
        }

        systemcontext AdsGoFastCore "SystemContext" {
            include *
            autoLayout
        }

        container AdsGoFastCore "c1"{
            include *
            autoLayout
        }
        

        

      
        styles {
            element "Person" {
                color #ffffff
                fontSize 22
                shape Person
            }
            element "DataEngineer" {
                background #08427b
            }
            element "Bank Staff" {
                background #999999
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Existing System" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Web Browser" {
                shape WebBrowser
            }
            element "Mobile App" {
                shape MobileDeviceLandscape
            }
            element "Database" {
                shape Cylinder
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Failover" {
                opacity 25
            }
        }                               
        
        themes https://static.structurizr.com/themes/microsoft-azure-2020.07.13/theme.json
    }
}


