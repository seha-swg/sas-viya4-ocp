![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Verify that the workshop environment is functional

* [Introduction](#introduction)
* [Verify your collection](#verify-your-collection)
  * [Has the collection finished bootstrapping?](#has-the-collection-finished-bootstrapping)
  * [Make sure kubectl is installed](#make-sure-kubectl-is-installed)
  * [Make sure Kustomize is installed](#make-sure-kustomize-is-installed)
  * [Make sure jq is installed](#make-sure-jq-is-installed)
  * [Make sure oc is installed](#make-sure-oc-is-installed)
* [Validate the Azure environment](#validate-the-azure-environment)
  * [Login to Azure](#login-to-azure)
  * [Set the Azure CLI defaults](#set-the-azure-cli-defaults)
  * [Find your Azure resource group](#find-your-azure-resource-group)
* [Next Steps](#next-steps)
* [Complete Hands-on Navigation Index](#complete-hands-on-navigation-index)

## Introduction

In this workshop, we use an OpenShift Container Platform (OCP) cluster, which has been automatically installed on Azure and is dedicated for your use within this workshop.

The objective of this initial exercise is to verify the readiness of the environment, familiarize with some tools, and exercise basic commands.

## Verify your collection

* Connect to the Windows machine of your collection (as Student/Metadata0).
* In the following steps, **we will run the commands from the sasnode01 session from within MobaXterm** on the Windows client machine.

See [01_011_Access_the_Environment.md](01_011_Access_the_Environment.md) to book the collection if you have not already done so.

### Has the collection finished bootstrapping?

If you connect to the collection as soon as you receive the confirmation e-mail, the collection is probably still in the process of self-configuring.

You need to wait until that process is done. (less than 1 hour, usually).

In order to confirm that the bootstrapping is finished and successful, do the following:

1. Execute the following command on sasnode01:

    ```sh
    tail -f /opt/gellow_work/logs/gellow_summary.log
    ```

1. Wait for the last lines to say:

    ```log
    PASS Final message: It seems everything deployed successfully!
    PASS Final message: You can start using this collection
    NOTE: sending message to teams channel for ALL reservations.
    #####################################################################################
    ####### DONE WITH THE BOOTSTRAPPING OF THE MACHINE ##################################
    #####################################################################################
    ```

1. Now, you can hit `Ctrl +C` keys to exit the interactive "tail" command.

1. If the lines include any ERROR or FAIL message, see this [troubleshooting page](01_013_Troubleshooting.md).

### Make sure kubectl is installed

* Run the command below to show the installed version:

    ```bash
    kubectl version --client --short
    ```

    The kubectl version on the client machine can be only one minor version later or earlier than the version of Kubernetes that is used in the cluster. For example, if the client version is 1.22, then the server version can be 1.23 but not 1.24. For more information, see the [Kubernetes version skew policy](https://kubernetes.io/releases/version-skew-policy/).

### Make sure Kustomize is installed

* Run the command below to show the installed version:

    ```bash
    kustomize version
    ```

    The [SAS Viya Operations](https://go.documentation.sas.com/doc/en/itopscdc/v_031/itopssr/n1ika6zxghgsoqn1mq4bck9dx695.htm#n0u8dut20wmtp3n1jukmbg0dmim5) guide lists the supported version (as of August 2022, this is 3.7.0)

### Make sure jq is installed

* Run the command below to verify that `jq` is installed:

    ```bash
    jq --version
    ```

    `jq` is not a prerequisite to deploy SAS Viya, but it's a very useful tool to parse and format the json output produced by many commands.

### Make sure oc is installed

* `oc` is the [OpenShift CLI](https://docs.openshift.com/container-platform/4.10/cli_reference/openshift_cli/getting-started-cli.html#cli-about-cli_cli-developer-commands)
* Run the command below to show the installed version

    ```bash
    oc version --client
    ```

    This workshop provides an `oc` client with the same version as the OpenShift cluster. For additional information about version compatibility, see [Red Hat documentation](https://docs.openshift.com/container-platform/4.10/cli_reference/openshift_cli/usage-oc-kubectl.html).

## Validate the Azure environment

### Login to Azure

1. Run the command below to show the installed version of the Azure CLI

    ```bash
    az version
    ```

    For this workshop we have installed the Azure CLI version 2.36; later versions introduce [breaking changes](https://docs.microsoft.com/en-us/cli/azure/microsoft-graph-migration) that may not work in all exercises.

1. Login to the Azure CLI.

    ```sh
    # Use a device code login
    az login --use-device-code
    ```

    You should see output similar to

    ```log
    [cloud-user@pdcesx04215 ~]$ az login --use-device-code
    To sign in, use a web browser to open the page https://microsoft.com/devicelogin and enter the code XXXXXXXXX to authenticate.
    ```
<!--
Auto-logon for the cheatcodes
```bash
az account show
if [[ $? == 1 ]]; then
  az login -u gatedemo003@gelenable.sas.com -p Metadata0
fi
```
-->

1. Open the web browser and paste the URL [https://microsoft.com/devicelogin](https://microsoft.com/devicelogin)

    ![azure_device_login](/img/azuredevicelogin.png)

1. Now copy and paste the device code in the Web form and click "Next". On the Sign in form, use the `gatedemo003@gelenable.sas.com` email with the `Metadata0` password.

    ![email4login](/img/email4login.png)

    You may get the following message to confirm the use of the Azure CLI. Click 'Continue'.

    ![cli_confirm](/img/cli_confirm.png)

    You should see a window confirming that you are logged.

    ![logged_in](/img/loggedin.png)

1. Back to your terminal, make sure it worked

    You should see output similar to the following. You will get multiple entries based on the Azure subscriptions the `gatedemo003@gelenable.sas.com` user is member of. In the next step we will verify that "PSGEL300 SAS Viya Deploy Red Hat OpenShift" is included in the listing.

    ```log
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
          "name": "gatedemo003@gelenable.sas.com",
          "type": "user"
        }
      },
    ...

    ```

### Set the Azure CLI defaults

* Make sure that `PSGEL300 SAS Viya Deploy Red Hat OpenShift` is the default subscription:

  ```bash
  az account set -s "PSGEL300 SAS Viya Deploy Red Hat OpenShift"
  ```

  let's now list all the subscriptions we have access to and verify that the default one is `PSGEL300 SAS Viya Deploy Red Hat OpenShift`:

    ```sh
    az account list -o table
    ```

  <details><summary>Click here to see the expected output</summary>

  You may have one or more subscriptions, including others not shown here.

  ```log
  [cloud-user@pdcesx04215 ~]$ az account list -o table
  Name                                                              CloudName    SubscriptionId                        State    IsDefault
  ----------------------------------------------------------------  -----------  ------------------------------------  -------  -----------
  PSGEL300 SAS Viya Deploy Red Hat OpenShift                        AzureCloud   c1eea1ae-7109-4c52-a776-3b75dfb5b684  Enabled  True
  PSGEL286 SAS Viya 4: Data Management on Azure Cloud               AzureCloud   d588dad0-2004-4b14-a34e-6bf0519e32e4  Enabled  False
  PSGEL271 Model Operations Using SAS Model Manager on SAS Viya 4   AzureCloud   520ca0a1-1543-4d7c-a491-372cfdc3a896  Enabled  False
  PSGEL270 SAS Viya: Migration                                      AzureCloud   0629a4b9-42cc-4f29-8a6b-f456f7c1d6e4  Enabled  False
  PSGEL287 Data Governance with SAS                                 AzureCloud   85fd677d-e833-4096-99ec-6cff57204198  Enabled  False
  PSGEL260 SAS Viya 4: Administration                               AzureCloud   5f4c9d2e-c29a-4e3e-a9c0-2ceda7820633  Enabled  False
  PSGEL284 Using SAS Event Stream Processing on SAS Viya 4          AzureCloud   87865a58-d70e-4147-893b-6c0b7226294c  Enabled  False
  PSGEL309 SAS Viya 4: Arch Admin SAS Workload Management           AzureCloud   aa6edc9a-88e8-4cc8-a6d3-cbf1ad23273d  Enabled  False
  PSGEL298 SAS Viya 4: Deployment on Azure Kubernetes Service       AzureCloud   e8d9e6ad-9325-4c8d-a301-4e659340fc8b  Enabled  False
  PSGEL306 SAS Viya 4: Multi-tenancy                                AzureCloud   6a70b249-f8ae-4761-9a3a-7d46c11cdd57  Enabled  False
  PSGEL255 Deploying SAS Viya 4                                     AzureCloud   cc76e9ff-1828-45e3-b752-151979fb363a  Enabled  False
  PSGEL283 Applying DevOps Principles to SAS Viya Data Management   AzureCloud   2bd6975d-40dd-4287-b220-394f55cd58bc  Enabled  False
  PSGEL261 SAS Viya 4: Data Management                              AzureCloud   1562c49d-0a8a-4222-8d8b-f0707fae8000  Enabled  False
  PSGEL288 SAS Viya 4: Data Management on Google Cloud Platform     AzureCloud   ee7220bf-abdb-4142-893b-e88691110519  Enabled  False
  PSGEL299 SAS Viya 4: SAS In-Database Technologies                 AzureCloud   0a3a87fd-33cd-45b4-9799-7e72cce61729  Enabled  False
  PSGEL289 SAS Viya 4: Data Management on Amazon Web Services       AzureCloud   85e60f61-394d-4e1f-b395-581c61fd1789  Enabled  False
  PSGEL312 Using SAS ESP on SAS Viya 4: Fundamentals                AzureCloud   c3939ca2-cbad-451a-aaa7-b36cae5bfecd  Enabled  False
  PSGEL314 SAS Viya: SAS Data Preparation                           AzureCloud   3f3cd3b2-495d-491a-9c7c-29de1cd34646  Enabled  False
  PSGEL280 Using SAS Visual Forecasting on SAS Viya 4               AzureCloud   515f8ff4-3d69-49dd-9dde-e62f50506738  Enabled  False
  PSGEL281 SAS Viya 4: Observability                                AzureCloud   de2b4271-8b32-44b5-9a96-36ee5fe6173c  Enabled  False
  PSGEL282 Designing Chatbots Using SAS Conversation Designer       AzureCloud   226a7056-7afd-41f2-96a6-afa717ae84dc  Enabled  False
  PSGEL305 SAS Container Runtime - Arch & Dep on Azure Cloud        AzureCloud   3ec002b2-e853-4615-aa44-b625dbd8f200  Enabled  False
  PSGEL278 Artificial Intelligence with SAS VDMML on SAS Viya 4     AzureCloud   c2a3f499-f65a-4e1c-87a5-39b7369085e3  Enabled  False
  PSGEL317 SAS Apro Deploy Config                                   AzureCloud   f1e5039a-7df8-4e21-903f-52a11878f7f0  Enabled  False
  PSGEL313 Using Azure DevOps and Azure Pipelines with SAS Viya     AzureCloud   eb8de514-6460-4568-a509-23ef413663da  Enabled  False
  PSGEL266 SAS Viya 4: Architecture                                 AzureCloud   684cd533-fc34-4140-9a58-1fba5ec92caa  Enabled  False
  PSGEL296 SAS Viya 4: Deployment on Google Kubernetes Engine       AzureCloud   b7a8eebd-806d-4313-b9ec-8602f021896a  Enabled  False
  PSGEL307 SAS Viya 4: Administration on Azure Kubernetes Service   AzureCloud   616d9cb1-6363-4db3-a5a5-1b86b6b6fcfd  Enabled  False
  PSGEL277 Designing Reports Using VA on SAS Viya 4                 AzureCloud   c1c92ed9-6d9b-454e-9077-bbbb7533020d  Enabled  False
  PSGEL268 Programming with CAS on SAS Viya 4                       AzureCloud   911c0a89-ac27-45fc-b151-e4eccecd2a92  Enabled  False
  PSGEL315 SAS Viya: SAS Studio Flow and Custom Steps               AzureCloud   697568a8-3e5c-42d1-9d8c-03e2a85ff3e5  Enabled  False
  PSGEL262 SAS Viya 4: Advanced Topics in Encryption                AzureCloud   51a7023c-557c-4f7d-8ddd-6b85aeb58e8f  Enabled  False
  PSGEL263 SAS Viya 4 Adv Topics in Authentication                  AzureCloud   77fda233-2cc4-422b-915e-4ee8d2cabe77  Enabled  False
  PSGEL279 Using SAS Visual Statistics and SAS VDMML on SAS Viya 4  AzureCloud   2ea48c4b-6e0d-46c2-ab99-7a35fb8d0edc  Enabled  False
  PSGEL267 Using SAS Intelligent Decisioning on SAS Viya 4          AzureCloud   e770a687-bc40-4dad-a4c8-8a260676aa24  Enabled  False
  PSGEL297 SAS Viya 4: Deployment on Amazon EKS                     AzureCloud   e7043c05-1fa6-4ce7-852b-9c80183a574b  Enabled  False
  PSGEL272 Using REST APIs in SAS Viya 4                            AzureCloud   7c73db4d-888a-4a7e-b6bc-757dcf7a0e3f  Enabled  False
  PSGEL311 Using SAS ESP on SAS Viya 4: Advanced                    AzureCloud   43c1cc7c-7cd3-4baa-b998-6ee44f1848b4  Enabled  False
  ```

</details>

> &#9888; If the `az account set` command failed and/or you cannot see `PSGEL300 SAS Viya Deploy Red Hat OpenShift` in the table of your subscriptions, then you cannot proceed with the rest of the workshop. Please refer to [00 001 Access Environments](/00_001_Access_Environments.md) for instructions on accessing this required subscription.

### Find your Azure resource group

* The OCP cluster that has been created on Azure is part of a resource group named after your user id and the linux RACE client. For example, if you are working in a machine named `azureuse020285`, then the Azure resource group may be called `itaedr-a20285`.
  > If you are attending this workshop as part of a live class, then the resource group will not include your user id: it will have a random name such as `gamma-p03030`.

* You can query Azure to verify that the group exists:

    ```sh
    az group show --name ${AZURE_RG}
    ```

    You should see output similar to

    ```log
    [cloud-user@azureuse020285 ~]$ az group show --name ${AZURE_RG}
    {
      "id": "/subscriptions/c1eea1ae-7109-4c52-a776-3b75dfb5b684/resourceGroups/itaedr-a20285",
      "location": "eastus2",
      "managedBy": null,
      "name": "itaedr-a20285",
      "properties": {
        "provisioningState": "Succeeded"
      },
      "tags": {
        "RACE_Host": "azureuse020285",
        "gel_id": "sasdemo.nonvlrs",
        "gel_project": "PSGEL300",
        "resourceowner": "gelenable@sas.com"
      },
      "type": "Microsoft.Resources/resourceGroups"
    }
    ```

* You can also browse in the [Azure portal](https://portal.azure.com/) to see all the resources that have been created in the resource group. From the Home page, select *Resource Groups* and then the group with the name you just displayed:

![Azure Resource Group](/img/azure_resourcegroup.png)

> &#9888; *Note: If you don't see your resource group, you might not be looking in the correct subscription. If you don't see the "PSGEL300 SAS Viya Deploy Red Hat OpenShift" subscription you might have to change the global subscription filter in the "Subscription" menu*

## Next Steps

Now that you have verified that the workshop environment is functional, you can move to the next exercise to learn how to interact with OpenShift.

Click [here](/02_OpenShift_Introduction/02_031_Explore_OpenShift.md) to move onto the next exercise: ***02 031 Explore OpenShift***

---

## Complete Hands-on Navigation Index

<!-- startnav -->
* [01 Workshop Introduction / 01 011 Access the Environment](/01_Workshop_Introduction/01_011_Access_the_Environment.md)
* [01 Workshop Introduction / 01 012 Verify the Environment](/01_Workshop_Introduction/01_012_Verify_the_Environment.md)**<-- you are here**
* [01 Workshop Introduction / 01 999 Fast track with cheatcodes](/01_Workshop_Introduction/01_999_Fast_track_with_cheatcodes.md)
* [02 OpenShift Introduction / 02 031 Explore OpenShift](/02_OpenShift_Introduction/02_031_Explore_OpenShift.md)
* [04 Deployment / 04 021 Perform the Prerequisites](/04_Deployment/04_021_Perform_the_Prerequisites.md)
* [04 Deployment / 04 022 Prepare for Viya Deployment](/04_Deployment/04_022_Prepare_for_Viya_Deployment.md)
* [04 Deployment / 04 023 Prepare for OpenShift](/04_Deployment/04_023_Prepare_for_OpenShift.md)
* [04 Deployment / 04 024 Customize Viya Deployment](/04_Deployment/04_024_Customize_Viya_Deployment.md)
* [04 Deployment / 04 025 Manually Deploy Viya](/04_Deployment/04_025_Manually_Deploy_Viya.md)
* [04 Deployment / 04 999 Cleanup](/04_Deployment/04_999_Cleanup.md)
* [README](/README.md)
<!-- endnav -->
