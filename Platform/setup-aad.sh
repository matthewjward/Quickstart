#!/bin/bash

# This script sets up 4 AAD applications to control access to the Applications / API.
# Two in each environment. One is configured for an OIDC flow to sign the user into the app.
# The 2nd configures authorisation for the API.

# Your CI/CD will need permission to create AAD App Registrations else it won't work.

WEBSITE_HOST_NAME=$1
WEB_API_HOST_NAME=$2


# Build the application representing the website.
# All we want to do here is sign someone in. The application behaves like a SPA using a separate API for resource access.
read -r -d '' REQUIRED_WEBSITE_RESOURCE_ACCESS << EOM
[{
    "resourceAppId": "00000003-0000-0000-c000-000000000000",
    "resourceAccess": [
        {
            "id": "e1fe6dd8-ba31-4d61-89e7-88639da4683d",
            "type": "Scope"
        }
   ]
}]
EOM

AAD_WEBSITE_APPLICATION=$(az ad app create --display-name $WEBSITE_HOST_NAME --reply-urls "https://${WEBSITE_HOST_NAME}.azurewebsites.net/signin-oidc" "https://${WEBSITE_HOST_NAME}-green.azurewebsites.net/signin-oidc" --required-resource-access "$REQUIRED_WEBSITE_RESOURCE_ACCESS")

# Build the application representing the API.
read -r -d '' API_ROLES << EOM
[{
    "allowedMemberTypes": [
      "User"
    ],
    "id" : "a0bdae44-5469-4395-bba4-e0158a0ebc54",
    "description": "Readers can read pets",
    "displayName": "Reader",
    "isEnabled": "true",
    "value": "reader"
},
{
    "allowedMemberTypes": [
      "User"
    ],
    "id" : "d8eb2b97-42e6-47af-bab7-8f964e8d3a29",
    "description": "Admins can create pets",
    "displayName": "Admin",
    "isEnabled": "true",
    "value": "admin"
}
]
EOM

AAD_API_APPLICATION_ID=$(az ad app create --display-name "$WEB_API_HOST_NAME" --app-roles "$API_ROLES" --query "appId" -o tsv | tr -d '\r')

# https://anmock.blog/2020/01/10/azure-cli-create-an-azure-ad-application-for-an-api-that-exposes-oauth2-permissions/
# disable default exposed scope
DEFAULT_SCOPE=$(az ad app show --id "$AAD_API_APPLICATION_ID"  | jq '.oauth2Permissions[0].isEnabled = false' | jq -r '.oauth2Permissions')
az ad app update --id "$AAD_API_APPLICATION_ID" --set oauth2Permissions="$DEFAULT_SCOPE"

#Create a scope we can prompt the user for 
read -r -d '' API_SCOPES << EOM
[
 {
        "adminConsentDescription": "Allows the app to see and create pets",
        "adminConsentDisplayName": "Pets",
        "id": "922d92cd-454b-4544-afd8-99f9a6ed9a44",
        "isEnabled": true,
        "lang": null,
        "origin": "Application",
        "type": "User",
        "userConsentDescription": "Allows the app to see and create pets",
        "userConsentDisplayName": "See pets",
        "value": "Pets.Manage"
    }
]
EOM
az ad app update --id "$AAD_API_APPLICATION_ID" --set oauth2Permissions="$API_SCOPES"