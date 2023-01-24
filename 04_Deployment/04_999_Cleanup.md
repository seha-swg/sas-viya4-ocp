![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

* [Clean up - why?](#clean-up---why)
* [Deleting the cluster with the openshift-install CLI](#deleting-the-cluster-with-the-openshift-install-cli)
* [Deleting the cluster from the Azure portal](#deleting-the-cluster-from-the-azure-portal)
* [Next Steps](#next-steps)
* [Complete Hands-on Navigation Index](#complete-hands-on-navigation-index)

## Clean up - why?

**Running SAS Viya in the Cloud is not free!**

* When we create an OCP cluster for you to deploy Viya on it, a lot of infrastructure resources needs to be created in the Cloud on your behalf (Virtual Network, VMs, Disks,  Load-balancers, etc...)

* Although we try to reduce them as much as possible (smaller instances, autoscaling with minimum node count set to 0), it still generates significant costs: we roughly estimate them at `50 US dollars` when you let your cluster run for 8 hours.

* This is the reason why we provide you ways to clean-up the environment and destroy your cluster once you have completed your training activity.

## Deleting the cluster with the openshift-install CLI

* The `openshift-install` CLI can delete the OpenShift cluster, the Azure resource group it belongs to, and all related cloud artifacts.
* This requires access to the original directory used to deploy the cluster, which contains the files that define it and grant full administrative access.
* For this workshop, these files are owned by root, so we'll have to switch user first.

    ```sh
    #become root
    sudo su -
    #move to the OCP deployment directory
    cd /home/cloud-user/project/clusterconfig/
    #destroy the cluster and related Azure resources
    openshift-install destroy cluster
    ```

## Deleting the cluster from the Azure portal

> Note: While it is possible to delete resources using the Azure Portal, for the workshop environment this is NOT possible. The 'gatedemoxxx' users only have READ access to the resources, therefore, it is not possible to use the Portal to delete the resources.
>
> This section is left only for reference, in case you are managing your own environment with full access.

* You can delete your cluster simply by deleting the resource group in the Azure Portal
* Select your resource group and click on the "Delete Resource Group" button.
   > TIP: if you do not remember your resource group, it should be named after your userid and the linux RACE client. For example, if you are working in the machine named `pdcesx03051`, then the Azure resource group is called `sasdemo-p03051`.

    ![delete rg](/img/delete_rg1.png)
    ![delete rg2](/img/delete_rg2.png)

* You will have to confirm by providing the Resource Group name.

    ![confirm deletion](/img/delete_rg3.png)

* The previous instructions are equivalent to the following command line using the az CLI.

    ```sh
    echo "Going to delete the Resource Group ${AZURE_RG}."
    az group delete --name ${AZURE_RG}
    ```

    You will be asked to confirm the operation. It will take a few minutes.

---

## Next Steps

You have finished the Hands-on instructions for this workshop.

---

## Complete Hands-on Navigation Index
<!-- startnav -->
* [01 Workshop Introduction / 01 011 Access the Environment](/01_Workshop_Introduction/01_011_Access_the_Environment.md)
* [01 Workshop Introduction / 01 012 Verify the Environment](/01_Workshop_Introduction/01_012_Verify_the_Environment.md)
* [01 Workshop Introduction / 01 999 Fast track with cheatcodes](/01_Workshop_Introduction/01_999_Fast_track_with_cheatcodes.md)
* [02 OpenShift Introduction / 02 031 Explore OpenShift](/02_OpenShift_Introduction/02_031_Explore_OpenShift.md)
* [04 Deployment / 04 021 Perform the Prerequisites](/04_Deployment/04_021_Perform_the_Prerequisites.md)
* [04 Deployment / 04 022 Prepare for Viya Deployment](/04_Deployment/04_022_Prepare_for_Viya_Deployment.md)
* [04 Deployment / 04 023 Prepare for OpenShift](/04_Deployment/04_023_Prepare_for_OpenShift.md)
* [04 Deployment / 04 024 Customize Viya Deployment](/04_Deployment/04_024_Customize_Viya_Deployment.md)
* [04 Deployment / 04 025 Manually Deploy Viya](/04_Deployment/04_025_Manually_Deploy_Viya.md)
* [04 Deployment / 04 999 Cleanup](/04_Deployment/04_999_Cleanup.md)**<-- you are here**
* [README](/README.md)
<!-- endnav -->
