## Introduction

This workshop provides students with a personal cluster on Azure hosting a running instance of OpenShift Container Platform (OCP). Students will use it to deploy Viya on OCP.

## How to setup the workshop

This workshop is integrated with [GELLOW](https://gitlab.sas.com/GEL/utilities/gellow/). In the month of April 2022 it has been ported to the new GELENABLE Azure tenant:

| | OLD | New |
|-|-|-|
| Tenant Name| SAS | GELenable |
| Tenant ID | b1c14d5c-3625-45b3-a430-9552373a0c2f | a708fb09-1d96-416a-ad34-72fa07ff196d |
| Subscription Name | sas-gelsandbox | PSGEL300 SAS Viya Deploy Red Hat OpenShift |
| Subscription ID | c973059c-87f4-4d89-8724-a0da5fe4ad5c | c1eea1ae-7109-4c52-a776-3b75dfb5b684 |
| Shared Subscription Name | GEL | GEL Persistent Resources |
| Shared Subscription ID | b91ae007-b39e-488f-bbbf-bc504d0a8917 | 5483d6c1-65f0-400d-9910-a7a448614167 |
| Principal Name | PSGEL300 | PSGEL300_sp |
| Principal Client ID | 37f11bee-ecae-462c-850c-e8d2bf09a199 | 668399fd-8533-4915-bc82-9f4fda424aa8 |
| Principal Object ID | f63f4567-378a-46c3-828a-bb4ea1d15151 | 416014cd-1841-42bd-ba8a-206a70709107 |
| Managed Enterprise Application Object ID | 16589f00-6ce3-4ad7-8575-21463d1e7576 | 47786469-ad4b-4680-abc6-8034f523f975 |
At machine boot, GELLOW automatic loop runs scripts located in [/scripts/loop/](../scripts/loop/)

This workshop installs the OCP and Azure clients in the collection's linux machine.

Then it uses a GEL-owned Service Principal to logon to azure and:

* create Azure infrastructure
* deploy OCP on the infrastructure

There are required artifacts that are shared across all students, and as such have been already created and are managed by GEL.

1. A workshop-dedicated [Service Principal](#service-principal),
1. The [CoreOS VHD image](#coreos-image) used to create Azure virtual machines
1. The [custom virtual machine image](#custom-virtual-machine-image) created from that VHD image
1. A [Shared Image Gallery](#create-an-image-gallery) hosting the machine, to share it with students
1. Security artifacts saved on GELWEB

## Service Principal

Define and configure the Service Principal (SP).

Here are the steps used to do it.

### Assumptions and requirements for the SP

* It has `contributor` role for th workshop subscription (Old: `sas-gelsandbox` New: `PSGEL300 SAS Viya Deploy Red Hat OpenShift`)
* It is owned by all GEL Team architects, not a single person
* It is dedicated to this workshop - it should not be used for anything else
* It is used to run batch scripts for the workshop. Students should not use it
* It has a long-term client certificate, used to logon to azure. The certificate is stored on gelweb just as with all other GELENABLE-based workshops
* It has a short-lived password (client secret) used by openshift-installer to logon to Azure (as of April 2022, OpenShift does not support certificate-based Azure logins)
  * Before GELENABLE, the password used to be stored on gelweb in the workshop directory `/data/workshops/PSGEL300_001/security` which is a mount of `nagel01.unx.sas.com:/vol/gel/gate/workshops/SCRIPTS/PSGEL300_001/security` and is available via HTTP at <https://gelweb.race.sas.com/scripts/PSGEL300_001/security/>
  * With GELENABLE, each time scripts run at collection bootstrap, a new short-lived, random password is generated, added to the principal and saved locally in the collection.

### Script to create the SP

1. Login to your subscription (for example from cldlgn.fyi.sas.com ):

    ```sh
    az login
    ```

1. If your Azure account has multiple subscriptions, ensure that you are using the right subscription.

   <details><summary>Click here to view the list of available accounts and view your active account details:</summary>

    ```sh
    az account list --refresh
    az account show
    ```

    Example output

    ```json
    itaedr@cldlgn05:~$ az account show
    {
        "environmentName": "AzureCloud",
        "homeTenantId": "a708fb09-1d96-416a-ad34-72fa07ff196d",
        "id": "c1eea1ae-7109-4c52-a776-3b75dfb5b684",
        "isDefault": true,
        "managedByTenants": [],
        "name": "PSGEL300 SAS Viya Deploy Red Hat OpenShift",
        "state": "Enabled",
        "tenantId": "a708fb09-1d96-416a-ad34-72fa07ff196d",
        "user": {
            "name": "Edoardo.Riva@sas.com",
            "type": "user"
        }
    }
    ```

    View your active account details and confirm that the tenantId value matches the subscription you want to use:
    </details>

1. If you are not using the right subscription, change the active subscription to `PSGEL300 SAS Viya Deploy Red Hat OpenShift`:

    ```sh
    az account set -s "PSGEL300 SAS Viya Deploy Red Hat OpenShift"
    ```

1. Get the tenantId and subscriptionId of `sas-gelsandbox`

    ```sh
    TENANTID=$(az account show --query tenantId -o tsv)
    SUBSCRIPTIONID=$(az account show --query id -o tsv)
    echo TENANT=${TENANTID}
    echo SUBSCRIPTION=${SUBSCRIPTIONID}
    ```

    ```log
    TENANT=a708fb09-1d96-416a-ad34-72fa07ff196d
    SUBSCRIPTION=c1eea1ae-7109-4c52-a776-3b75dfb5b684
    ```

1. Now create Service Principal that will be utilized by the workshop to create the infrastructure and by cluster
   * with no implicit roles
   * with a certificate to sign in, valid for 5 years

    ```sh
    APPNAME=PSGEL300_sp
    RESULT=$(az ad sp create-for-rbac --role Contributor --name ${APPNAME} --create-cert --years 5 --skip-assignment --only-show-errors)
    echo $RESULT | jq
    APPID=$(echo $RESULT | jq -r .appId)
    CERTFILE=$(echo $RESULT | jq -r .fileWithCertAndPrivateKey)
    ```

    ```json
    {
        "appId": "37f11bee-ecae-462c-850c-e8d2bf09a199",
        "displayName": "PSGEL300",
        "fileWithCertAndPrivateKey": "/r/sanyo.unx.sas.com/vol/vol101/u101/itaedr/tmpb5ssqzwn.pem",
        "name": "37f11bee-ecae-462c-850c-e8d2bf09a199",
        "password": null,
        "tenant": "b1c14d5c-3625-45b3-a430-9552373a0c2f"
    }
    ```

    > The command creates the service principal and a PEM file. The PEM file contains a correctly formatted PRIVATE KEY and CERTIFICATE.

1. Save the certificate somewhere safe and where you remember - for example, the old one was in [onenote](https://sasoffice365.sharepoint.com/sites/GEL/GELTEam/_layouts/OneNote.aspx?id=%2Fsites%2FGEL%2FGELTEam%2FGEL%20One%20Note%20Library%2FWorkshop%20Creation%20and%20Exnet%20Image%20Management&wd=target%28Cloud%2FPSGEL300%20-%20Viya4%20on%20OCP.one%7CA6E7A030-8EDC-425E-AD9A-A7BE918DD636%2FWorkshop%20architecture%7C59EB1D43-2C50-4D30-8094-3356ADDF7A28%2F%29). The new one is on [gelweb](http://gelweb.race.sas.com/scripts/gelenable/security/)

   > If you lose access to a certificate's private key, you have to [reset the service principal credentials](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli#reset-credentials).

1. >OLD: Not required with GELENABLE

    The certificate is used in Jenkins to connect to Azure. Jenkins wants a PKCS12 certificate, then Azure credentials should reference that, but I've been unable to make it work. Workaround: load the certificate as is in Jenkins in a credential of type "Secret File", then simply reference it in Jenkins code:

    ```groovy
    withCredentials([file(credentialsId: 'PSGEL300_keyCert.pem', variable: 'AZURE_CERTIFICATE_FILE'), azureServicePrincipal('PSGEL300')]) {
    sh label: 'Login to Azure', script: '''
        az login --service-principal -u ${AZURE_CLIENT_ID} -p ${AZURE_CERTIFICATE_FILE} -t ${AZURE_TENANT_ID}
        az account set -s ${AZURE_SUBSCRIPTION_ID}
        az account show
    '''
    }
   ```

1. >OLD: Not required with GELENABLE

    Add a short-lived password. This will be saved on GELWEB and used by the scripts; it's short-lived so that if it leaks it will expire soon. Then, a Jenkins job constantly keeps it fresh.

    ```sh
    # I choose to have it expire on Tuesday so that if something goes wrong with the renewal, there is someone in the office to check.
    END_DATE=$(date '+%Y-%m-%dT%H:%M:%SZ+0000' --date='Next Tuesday')
    RESULT=$(az ad sp credential reset --name ${APPID} --end-date ${END_DATE} --append)
    echo $RESULT | jq

    ```

1. >OLD: Not required with GELENABLE

    Save the password to GELWEB - we give read permissions to all since it will be openly served from GELWEB

    ```sh
    echo  $RESULT | jq -r .password | ssh glsuser1@gelweb.race.sas.com -C "cat  > /data/workshops/PSGEL300_001/security/${APPNAME}_Secret.txt"
    ## verify
    curl -s https://gelweb.race.sas.com/scripts/PSGEL300_001/security/${APPNAME}_Secret.txt
    # remove the local cert copy
    rm $CERTFILE
    ```

1. Manage the SP security.
    * >OLD: Not required with GELENABLE:

        add all gel architects as owners

        ```sh
        # add all gel architects as owners
        readarray -t gelArcIds < <(az ad group member list --group "GEL Team Architects" --query "[].objectId" -o tsv)
        for gelMember in ${gelArcIds[@]}; do
            echo "adding $gelMember"
            az ad app owner add --id ${APPID} --owner-object-id $gelMember
        done;
        #check
        az ad app owner list --id ${APPID} --query "[].{displayName: displayName}" -o table
        ```

        ```log
        adding a1708b6c-d02b-422f-ae2a-352589496f1c
        adding 12df51fa-9ad1-41c5-95f6-5994d06bdd3a
        adding ae839637-823c-44fa-a44e-0ae870811ed0
        adding 316db040-b710-4b09-9df0-d068164ddd03
        adding 6263caa5-dd02-4db8-a259-e9673cbdd9c4
        adding b19f75a7-0a2c-495e-974d-ee9b98f657bf
        adding 5be957ef-86a2-4165-9289-d9d5ac8e0b52
        adding 8936f85f-15fb-434b-8268-64e67de2be92
        adding 6d75f556-2f53-488e-8df8-1ce06d4f6dd7
        DisplayName
        -----------------
        Raphael Poumarede
        Stuart Rogers
        Simon Williams
        Michael Goddard
        Jeff Herman
        Rob Collum
        Allen Cunningham
        Mark Thomas
        Edoardo Riva
        ```

    * Add its own Service Principal as App owner:

        This is required to be able to self-change its own password.

        ```sh
        # find the id of the Service Principal associated with the app
        SPID=$(az ad sp show --id ${APPID} --query "objectId")
        # add the SP as an app owner
        az ad app owner add --id ${APPID} --owner-object-id  ${SPID}
        ```

    * add the roles required by OCP (see <https://docs.openshift.com/container-platform/4.7/installing/installing_azure/installing-azure-account.html#installation-azure-service-principal_installing-azure-account>)

        ```sh
        # by default these will apply at the subscription level
        # assign the Contributor role
        az role assignment create --role "Contributor" \
        --assignee ${APPID}
        # assign the User Access Administrator role
        az role assignment create --role "User Access Administrator" \
        --assignee ${APPID}
        ```

        outputs:

        ```json
        {
        "canDelegate": null,
        "condition": null,
        "conditionVersion": null,
        "description": null,
        "id": "/subscriptions/c973059c-87f4-4d89-8724-a0da5fe4ad5c/providers/Microsoft.Authorization/roleAssignments/2668acf3-d5ad-40a1-80a8-4cdb59ea87c2",
        "name": "2668acf3-d5ad-40a1-80a8-4cdb59ea87c2",
        "principalId": "16589f00-6ce3-4ad7-8575-21463d1e7576",
        "principalType": "ServicePrincipal",
        "roleDefinitionId": "/subscriptions/c973059c-87f4-4d89-8724-a0da5fe4ad5c/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c",
        "scope": "/subscriptions/c973059c-87f4-4d89-8724-a0da5fe4ad5c",
        "type": "Microsoft.Authorization/roleAssignments"
        }

        {
        "canDelegate": null,
        "condition": null,
        "conditionVersion": null,
        "description": null,
        "id": "/subscriptions/c973059c-87f4-4d89-8724-a0da5fe4ad5c/providers/Microsoft.Authorization/roleAssignments/222da8cc-dec1-4ee0-a79f-20c343e4d9c9",
        "name": "222da8cc-dec1-4ee0-a79f-20c343e4d9c9",
        "principalId": "16589f00-6ce3-4ad7-8575-21463d1e7576",
        "principalType": "ServicePrincipal",
        "roleDefinitionId": "/subscriptions/c973059c-87f4-4d89-8724-a0da5fe4ad5c/providers/Microsoft.Authorization/roleDefinitions/18d7d88d-d35e-4fb5-a5c3-7773c20a72d9",
        "scope": "/subscriptions/c973059c-87f4-4d89-8724-a0da5fe4ad5c",
        "type": "Microsoft.Authorization/roleAssignments"
        }
        ```

        ```sh
        # assign the Azure Active Directory Graph permission
        az ad app permission add --id ${APPID} \
        --api 00000002-0000-0000-c000-000000000000 \
        --api-permissions 824c81eb-e3f8-4ee6-8f6d-de7f50d565b7=Role
        # Approve the permissions request
        az ad app permission grant --id ${APPID} \
        --api 00000002-0000-0000-c000-000000000000
        ```

        output:

        ```log
        Invoking "az ad app permission grant --id 37f11bee-ecae-462c-850c-e8d2bf09a199 --api 00000002-0000-0000-c000-000000000000" is needed to make the change effective
        Operation failed with status: 'Bad Request'. Details: 400 Client Error: Bad Request for url: https://graph.windows.net/b1c14d5c-3625-45b3-a430-9552373a0c2f/oauth2PermissionGrants?api-version=1.6

        ```

        I do not have the rights to grant this permission. A SAS AD admin has to approve it. I was directed to Servicenow and I entered this request: [RITM0266758](https://sas.service-now.com/nav_to.do?uri=sc_req_item.do%3Fsys_id%3Defcece481b53781c34ab8485624bcbf1). For GELENABLE Stuart, Jeff or Mike have the permission to grant the permission.

### Using the SP

To login with this SP, use the following code

```sh
#OLD with SAS AAD
#APPID=37f11bee-ecae-462c-850c-e8d2bf09a199
#TENANTID=b1c14d5c-3625-45b3-a430-9552373a0c2f
#AZ_PASSWD=$(curl -s https://gelweb.race.sas.com/scripts/PSGEL300_001/security/PSGEL300_Secret.txt)
#New with GELNABLE
APPID=668399fd-8533-4915-bc82-9f4fda424aa8
TENANTID=a708fb09-1d96-416a-ad34-72fa07ff196d
curl -sk https://gelweb.race.sas.com/scripts/gelenable/security/PSGEL300_sp_cert.pem > /tmp/PSGEL300_sp_cert.pem
az login --service-principal -u ${APPID} -p /tmp/PSGEL300_sp_cert.pem --tenant ${TENANTID}
```

Result

```json
[
  {
    "cloudName": "AzureCloud",
    "homeTenantId": "a708fb09-1d96-416a-ad34-72fa07ff196d",
    "id": "c1eea1ae-7109-4c52-a776-3b75dfb5b684",
    "isDefault": true,
    "managedByTenants": [],
    "name": "PSGEL300 SAS Viya Deploy Red Hat OpenShift",
    "state": "Enabled",
    "tenantId": "a708fb09-1d96-416a-ad34-72fa07ff196d",
    "user": {
      "name": "668399fd-8533-4915-bc82-9f4fda424aa8",
      "type": "servicePrincipal"
    }
  },
  {
    "cloudName": "AzureCloud",
    "homeTenantId": "a708fb09-1d96-416a-ad34-72fa07ff196d",
    "id": "5483d6c1-65f0-400d-9910-a7a448614167",
    "isDefault": false,
    "managedByTenants": [],
    "name": "GEL Persistent Resources",
    "state": "Enabled",
    "tenantId": "a708fb09-1d96-416a-ad34-72fa07ff196d",
    "user": {
      "name": "668399fd-8533-4915-bc82-9f4fda424aa8",
      "type": "servicePrincipal"
    }
  }
]

```

## CoreOS image

### Revised instructions for GELENABLE

OCP requires s specific OS for the underlying images, [CoreOS](https://docs.openshift.com/container-platform/4.9/architecture/architecture-rhcos.html)

OCP [instructions](https://docs.openshift.com/container-platform/4.9/installing/installing_platform_agnostic/installing-platform-agnostic.html#installation-user-infra-machines-iso_installing-platform-agnostic) contain this note:

> The RHCOS images might not change with every release of OpenShift Container Platform. You must download images with **the highest version that is less than or equal to the OpenShift Container Platform version** that you install. Use the image versions that match your OpenShift Container Platform version if they are available.

Overall steps: <https://docs.openshift.com/container-platform/4.9/installing/installing_azure/installing-azure-user-infra.html#installation-azure-user-infra-uploading-rhcos_installing-azure-user-infra> :

*you must copy and store the RHCOS virtual hard disk (VHD) cluster image ... in a storage container so they are accessible during deployment*

1. Create a storage account in the shared persistent tenant (so that it's all safe from deletion)

    ```sh
    az account set --subscription "GEL Persistent Resources"
    #use the common group for all workshop shared storage
    RESOURCE_GROUP=GEL_Storage_Accounts
    AZURE_REGION=eastus2

    #az group create --name ${RESOURCE_GROUP}
    # create the storage account (name has to be lowercase)
    # The storage account named psgel300sa is already taken by the old tenant. change it to psgel300share
    SA_NAME=psgel300
    az storage account create -g ${RESOURCE_GROUP} --location ${AZURE_REGION} --name ${SA_NAME} --kind Storage --sku Standard_LRS
    # get one of the master keys to the storage
    ACCOUNT_KEY=$(az storage account keys list -g ${RESOURCE_GROUP} --account-name ${SA_NAME} --query "[0].value" -o tsv)
    ```

1. Create a storage container and upload the CoreOs image

    ```sh
    # create the Azure storage container
    az storage container create --name vhd --account-name ${SA_NAME} --account-key ${ACCOUNT_KEY}

    # upload the image - this may take a few  minutes
    # I will upload both a RHCOS 47 and a 49
    # get the image URL

    # as of 2022-08-05 this is:
    #"https://rhcos.blob.core.windows.net/imagebucket/rhcos-47.84.202206131038-0-azure.x86_64.vhd"
    VHD_URL_47=`curl -s https://raw.githubusercontent.com/openshift/installer/release-4.7/data/data/rhcos.json | jq -r .azure.url`
    az storage blob copy start --account-name ${SA_NAME} --account-key ${ACCOUNT_KEY} --destination-blob "rhcos-47.vhd" --destination-container vhd --source-uri "${VHD_URL_47}"

    # as of 2022-08-05 this is:
    #"https://rhcos.blob.core.windows.net/imagebucket/rhcos-410.84.202207061638-0-azure.x86_64.vhd"
    VHD_URL_410=`curl -s https://raw.githubusercontent.com/openshift/installer/release-4.10/data/data/coreos/rhcos.json | jq -r '.architectures.x86_64."rhel-coreos-extensions"."azure-disk".url'`
    az storage blob copy start --account-name ${SA_NAME} --account-key ${ACCOUNT_KEY} --destination-blob "rhcos-410.vhd" --destination-container vhd --source-uri "${VHD_URL_410}"

    # since the operations are asynchronous, check the status with:
    az storage blob show --account-name ${SA_NAME} --account-key ${ACCOUNT_KEY} --container-name vhd --name "rhcos-47.vhd" --query properties.copy
    az storage blob show --account-name ${SA_NAME} --account-key ${ACCOUNT_KEY} --container-name vhd --name "rhcos-410.vhd" --query properties.copy

    # get the URL to the blobs - this works while the blob is still being uploaded):
    VHD_BLOB_URL_47=$(az storage blob url --account-name ${SA_NAME}  -c vhd -n "rhcos-47.vhd" -o tsv 2>/dev/null)
    VHD_BLOB_URL_410=$(az storage blob url --account-name ${SA_NAME}  -c vhd -n "rhcos-410.vhd" -o tsv 2>/dev/null)
    echo ${VHD_BLOB_URL_47} ${VHD_BLOB_URL_410}
    ```

### Original instructions - superseded

OCP requires s specific OS for the underlying images, [CoreOS](https://docs.openshift.com/container-platform/4.7/architecture/architecture-rhcos.html)

OCP [instructions](https://docs.openshift.com/container-platform/4.7/installing/installing_platform_agnostic/installing-platform-agnostic.html#installation-user-infra-machines-iso_installing-platform-agnostic) contain this note:

> The RHCOS images might not change with every release of OpenShift Container Platform. You must download images with **the highest version that is less than or equal to the OpenShift Container Platform version** that you install. Use the image versions that match your OpenShift Container Platform version if they are available.

The instructions I followed use a script that, for every cluster, downloads the VHD image of ~1GB from RedHat to the local client, creates an Azure Storage account, and loads the uncompressed ~17GB VHD into an Azure storage blob.

I decided to consolidate this step and only do this once, saving the VHD in a shared Storage Account managed by GEL.

Here are the steps.

1. Create a storage account in the GEL tenant (so that it's safe)

    ```sh
    az account set --subscription GEL
    RESOURCE_GROUP=PSGEL300
    AZURE_REGION=eastus2

    az group create --name ${RESOURCE_GROUP}
    # create the storage account (name has to be lowercase)
    az storage account create -g ${RESOURCE_GROUP} --location ${AZURE_REGION} --name ${RESOURCE_GROUP,,}sa --kind Storage --sku Standard_LRS
    # get one of the master keys to the storage
    ACCOUNT_KEY=$(az storage account keys list -g ${RESOURCE_GROUP} --account-name ${RESOURCE_GROUP,,}sa --query "[0].value" -o tsv)
    ```

    <details><summary>Click to see the output</summary>

    ```json
    $ az group create --name ${RESOURCE_GROUP}
    {
    "id": "/subscriptions/b91ae007-b39e-488f-bbbf-bc504d0a8917/resourceGroups/PSGEL300",
    "location": "eastus2",
    "managedBy": null,
    "name": "PSGEL300",
    "properties": {
        "provisioningState": "Succeeded"
    },
    "tags": null,
    "type": "Microsoft.Resources/resourceGroups"
    }

    $ az storage account create -g ${RESOURCE_GROUP} --location ${AZURE_REGION} --name ${RESOURCE_GROUP,,}sa --kind Storage --sku Standard_LRS
    {
    "accessTier": null,
    "allowBlobPublicAccess": false,
    "allowCrossTenantReplication": null,
    "allowSharedKeyAccess": null,
    "azureFilesIdentityBasedAuthentication": null,
    "blobRestoreStatus": null,
    "creationTime": "2021-10-15T14:54:40.582259+00:00",
    "customDomain": null,
    "enableHttpsTrafficOnly": true,
    "enableNfsV3": null,
    "encryption": {
        "encryptionIdentity": null,
        "keySource": "Microsoft.Storage",
        "keyVaultProperties": null,
        "requireInfrastructureEncryption": null,
        "services": {
        "blob": {
            "enabled": true,
            "keyType": "Account",
            "lastEnabledTime": "2021-10-15T14:54:40.691658+00:00"
        },
        "file": {
            "enabled": true,
            "keyType": "Account",
            "lastEnabledTime": "2021-10-15T14:54:40.691658+00:00"
        },
        "queue": null,
        "table": null
        }
    },
    "extendedLocation": null,
    "failoverInProgress": null,
    "geoReplicationStats": null,
    "id": "/subscriptions/b91ae007-b39e-488f-bbbf-bc504d0a8917/resourceGroups/PSGEL300/providers/Microsoft.Storage/storageAccounts/psgel300sa",
    "identity": null,
    "isHnsEnabled": null,
    "keyCreationTime": {
        "key1": "2021-10-15T14:54:40.676036+00:00",
        "key2": "2021-10-15T14:54:40.676036+00:00"
    },
    "keyPolicy": null,
    "kind": "Storage",
    "largeFileSharesState": null,
    "lastGeoFailoverTime": null,
    "location": "eastus2",
    "minimumTlsVersion": null,
    "name": "psgel300sa",
    "networkRuleSet": {
        "bypass": "AzureServices",
        "defaultAction": "Allow",
        "ipRules": [],
        "resourceAccessRules": null,
        "virtualNetworkRules": []
    },
    "primaryEndpoints": {
        "blob": "https://psgel300sa.blob.core.windows.net/",
        "dfs": null,
        "file": "https://psgel300sa.file.core.windows.net/",
        "internetEndpoints": null,
        "microsoftEndpoints": null,
        "queue": "https://psgel300sa.queue.core.windows.net/",
        "table": "https://psgel300sa.table.core.windows.net/",
        "web": null
    },
    "primaryLocation": "eastus2",
    "privateEndpointConnections": [],
    "provisioningState": "Succeeded",
    "resourceGroup": "PSGEL300",
    "routingPreference": null,
    "sasPolicy": null,
    "secondaryEndpoints": null,
    "secondaryLocation": null,
    "sku": {
        "name": "Standard_LRS",
        "tier": "Standard"
    },
    "statusOfPrimary": "available",
    "statusOfSecondary": null,
    "tags": {
        "resourceowner": "Edoardo.Riva@sas.com"
    },
    "type": "Microsoft.Storage/storageAccounts"
    }
    ```

    </details>

1. Create a storage container and upload the CoreOs image

    > **WARNING**: this may require a few minutes and about 20GB of disk space on the local client. I tried to do it in my home dir and it exceeded my disk quota.
    > TO DO: Next time instead do a direct copy form the web url: <https://docs.openshift.com/container-platform/4.7/installing/installing_azure/installing-azure-user-infra.html#installation-azure-user-infra-uploading-rhcos_installing-azure-user-infra>

    ```sh
    # create the Azure storage container
    az storage container create --name vhd --account-name ${RESOURCE_GROUP,,}sa --account-key ${ACCOUNT_KEY}
    # get the image
    VHD_URL="https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.7/4.7.33/rhcos-azure.x86_64.vhd.gz"
    VHD_FILE=$(basename $VHD_URL)
    wget $VHD_URL
    # verify the image
    curl -s https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.7/4.7.33/sha256sum.txt | grep ${VHD_FILE} | sha256sum -c
    # extract the image - this may take a few minutes
    time gzip -d ${VHD_FILE}
    # upload the image - this may take a few more minutes
    time az storage blob upload --account-name ${RESOURCE_GROUP,,}sa --account-key ${ACCOUNT_KEY} --name "rhcos.vhd" --container vhd --file "${VHD_FILE%.gz}"
    #remove the local copy
    rm "${VHD_FILE%.gz}"
    # in case it's required:
    VHD_BLOB_URL=$(az storage blob url --account-name ${RESOURCE_GROUP,,}sa  -c vhd -n "rhcos.vhd" -o tsv 2>/dev/null)
    echo ${VHD_BLOB_URL}
    ```

    <details><summary>Click to see the output</summary>

    ```log
    $ az storage container create --name vhd --account-name ${RESOURCE_GROUP,,}sa --account-key ${ACCOUNT_KEY}
    {
      "created": true
    }
    $ wget $VHD_URL
    --2021-10-15 11:02:54--  https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.7/4.7.33/rhcos-azure.x86_64.vhd.gz
    Resolving mirror.openshift.com (mirror.openshift.com)... 54.172.173.155, 54.173.18.88, 54.172.163.83
    Connecting to mirror.openshift.com (mirror.openshift.com)|54.172.173.155|:443... connected.
    HTTP request sent, awaiting response... 200 OK
    Length: 1001539581 (955M) [application/x-gzip]
    Saving to: ‘rhcos-azure.x86_64.vhd.gz’

    rhcos-azure.x86_64.vhd.gz           100%[================================================================>] 955.14M  43.1MB/s    in 20s

    2021-10-15 11:03:15 (47.3 MB/s) - ‘rhcos-azure.x86_64.vhd.gz’ saved [1001539581/1001539581]

    $ curl -s https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.7/4.7.33/sha256sum.txt | grep ${VHD_FILE} | sha256sum -c
    rhcos-azure.x86_64.vhd.gz: OK
    $ time gzip -d ${VHD_FILE}

    real    1m56.759s
    user    1m46.191s
    sys     0m10.504s

    $ time az storage blob upload --account-name ${RESOURCE_GROUP,,}sa --account-key ${ACCOUNT_KEY} --name "rhcos.vhd" --container vhd --file "${VHD_FILE%.gz}"

    Finished[#############################################################]  100.0000%
    {
    "etag": "\"0x8D98FF2BB184785\"",
    "lastModified": "2021-10-15T15:44:53+00:00"
    }

    real    11m47.714s
    user    10m24.934s
    sys     0m12.059s
    rm "${VHD_FILE%gz}"

    $ VHD_BLOB_URL=$(az storage blob url --account-name ${RESOURCE_GROUP,,}sa  -c vhd -n "rhcos.vhd" -o tsv 2>/dev/null)
    $ echo ${VHD_BLOB_URL}
    https://psgel300sa.blob.core.windows.net/vhd/rhcos.vhd
    ```

    </details>

1. Check that the blob is secure.

    ```sh
    wget ${VHD_BLOB_URL}
    ```

    ```log
    $ wget https://psgel300sa.blob.core.windows.net/vhd/rhcos.vhd
    --2021-10-15 12:01:28--  https://psgel300sa.blob.core.windows.net/vhd/rhcos.vhd
    Resolving psgel300sa.blob.core.windows.net (psgel300sa.blob.core.windows.net)... 52.239.156.2
    Connecting to psgel300sa.blob.core.windows.net (psgel300sa.blob.core.windows.net)|52.239.156.2|:443... connected.
    HTTP request sent, awaiting response... 409 Public access is not permitted on this storage account.
    2021-10-15 12:01:28 ERROR 409: Public access is not permitted on this storage account..
    ```

## Custom virtual machine

### Create Images in an Image Gallery

It is not possible to create and then share VM images between subscriptions (the images would be in the `GEL Persistent Resources` subscription, while the workshop creates everything in a different one)

If you try to directly use an image across subscriptions, you'd get this error:

```log
+ az deployment group create -g PSGEL300-pdcesx02193 --template-file scripts/loop/viya4/../../../assets/azure/03_bootstrap.json --parameters bootstrapIgnition=eyJpZ25pdGlvbiI6eyJ2ZXJzaW9uIjoiMy4yLjAiLCJjb25maWciOnsicmVwbGFjZSI6eyJzb3VyY2UiOiJodHRwczovL3BkY2VzeDAyMTkzc2EuYmxvYi5jb3JlLndpbmRvd3MubmV0L2ZpbGVzL2Jvb3RzdHJhcC5pZ24/c2U9MjAyMS0xMC0xOVQxOCUzQTMzWiZzcD1yJnNwcj1odHRwcyZzdj0yMDE4LTExLTA5JnNyPWImc2lnPUQ0V3FuWDZsd1ZOY1pndEp3OW1VQVd4a0h0MWtYRSUyRlY5ajhXNDNOY0tNOCUzRCJ9fX19Cg== --parameters 'sshKeyData=ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDhw9+kXjLMdi1AnzYVfBbCa4L6cC1ebiW7UuAMB6vQUTMGHwrBRBbVZ23E2VdUsEGtEUk4qD1rpZRTrJRwnmaY3iEfRSOcrif1FOq8116r0unov8ne2RRYEI+PEYNCEnx/EiH38UBiNcsCxtNnW2BO3Cdq9nLzRjZr+OVookSCMlcFIiiMeMEh58F/Cx5LTt0LNUn4sgrnYHaoLtLvjddz9+igOKITnbIcNM2GK3ZkTdVZcfSeOyJUjcgdfqS7pG+o2DViMPv1Ttexu6s/aa1YuINvdWZOY/DYNyU0HF5ccOc9ewiiCTq0GU06dI1qWwoijiaZa808OwoZuvmWBlIz' --parameters baseName=PSGEL300-pdcesx02193 --parameters imageID=/subscriptions/b91ae007-b39e-488f-bbbf-bc504d0a8917/resourceGroups/PSGEL300/providers/Microsoft.Compute/images/PSGEL300-OCP47-image --parameters diagnosticStorageAccount=pdcesx02193sa
{"status":"Failed","error":{"code":"DeploymentFailed","message":"At least one resource deployment operation failed. Please list deployment operations for details. Please see https://aka.ms/DeployOperations for usage details.","details":[{"code":"BadRequest","message":"{\r\n  \"error\": {\r\n    \"code\": \"BadRequest\",\r\n    \"message\": \"Image sharing not supported for subscription.\"\r\n  }\r\n}"}]}}
```

Azure wants you to create an "[image gallery](https://docs.microsoft.com/en-us/azure/virtual-machines/shared-image-galleries)".

1. Use the shared image gallery

    ```sh
    RESOURCE_GROUP=GEL_COMPUTE_GALLERY
    SIG_ID=$(az sig list --resource-group ${RESOURCE_GROUP} | jq -r .[0].id)
    SIG_NAME=$(az sig list --resource-group ${RESOURCE_GROUP} | jq -r .[0].name)
    echo $SIG_ID
    echo $SIG_NAME
    ```

    ```log
    /subscriptions/5483d6c1-65f0-400d-9910-a7a448614167/resourceGroups/GEL_COMPUTE_GALLERY/providers/Microsoft.Compute/galleries/GEL_Compute_Gallery
    GEL_Compute_Gallery
    ```

1. For users to be able to access images form the gallery, they need RBAC permissions ("Reader" role). In this workshop, the user is the PSGEL300_sp service principal. Use the gallery object ID as a scope, along with the SP id and `az role assignment create` to give access rights to the shared image gallery.

    ```sh
    # PSGEL300_sp SP objectId
    SP_ID=$(az ad sp list --filter "displayName eq 'PSGEL300_sp'" --query [].objectId -o tsv)
    # assign the Reader role to the group
    az role assignment create --role "Reader" \
      --assignee ${SP_ID} --scope ${SIG_ID}
    ```

1. Create image definitions. From the doc: *"Image definitions create a logical grouping for images. They are used to manage information about the image versions that are created within them."*.

    ```sh
    az sig image-definition create \
    --resource-group ${RESOURCE_GROUP} \
    --gallery-name ${SIG_NAME} \
    --gallery-image-definition PSGEL300-OCP-47 \
    --publisher SAS \
    --offer OCP \
    --sku SAS-OCP-47 \
    --os-type Linux \
    --os-state generalized

    az sig image-definition create \
    --resource-group ${RESOURCE_GROUP} \
    --gallery-name ${SIG_NAME} \
    --gallery-image-definition PSGEL300-OCP-410 \
    --publisher SAS \
    --offer OCP \
    --sku SAS-OCP-410 \
    --os-type Linux \
    --os-state generalized

    ```

1. Create an image version

    ```sh
    # Find the VHD URLs
    VHD_BLOB_URL_47=$(az storage blob url --account-name ${SA_NAME}  -c vhd -n "rhcos-47.vhd" -o tsv 2>/dev/null)
    VHD_BLOB_URL_410=$(az storage blob url --account-name ${SA_NAME}  -c vhd -n "rhcos-410.vhd" -o tsv 2>/dev/null)

    # create the image version - this will take a few minutes
    # copy them in multiple regions for HA (they cost less than a dollar per month)
    az sig image-version create \
    --resource-group ${RESOURCE_GROUP} \
    --gallery-name ${SIG_NAME} \
    --gallery-image-definition PSGEL300-OCP-47 \
    --gallery-image-version 1.0.0 \
    --os-vhd-storage-account ${SA_NAME} \
    --os-vhd-uri ${VHD_BLOB_URL_47} \
    --target-regions eastus2 eastus westus2 \
    --no-wait

    az sig image-version create \
    --resource-group ${RESOURCE_GROUP} \
    --gallery-name ${SIG_NAME} \
    --gallery-image-definition PSGEL300-OCP-410 \
    --gallery-image-version 1.0.0 \
    --os-vhd-storage-account ${SA_NAME} \
    --os-vhd-uri ${VHD_BLOB_URL_410} \
    --target-regions eastus2 eastus westus2 \
    --no-wait
    ```

    <details><summary>Click to see the output</summary>

    ```log
    $ az role assignment create --role "Reader" \
    >       --assignee ${SP_ID} --scope ${SIG_ID}
    {
    "canDelegate": null,
    "condition": null,
    "conditionVersion": null,
    "description": null,
    "id": "/subscriptions/5483d6c1-65f0-400d-9910-a7a448614167/resourceGroups/GEL_COMPUTE_GALLERY/providers/Microsoft.Compute/galleries/GEL_Compute_Gallery/providers/Microsoft.Authorization/roleAssignments/62754061-6c25-469c-a999-922453356408",
    "name": "62754061-6c25-469c-a999-922453356408",
    "principalId": "47786469-ad4b-4680-abc6-8034f523f975",
    "principalType": "ServicePrincipal",
    "resourceGroup": "GEL_COMPUTE_GALLERY",
    "roleDefinitionId": "/subscriptions/5483d6c1-65f0-400d-9910-a7a448614167/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7",
    "scope": "/subscriptions/5483d6c1-65f0-400d-9910-a7a448614167/resourceGroups/GEL_COMPUTE_GALLERY/providers/Microsoft.Compute/galleries/GEL_Compute_Gallery",
    "type": "Microsoft.Authorization/roleAssignments"
    }
    $ az sig image-definition create \
    >     --resource-group ${RESOURCE_GROUP} \
    >     --gallery-name ${SIG_NAME} \
        --os-type Linux \
        --os-state generalized>     --gallery-image-definition PSGEL300-OCP-47 \
    >     --publisher SAS \
    >     --offer OCP \
    >     --sku SAS-OCP-47 \
    >     --os-type Linux \
    >     --os-state generalized
    {
    "description": null,
    "disallowed": null,
    "endOfLifeDate": null,
    "eula": null,
    "features": null,
    "hyperVGeneration": "V1",
    "id": "/subscriptions/b91ae007-b39e-488f-bbbf-bc504d0a8917/resourceGroups/PSGEL300/providers/Microsoft.Compute/galleries/GEL/images/PSGEL300-OCP-47",
    "identifier": {
        "offer": "OCP",
        "publisher": "SAS",
        "sku": "SAS-OCP-47"
    },
    "location": "eastus2",
    "name": "PSGEL300-OCP-47",
    "osState": "Generalized",
    "osType": "Linux",
    "privacyStatementUri": null,
    "provisioningState": "Succeeded",
    "purchasePlan": null,
    "recommended": null,
    "releaseNoteUri": null,
    "resourceGroup": "PSGEL300",
    "tags": {
        "resourceowner": "Edoardo.Riva@sas.com"
    },
    "type": "Microsoft.Compute/galleries/images"
    }
    $ # get the VHD URL
    $ VHD_BLOB_URL=$(az storage blob url --account-name ${SA_NAME}  -c vhd -n "rhcos.vhd" -o tsv 2>/dev/null)
    $ # create the image version
    $ az sig image-version create \
    >     --resource-group ${RESOURCE_GROUP} \
    >     --gallery-name GEL \
    >     --gallery-image-definition PSGEL300-OCP-47 \
    >     --gallery-image-version 1.0.0 \
    >     --os-vhd-storage-account ${RESOURCE_GROUP,,}sa \
    >     --os-vhd-uri ${VHD_BLOB_URL}
    {
    "id": "/subscriptions/b91ae007-b39e-488f-bbbf-bc504d0a8917/resourceGroups/PSGEL300/providers/Microsoft.Compute/galleries/GEL/images/PSGEL300-OCP-47/versions/1.0.0",
    "location": "eastus2",
    "name": "1.0.0",
    "provisioningState": "Succeeded",
    "publishingProfile": {
        "endOfLifeDate": null,
        "excludeFromLatest": false,
        "publishedDate": "2021-10-19T20:08:25.025340+00:00",
        "replicaCount": 1,
        "storageAccountType": "Standard_LRS",
        "targetRegions": [
        {
            "encryption": null,
            "name": "East US 2",
            "regionalReplicaCount": 1,
            "storageAccountType": "Standard_LRS"
        }
        ]
    },
    "replicationStatus": null,
    "resourceGroup": "PSGEL300",
    "storageProfile": {
        "dataDiskImages": null,
        "osDiskImage": {
        "hostCaching": "ReadWrite",
        "sizeInGb": null,
        "source": {
            "id": "/subscriptions/b91ae007-b39e-488f-bbbf-bc504d0a8917/resourceGroups/PSGEL300/providers/Microsoft.Storage/storageAccounts/psgel300sa",
            "resourceGroup": "PSGEL300",
            "uri": "https://psgel300sa.blob.core.windows.net/vhd/rhcos.vhd"
        }
        },
        "source": null
    },
    "tags": {
        "resourceowner": "Edoardo.Riva@sas.com"
    },
    "type": "Microsoft.Compute/galleries/images/versions"
    }

    ```

    </details>

## Save security artifacts on GELWEB

Where is it all saved: <https://gelweb.race.sas.com/scripts/PSGEL300_001/security/>

What we save :

* PSGEL300 credentials : See step #6 of [creating the SP](#script-to-create-the-sp)
* OCP pull secret: I got the pull-secret of gelenablement@sas.com from RedHat web console at <https://console.redhat.com/openshift/downloads#tool-pull-secret>

    ```sh
    OCP_SECRET=$(cat ~/openshift/install/pull-secret.json)
    echo ${OCP_SECRET} | ssh glsuser1@gelweb.race.sas.com -C "cat > /data/workshops/PSGEL300_001/security/pull-secret.json"
    ## verify
    curl -s https://gelweb.race.sas.com/scripts/PSGEL300_001/security/pull-secret.json | diff - <(echo ${OCP_SECRET})
    ```

Note :  pull-secret is something like this (redacted to protect mine !!)

{auths:{cloud.openshift.com:{auth:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx==,email:gelenablement@sas.com},quay.io:{auth:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx==,email:gelenablement@sas.com},registry.connect.redhat.com:{auth:yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy==,email:gelenablement@sas.com},registry.redhat.io:{auth:yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy==,email:Edoardo.Riva@sas.com}}}

## Save artifacts in Azure KeyVault

* Move the pull-secret in Azure KeyVault (done while logged in as myself on cldlgn)

    ```sh
    az account set --subscription "GEL Persistent Resources"
    #use the common group
    RESOURCE_GROUP=GEL_KEY_VAULT
    KV_NAME=gel-keyvault
    #the pull secret is a single-line json
    PULL_SECRET=$(curl -s https://gelweb.race.sas.com/scripts/PSGEL300_001/security/pull-secret.json)
    az keyvault secret set --name gel-ocp-pull-secret --vault-name ${KV_NAME} --value ${PULL_SECRET}
    ```

* Then secure it to the workshop principal

    See <https://learn.microsoft.com/en-us/azure/key-vault/general/rbac-guide?tabs=azure-cli#secret-scope-role-assignment>

    ```sh
    # PSGEL300_sp SP objectId
    # note az up to version 2.36 uses the field objectID; starting from 2.37 it is just id
    SP_ID=$(az ad sp list --filter "displayName eq 'PSGEL300_sp'" --query [].id -o tsv)

    # assign the Key Vault Secrets User role to the PSGEL300_sp principal
    SUBSCRIPTIONID=$(az account show --query id -o tsv)
    az role assignment create --role "Key Vault Secrets User" \
      --assignee ${SP_ID} --scope "/subscriptions/${SUBSCRIPTIONID}/resourcegroups/${RESOURCE_GROUP}/providers/Microsoft.KeyVault/vaults/${KV_NAME}/secrets/gel-ocp-pull-secret"
    ```
