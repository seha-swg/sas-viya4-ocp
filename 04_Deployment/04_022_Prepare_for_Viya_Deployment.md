![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Prepare the cluster for SAS Viya

* [Prepare the Order's Deployment Assets](#prepare-the-orders-deployment-assets)
* [Create a site-config directory](#create-a-site-config-directory)
* [Create the namespace and the administrator for SAS Viya](#create-the-namespace-and-the-administrator-for-sas-viya)
* [Next Steps](#next-steps)
* [Complete Hands-on Navigation Index](#complete-hands-on-navigation-index)

## Prepare the Order's Deployment Assets

The first step to deploy SAS Viya is to retrieve the deployment assets. In a normal scenario, you would:

   1. log in to the <https://my.sas.com/> portal and
   1. download a .tgz file containing your assets
   1. explode the .tgz into `~/project/gelocp/` (our project directory)
   1. which would create `~/project/gelocp/sas-bases`

Instead, in order to keep the materials in this course up to date, we will use a script to generate the assets for you.

1. Run the following commands (copy-paste all lines together)

    ```bash
    cd ~/project
    #load parameters from file
    source <( cat /opt/gellow_work/vars/vars.txt )

    echo "SAS Viya cadence and version = ${GELLOW_CADENCE_NAME}-${GELLOW_CADENCE_VERSION}"

    bash /opt/gellow_code/scripts/common/generate_sas_bases.sh \
          --cadence-name ${GELLOW_CADENCE_NAME} \
          --cadence-version ${GELLOW_CADENCE_VERSION} \
          --order-nickname ${GELLOW_ORDERNICKNAME} \
          --output-folder ~/project/gelocp
    ```

## Create a site-config directory

We need to create a "site-config" directory to store our specific configuration (it is a separated space from the software-provided manifests).

1. Run the following commands

    ```bash
    mkdir -p ~/project/gelocp/site-config/
    mkdir -p ~/project/gelocp/site-config/security/
    mkdir -p ~/project/gelocp/site-config/configure-postgres/internal/pgo-client
    ```

## Create the namespace and the administrator for SAS Viya

1. Run this command to create the "gel-viya" namespace in our cluster. Remember, this is possible because we logged into the OCP cluster as a user with full cluster-admin rights.

    ```bash
    oc new-project gel-viya
    ```

1. In this workshop, we want to operate in a way that is close to customer environments. For this reason, we'll create a dedicated administrator with full permissions on the gel-viya namespace, but limited access to the cluster.

    Submit the following code to grant namespace administrative capabilities to the `gatedemo004` user

    ```bash
    oc create rolebinding \
        sas-viya-admin \
        --clusterrole=admin \
        --namespace=gel-viya \
        --user="gatedemo004"
    ```

1. Verify user permissions.

    ```sh
    # gatedemo004 does not have access to cluster-scoped artifacts:
    kubectl auth can-i create projects --as gatedemo004
    kubectl auth can-i create crd --as gatedemo004
    # gatedemo003 instead has access to cluster-scoped artifacts:
    kubectl auth can-i create projects --as gatedemo003
    kubectl auth can-i create crd --as gatedemo003
    # gatedemo004 only has access to the gel-viya namespace:
    kubectl auth can-i create pods --namespace default --as gatedemo004
    kubectl auth can-i create pods --namespace gel-viya --as gatedemo004
    ```

    You should see output similar to the following:

    ```log
    $ # gatedemo004 does not have access to cluster-scoped artifacts:
    $ kubectl auth can-i create projects --as gatedemo004
    Warning: resource 'projects' is not namespace scoped in group 'project.openshift.io'
    no
    $ kubectl auth can-i create crd --as gatedemo004
    Warning: resource 'customresourcedefinitions' is not namespace scoped in group 'apiextensions.k8s.io'
    no
    $ # gatedemo003 instead has access to cluster-scoped artifacts:
    $ kubectl auth can-i create projects --as gatedemo003
    Warning: resource 'projects' is not namespace scoped in group 'project.openshift.io'
    yes
    $ kubectl auth can-i create crd --as gatedemo003
    Warning: resource 'customresourcedefinitions' is not namespace scoped in group 'apiextensions.k8s.io'
    yes
    $ # gatedemo004 only has access to the gel-viya namespace:
    $ kubectl auth can-i create pods --namespace default --as gatedemo004
    no
    $ kubectl auth can-i create pods --namespace gel-viya --as gatedemo004
    yes
    ```

    As you can read from the output, `gatedemo004` cannot create artifacts outside the gel-viya namespace, while it has that capability in the gel-viya namespace. `gatedemo003`, the cluster administrator, does not have these limitations.

---

## Next Steps

Deployment steps for OpenShift are different from those required for other infrastructures.

Click [here](/04_Deployment/04_023_Prepare_for_OpenShift.md) to move onto the next exercise that describes those differences: ***04 023 Prepare for OpenShift***

---

## Complete Hands-on Navigation Index
<!-- startnav -->
* [01 Workshop Introduction / 01 011 Access the Environment](/01_Workshop_Introduction/01_011_Access_the_Environment.md)
* [01 Workshop Introduction / 01 012 Verify the Environment](/01_Workshop_Introduction/01_012_Verify_the_Environment.md)
* [01 Workshop Introduction / 01 999 Fast track with cheatcodes](/01_Workshop_Introduction/01_999_Fast_track_with_cheatcodes.md)
* [02 OpenShift Introduction / 02 031 Explore OpenShift](/02_OpenShift_Introduction/02_031_Explore_OpenShift.md)
* [04 Deployment / 04 021 Perform the Prerequisites](/04_Deployment/04_021_Perform_the_Prerequisites.md)
* [04 Deployment / 04 022 Prepare for Viya Deployment](/04_Deployment/04_022_Prepare_for_Viya_Deployment.md)**<-- you are here**
* [04 Deployment / 04 023 Prepare for OpenShift](/04_Deployment/04_023_Prepare_for_OpenShift.md)
* [04 Deployment / 04 024 Customize Viya Deployment](/04_Deployment/04_024_Customize_Viya_Deployment.md)
* [04 Deployment / 04 025 Manually Deploy Viya](/04_Deployment/04_025_Manually_Deploy_Viya.md)
* [04 Deployment / 04 999 Cleanup](/04_Deployment/04_999_Cleanup.md)
* [README](/README.md)
<!-- endnav -->
