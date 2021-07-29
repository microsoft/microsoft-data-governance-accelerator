
workspace "Big Bank plc" "This is an example workspace to illustrate the key features of Structurizr, via the DSL, based around a fictional online banking system." {

    model {
       

        enterprise "Big Bank plc" {
            DataEngineer = person "Data Engineer" "..." "DataEngineer"
            ReportConsumer = person "Data / Report Consumer" "" ""
            backoffice = person "Back Office Staff" "Administration and support staff within the bank." "Bank Staff"

            
            group "Azure" {
                mainframe = softwaresystem "Mainframe Banking System" "Stores all of the core banking information about DataEngineers, accounts, transactions, etc." "Existing System"
                email = softwaresystem "E-mail System" "The internal Microsoft Exchange e-mail system." "Existing System"
                atm = softwaresystem "ATM" "Allows DataEngineers to withdraw cash." "Existing System"

                AdsGoFastCore = softwaresystem "ADS Go Fast Core" "..." {
                    webApplication = container "Web Application" "..." ".Net Core MVC"
                    apiApplication = container "API Application" "Ads Go Fast Orchestration Function App" ".Net Core" {
                        signinController = component "Sign In Controller" "Allows users to sign in to the Internet Banking System." "Spring MVC Rest Controller"
                        accountsSummaryController = component "Accounts Summary Controller" "Provides DataEngineers with a summary of their bank accounts." "Spring MVC Rest Controller"
                        resetPasswordController = component "Reset Password Controller" "Allows users to reset their passwords with a single use URL." "Spring MVC Rest Controller"
                        securityComponent = component "Security Component" "Provides functionality related to signing in, changing passwords, etc." "Spring Bean"
                        mainframeBankingSystemFacade = component "Mainframe Banking System Facade" "A facade onto the mainframe banking system." "Spring Bean"
                        emailComponent = component "E-mail Component" "Sends e-mails to users." "Spring Bean"
                    }
                    database = container "ADS Go Fast Metadata DB" "Stores task metadata and settings for the ADS Go Fast Framework" "ADS Go Fast Metadata DB" "Microsoft Azure - SQL Database, Database"
                }

                AdsGoFastExecutionEngines = softwaresystem "Task Execution Engines " "..." {
                    adf = container "Azure Data Factory" "..." "...."
                }

                ReportingEngines = softwaresystem "Reporting & Analytics Services" "..." {
                    pbi = container "Power Bi" "..." "...."
                }

                DataLake = softwaresystem "DataLake" "..." {
                    adlsLanding = container "ADLS - Landing" "..." "...."
                    adlsBronze = container "ADLS - Bronze" "..." "...."
                    adlsSilver = container "ADLS - Silver" "..." "...."
                    adlsGold = container "ADLS - Gold" "..." "...."
                }
            }

            group "On Premise" {
            OnPremiseSourcesSystem = softwaresystem "On Premise Source Systems" "...." {
                    database_op_sql = container "Database - SQL" "" "Oracle Database Schema" "Database"
            }
        }
            
        }

        

        # relationships between people and software systems
        DataEngineer -> AdsGoFastCore "..."
        pbi -> ReportConsumer "..."

        # relationships to/from containers
        DataEngineer -> webApplication "Visits bigbank.com/ib using" "HTTPS"
        webApplication -> database ".."
        database_op_sql -> adf ".."
        AdsGoFastCore -> AdsGoFastExecutionEngines ".."

        # relationships to/from components
        signinController -> securityComponent "Uses"
        accountsSummaryController -> mainframeBankingSystemFacade "Uses"
        resetPasswordController -> securityComponent "Uses"
        resetPasswordController -> emailComponent "Uses"
        securityComponent -> database "Reads from and writes to" "JDBC"
        mainframeBankingSystemFacade -> mainframe "Makes API calls to" "XML/HTTPS"
        emailComponent -> email "Sends e-mail using"

       
    }

    views {
        systemLandscape "SystemLandscape" {
            include *
            autoLayout
        }

        systemcontext AdsGoFastCore "SystemContext" {
            include *
            animation {
                AdsGoFastCore
                DataEngineer
                mainframe
                email
            }
            autoLayout
        }

        container AdsGoFastCore "Containers" {
            include *
            animation {
                DataEngineer mainframe email OnPremiseSourcesSystem
                webApplication
                apiApplication
                database
            }
            autoLayout
        }

        component apiApplication "Components" {
            include *
            animation {
                database email mainframe
                signinController securityComponent
                accountsSummaryController mainframeBankingSystemFacade
                resetPasswordController emailComponent
            }
            autoLayout
        }

        dynamic apiApplication "SignIn" "Summarises how the sign in feature works in the single-page application." {
            
            signinController -> securityComponent "Validates credentials using"
            securityComponent -> database "select * from users where username = ?"
            database -> securityComponent "Returns user data to"
            securityComponent -> signinController "Returns true if the hashed password matches"
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
