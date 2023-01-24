![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Prepare the cluster for SAS Viya

* [Introduction](#introduction)
* [Verify](#verify)
  * [Verify the cluster release](#verify-the-cluster-release)
  * [Verify that the cluster has the correct storage](#verify-that-the-cluster-has-the-correct-storage)
  * [Verify the cluster Ingress](#verify-the-cluster-ingress)
* [Deploy required software components](#deploy-required-software-components)
  * [Deploy the cert-utils operator](#deploy-the-cert-utils-operator)
* [Next Steps](#next-steps)
* [Complete Hands-on Navigation Index](#complete-hands-on-navigation-index)

## Introduction

At this point you should have completed the steps to connect to the OCP cluster - otherwise, [go back](/02_OpenShift_Introduction/02_031_Explore_OpenShift.md) to the previous exercise.

The objective of this exercise is to go through the pre-requites that need to be implemented before you can deploy SAS Viya in your cluster. Some are required by SAS Viya in every environment, while others are specific to OCP.

&#128073; At customer sites, most of these pre-requisites should be fulfilled by the customer's IT team.

## Verify

### Verify the cluster release

As of August 2022, the current SAS Viya release supports OCP versions 4.8 to 4.10, which include Kubernetes 1.21 to 1.23

1. Verify the cluster release with the following command:

    ```bash
    oc version
    ```

    You should expect to see output similar to below:

    ```log
    Client Version: 4.10.25
    Server Version: 4.10.25
    Kubernetes Version: v1.23.5+012e945
    ```

> Remember that, for generic Kubernetes commands, `kubectl` and `oc` are equivalent.

### Verify that the cluster has the correct storage

Some SAS Viya components require RWX storage (i.e., Kubernetes volumes that can be mounted in Read/Write by multiple nodes), while others require RWO storage (i.e., Kubernetes volumes that can be mounted in Read/Write by a single node)

1. Run the following command to list the Storage Classes defined in the cluster.

    ```bash
    # Get the StorageClass information
    oc get sc
    ```

    You should see output similar to the following:

    ```log
    NAME                        PROVISIONER                RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
    managed-csi                 disk.csi.azure.com         Delete          WaitForFirstConsumer   true                   89m
    managed-premium (default)   kubernetes.io/azure-disk   Delete          WaitForFirstConsumer   true                   89m
    sas-azurefile               kubernetes.io/azure-file   Delete          Immediate              true                   64m
    ```

1. Explore the sas-azurefile storage class with the following command

    ```sh
    oc describe sc sas-azurefile
    ```

    You should see output similar to the following:

    ```log
    Name:            sas-azurefile
    IsDefaultClass:  No
    Annotations:     kubectl.kubernetes.io/last-applied-configuration={"allowVolumeExpansion":true,"apiVersion":"storage.k8s.io/v1","kind":"StorageClass","metadata":{"annotations":{},"name":"sas-azurefile"},"mountOptions":["dir_mode=0777","file_mode=0777","uid=1001","gid=1001"],"parameters":{"storageAccount":"rext030174sa"},"provisioner":"kubernetes.io/azure-file"}

    Provisioner:           kubernetes.io/azure-file
    Parameters:            storageAccount=pdcesx03051sa
    AllowVolumeExpansion:  True
    MountOptions:
    dir_mode=0777
    file_mode=0777
    uid=1001
    gid=1001
    ReclaimPolicy:      Delete
    VolumeBindingMode:  Immediate
    Events:             <none>
    ```

    The *sas-azurefile* StorageClass has been defined for SAS Viya usage for this specific workshop. At customer sites, verify that the cluster supports both kinds of storage.

### Verify the cluster Ingress

Only the OpenShift Ingress Operator is supported.

1. Confirm the Ingress router has created a load balancer and populated the EXTERNAL-IP field:

    ```bash
    oc -n openshift-ingress get service router-default
    ```

    You should see output similar to the following:

    ```log
    NAME             TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
    router-default   LoadBalancer   172.30.176.226   20.75.62.14   80:31292/TCP,443:32064/TCP   43m
    ```

## Deploy required software components

### Deploy the cert-utils operator

This operator from Red Hat is required on OCP to manage certificates for TLS support and create keystores. For more information, see https://github.com/redhat-cop/cert-utils-operator/blob/master/README.md.

1. Create a new OCP project (i.e. a Kubernetes namespace) to host the cert-utils artifacts

    ```bash
    oc new-project cert-utils-operator
    ```

    You should see output similar to the following:

    ```log
    $ oc new-project cert-utils-operator
    Now using project "cert-utils-operator" on server "https://api.pdcesx03051.gelenable.sas.com:443".

    You can add applications to this project with the 'new-app' command. For example, try:

        oc new-app rails-postgresql-example

    to build a new example application in Ruby. Or use kubectl to deploy a simple Kubernetes application:

        kubectl create deployment hello-node --image=k8s.gcr.io/serve_hostname
    ```

1. The preferred way to install operators in OCP is using the OperatorHub from the web console. Log into the OpenShift web console as the gatedemo003 user to install the cert-utils-operator.

1. Open the Operators menu, select the OperatorHub page, enter `cert-utils` in the filter, and click on the resulting box.

    ![](/img/OperatorHub_CertUtils.png)

1. Acknowledge the warning about community support, then select the *Install* button:

    ![](/img/CertUtilsInstall.png)

1. Accept all defaults. Verify that the `cert-utils-operator` project that we created is recognized and selected, then click on *Install*.

    ![](/img/CertUtilsInstall2.png)

1. The installation will start; it may take up to 5 minutes to complete. At the end you should get a green checkmark; select *View Operator* to verify it is actually running.

    ![](/img/CertUtilsInstall3.png)

<!--
Scripted install for cheatcodes
See https://github.com/redhat-cop/cert-utils-operator#deploying-from-operatorhub-using-cli
```bash
oc apply -f https://raw.githubusercontent.com/redhat-cop/cert-utils-operator/master/config/operatorhub/operator.yaml -n cert-utils-operator
## wait until pods start
sleep 30
oc -n cert-utils-operator wait --for=condition=ready pod -l=control-plane=cert-utils-operator --timeout=300s
```
-->

---

## Next Steps

Before digging into Viya deployment, we have to retrieve the deployment assets.

Click [here](/04_Deployment/04_022_Prepare_for_Viya_Deployment.md) to move onto the next exercise: ***4 022 Prepare for Viya Deployment***

---

## Complete Hands-on Navigation Index
<!-- startnav -->
* [01 Workshop Introduction / 01 011 Access the Environment](/01_Workshop_Introduction/01_011_Access_the_Environment.md)
* [01 Workshop Introduction / 01 012 Verify the Environment](/01_Workshop_Introduction/01_012_Verify_the_Environment.md)
* [01 Workshop Introduction / 01 999 Fast track with cheatcodes](/01_Workshop_Introduction/01_999_Fast_track_with_cheatcodes.md)
* [02 OpenShift Introduction / 02 031 Explore OpenShift](/02_OpenShift_Introduction/02_031_Explore_OpenShift.md)
* [04 Deployment / 04 021 Perform the Prerequisites](/04_Deployment/04_021_Perform_the_Prerequisites.md)**<-- you are here**
* [04 Deployment / 04 022 Prepare for Viya Deployment](/04_Deployment/04_022_Prepare_for_Viya_Deployment.md)
* [04 Deployment / 04 023 Prepare for OpenShift](/04_Deployment/04_023_Prepare_for_OpenShift.md)
* [04 Deployment / 04 024 Customize Viya Deployment](/04_Deployment/04_024_Customize_Viya_Deployment.md)
* [04 Deployment / 04 025 Manually Deploy Viya](/04_Deployment/04_025_Manually_Deploy_Viya.md)
* [04 Deployment / 04 999 Cleanup](/04_Deployment/04_999_Cleanup.md)
* [README](/README.md)
<!-- endnav -->
