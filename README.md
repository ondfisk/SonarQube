# SonarQube

Sample of SonarQube running on Azure App Service on Linux (container) with Azure SQL Database.

## Setup

1. Configure environment `Production` in GitHub actions
1. Configure secrets:

    - AZURE_CREDENTIALS
    - SQL_SERVER_PASSWORD
    - SQL_DATABASE_PASSWORD

1. Deploy resources
1. Create SQL login on `master`:

    ```sql
    CREATE LOGIN SonarQube WITH PASSWORD = '...'
    GO
    ```

1. Create and assign user on `SonarQube` database

    ```sql
    CREATE USER SonarQube FOR LOGIN SonarQube
    GO
    EXEC sp_addrolemember 'db_owner', 'SonarQube'
    GO
    ```

1. Configure Azure AD App Registration:

    - Redirect URI: <https://ondfisksonarqube.azurewebsites.net/oauth2/callback/aad>

1. Go to deployed web site and login to SonarQube to complete configuration

    - Configuration/General Settings/General/Server base URL: <https://ondfisksonarqube.azurewebsites.net/>
    - Configuration/Marketplace//Plugins: Install *Azure Active Directory (AAD) Authentication Plug-in for SonarQube INTEGRATION*
    - Configuration/General Settings/Azure Active Directory: ...

## TODO

Automate creation of SQL LOGIN for SonarQube
