
@minLength(1)
@description('The name of the key vault that will store AAD secrets for the web app')
param keyVaultName string

@minLength(1)
@description('The name of the Azure App Configuration Service that will store AAD secrets for the web app')
param appConfigurationServiceName string

// these AADB2C settings are also documented in the create-AADB2C-app-registrations.md.md. Please keep both locations in sync

@minLength(1)
@description('A scope used by the front-end public web app to get authorized access to the public web api. Looks similar to https://myb2ctestorg.onmicrosoft.com/fbb6ce3b-c65f-4708-ae94-5069d1f821b4/Attendee')
param frontEndAzureAdB2CApiScope string

@minLength(1)
@description('A unique identifier of the public facing front-end web app')
param frontEndAzureAdB2cClientId string

@secure()
@minLength(1)
@description('A secret generated by Azure AD B2C so that your web app can establish trust with Azure AD B2C')
param frontEndAzureAdB2cClientSecret string

@minLength(1)
@description('A unique identifier of the public facing API web app')
param apiAzureAdB2cClientId string

@minLength(1)
@description('The domain for the Azure B2C tenant: e.g. myb2ctestorg.onmicrosoft.com')
param azureAdB2cDomain string

@minLength(1)
@description('The url for the Azure B2C tenant: e.g. https://myb2ctestorg.b2clogin.com')
param azureAdB2cInstance string

@minLength(1)
@description('A unique identifier of the Azure AD B2C tenant')
param azureAdB2cTenantId string

@minLength(1)
@description('An Azure AD B2C flow that defines behaviors relating to user sign-up and sign-in. Also known as an Azure AD B2C user flow.')
param azureAdB2cSignupSigninPolicyId string

@minLength(1)
@description('An Azure AD B2C flow that enables users to reset their passwords. Also known as an Azure AD B2C user flow.')
param azureAdB2cResetPolicyId string

@minLength(1)
@description('A URL provided by your web app that will clear session info when a user signs out')
param azureAdB2cSignoutCallback string

// reminder: the semi-colon is not a valid character for a kv key name so we use alternate dotnet syntax of -- to specify this nested config setting
var clientSecretName = 'AzureAdB2C--ClientSecret'

resource kv 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = {
  name: keyVaultName

  resource kvFrontEndAzureAdB2cClientSecret 'secrets@2021-11-01-preview' = {
    name: clientSecretName
    properties: {
      value: frontEndAzureAdB2cClientSecret
    }
  }
}

resource appConfigSvc 'Microsoft.AppConfiguration/configurationStores@2022-05-01' existing = {
  name: appConfigurationServiceName
  
  //begin front-end web app settings
  resource appConfigSvcFrontEndAzureAdB2cClientSecret 'keyValues@2022-05-01' = {
    name: 'AzureAdB2C:ClientSecret'
    properties: {
      value: string({
        uri: '${kv.properties.vaultUri}secrets/${clientSecretName}'
      })
      contentType: 'application/vnd.microsoft.appconfig.keyvaultref+json;charset=utf-8'
    }
  }

  resource appConfigSvcFrontEndAzureAdB2cApiScope 'keyValues@2022-05-01' = {
    name: 'PubApp:RelecloudApi:AttendeeScope'
    properties: {
      value: frontEndAzureAdB2CApiScope
    }
  }

  resource appConfigSvcFrontEndAzureAdB2cClientId 'keyValues@2022-05-01' = {
    name: 'AzureAdB2C:ClientId'
    properties: {
      value: frontEndAzureAdB2cClientId
    }
  }

  resource appConfigSvcAzureAdB2cDomain 'keyValues@2022-05-01' = {
    name: 'AzureAdB2C:Domain'
    properties: {
      value: azureAdB2cDomain
    }
  }

  resource appConfigSvcAzureAdB2cInstance 'keyValues@2022-05-01' = {
    name: 'AzureAdB2C:Instance'
    properties: {
      value: azureAdB2cInstance
    }
  }

  resource appConfigSvcAzureAdB2cTenantId 'keyValues@2022-05-01' = {
    name: 'AzureAdB2C:TenantId'
    properties: {
      value: azureAdB2cTenantId
    }
  }

  resource appConfigSvcAzureAdB2cSignupSigninPolicyId 'keyValues@2022-05-01' = {
    name: 'AzureAdB2C:SignUpSignInPolicyId'
    properties: {
      value: azureAdB2cSignupSigninPolicyId
    }
  }

  resource appConfigSvcAzureAdB2cResetPolicyId 'keyValues@2022-05-01' = {
    name: 'AzureAdB2C:ResetPasswordPolicyId'
    properties: {
      value: azureAdB2cResetPolicyId
    }
  }

  resource appConfigSvcAzureAdB2cSignedOutCallbackPath 'keyValues@2022-05-01' = {
    name: 'AzureAdB2C:SignedOutCallbackPath'
    properties: {
      value: azureAdB2cSignoutCallback
    }
  }

  //begin web API app settings
  resource appConfigSvcApiAzureAdB2cClientId 'keyValues@2022-05-01' = {
    name: 'Api:AzureAdB2C:ClientId'
    properties: {
      value: apiAzureAdB2cClientId
    }
  }

  resource appConfigSvcApiAzureAdB2cDomain 'keyValues@2022-05-01' = {
    name: 'Api:AzureAdB2C:Domain'
    properties: {
      value: azureAdB2cDomain
    }
  }

  resource appConfigSvcApiAzureAdB2cInstance 'keyValues@2022-05-01' = {
    name: 'Api:AzureAdB2C:Instance'
    properties: {
      value: azureAdB2cInstance
    }
  }

  resource appConfigSvcApiAzureAdB2cTenantId 'keyValues@2022-05-01' = {
    name: 'Api:AzureAdB2C:TenantId'
    properties: {
      value: azureAdB2cTenantId
    }
  }

  resource appConfigSvcApiAzureAdB2cSignupSigninPolicyId 'keyValues@2022-05-01' = {
    name: 'Api:AzureAdB2C:SignUpSignInPolicyId'
    properties: {
      value: azureAdB2cSignupSigninPolicyId
    }
  }
}
