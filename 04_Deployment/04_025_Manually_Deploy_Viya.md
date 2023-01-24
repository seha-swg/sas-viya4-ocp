![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Deploy SAS Viya 4 in OpenShift

* [Introduction](#introduction)
* [Deploy Viya in the OCP cluster](#deploy-viya-in-the-ocp-cluster)
  * [Build step](#build-step)
  * [Deployment : Apply the Kubernetes manifests](#deployment--apply-the-kubernetes-manifests)
* [Monitor the Viya services startup](#monitor-the-viya-services-startup)
  * [Waiting for the environment to report "ready" state](#waiting-for-the-environment-to-report-ready-state)
  * [Checking if Viya is Ready and Stable with gel_ReadyViya4](#checking-if-viya-is-ready-and-stable-with-gel_readyviya4)
  * [Watching pod status using the "kubectl get pods" command](#watching-pod-status-using-the-kubectl-get-pods-command)
  * [Monitoring the cluster with OpenShift console](#monitoring-the-cluster-with-openshift-console)
* [Validation](#validation)
  * [Connect to your Viya applications](#connect-to-your-viya-applications)
* [Next Steps](#next-steps)
* [Complete Hands-on Navigation Index](#complete-hands-on-navigation-index)

## Introduction

At this point, you have prepared and customized all of the deployment files.
The next step is to perform the SAS Viya deployment.

## Deploy Viya in the OCP cluster

### Build step

1. Generate the Kubernetes manifest files with Kustomize:

    ```bash
    cd ~/project/gelocp
    kustomize build -o site.yaml
    ```

### Deployment : Apply the Kubernetes manifests

Now you can apply the SAS Viya manifest in the OpenShift cluster to deploy and start the SAS Viya containers.

There are 4 groups of resources defined in the site.yaml :

* *cluster-api*: Custom Resource Definitions (Kubernetes API extensions)

    These resources are created at **cluster** level and are shared amongst all Viya namespaces and versions running in the cluster.

    A **cluster administrator** role is required to define these.

* *cluster-wide*: service accounts, roles

    These resources are defined in each **namespace** and only apply to that specific namespace.

    A **cluster administrator** role is required to define these.

* *cluster-local*: rolebindings, config maps, secrets, persistentvolumeclaims, pgcluster custom resource

    These resources are defined in each **namespace** and only apply to that specific namespace.

    A **namespace administrator** role is required to define most of these, but special permissions are required for the rolebindings. For this reason, we'll still use a cluster administrator.

* *namespace*: the rest of the resources

    These resources are defined in each **namespace** and only apply to that specific namespace.

    A **namespace developer** role may be enough to define these.
<!-- still not working
To show that a different K8s permission level is required depending on the type of resources created, we will switch between the cluster administrator and the namespace administrator for the deployment.
--->
1. Submit the following commands - still logged in the cluster as the cluster administrator `gatedemo003`

    ```bash
    cd ~/project/gelocp
    # Verify we are cluster-admins
    oc whoami

    # Apply the "cluster api" configuration in site.yaml
    kubectl apply --selector="sas.com/admin=cluster-api" --server-side --force-conflicts -f site.yaml

    # Wait for Custom Resource Deployment to be deployed
    kubectl wait --for condition=established --timeout=60s -l "sas.com/admin=cluster-api" crd

    # Apply the "cluster wide" configuration in site.yaml
    kubectl apply --selector="sas.com/admin=cluster-wide" -f site.yaml

    #Apply the "cluster local" configuration in site.yaml and delete all the other "cluster local" resources that are not in the file
    kubectl apply --selector="sas.com/admin=cluster-local" -f site.yaml --prune
    ```

    You will probably get multiple warnings, these are expected and are not an issue:

    ```log
    unable to recognize "site.yaml": no matches for kind "OpenDistroCluster" in version "opendistro.sas.com/v1alpha1"
    unable to recognize "site.yaml": no matches for kind "CASDeployment" in version "viya.sas.com/v1alpha1"
    unable to recognize "site.yaml": no matches for kind "Pgcluster" in version "webinfdsvr.sas.com/v1"
    ```
<!-- still not working
1. Switch to the namespace administrator `gatedemo004`

    ```sh
    oc login --namespace gel-viya -u gatedemo004
    ```

    If this is the first time you log in with this account, you should be asked to enter the password - enter `Metadata0`

    ```log
    Authentication required for https://api.rext03-0174.gelenable.sas.com:443 (openshift)
    Username: gatedemo004
    Password:
    Login successful.

    You have one project on this server: "gel-viya"

    Using project "gel-viya".
    ```
-->
1. Submit the following commands to complete SAS Viya deployment

    ```bash
    # check that we are namespace administrators
    oc whoami

    # Apply the configuration in manifest.yaml that matches label "sas.com/admin=namespace" and delete all the other resources that are not in the file and match label "sas.com/admin=namespace".
    kubectl apply --selector="sas.com/admin=namespace" -f site.yaml --prune
    ```

    Doing this will create all required content in kubernetes and start up the process. You may get warnings about deprecated APIs, they are OK to ignore.

* The next time you want to reapply the manifest, you can simply reapply the site.yaml file with the command below (since the components created outside of the namespace scope will already be there)

    ```sh
    cd ~/project/gelocp
    kubectl -n gel-viya apply -f site.yaml
    ```

## Monitor the Viya services startup

* There are several ways to monitor your Viya deployment progress.
* Pick one of the method presented below (sas-readiness, kubectl commands, gel_ReadyViya4, OpenShift Console) - or try them all, each one in a dedicated new MobaXterm connection to sasnode01
* If after **50-70 minutes** your environment is still not ready ... it's time to start debugging.
* You can use commands like "kubectl describe" or "kubectl logs" to troubleshoot your issues.

### Waiting for the environment to report "ready" state

Use either one of the following commands to leverage the sas-readiness pod:

* The following command will only return when the environment is ready (or after 45 minutes):

    ```sh
    time kubectl -n gel-viya wait \
         --for=condition=ready \
         pod \
         --selector='app.kubernetes.io/name=sas-readiness' \
          --timeout=2700s
    ```

* The following command will monitor the log of the readiness pod:

    ```sh
    watch -c -n 20 'kubectl -n gel-viya logs \
         --selector=app.kubernetes.io/name=sas-readiness \
          | tail -n 1 | jq .message'
    ```

    A successful start should eventually show a line like the following:

    ```log
    "All checks passed. Marking as ready. The first recorded failure was 23m20s ago."
    ```

    Hit CTRL+c to exit when done.

### Checking if Viya is Ready and Stable with gel_ReadyViya4

* Some pods may keep restarting for a few times even after being ready, but the sas-readiness service does not report this state.

* In this environment we have deployed a custom tool called [gel_ReadyViya4](https://gelgitlab.race.sas.com/GEL/utilities/gel_ReadyViya4):
    * reads the logs from the Viya readiness POD
    * can detect initial **Readiness**, defined as the first occurrence of the “ready” message in the log.
    * can detect subsequent **Stability**, defined as a consecutive time after initial readiness with no failures in the readiness POD logs
    * For additional info, see <http://sww.sas.com/blogs/wp/gate/48606/using-the-logs-of-the-readiness-service-to-determine-the-state-of-a-viya-4-deployment/sasgnn/2021/11/08>  

* The following command will monitor the log of the readiness pod waiting up to 45 minutes for readiness, then checking the stability for 5 more minutes:

    ```sh
    gel_ReadyViya4 -n gel-viya -r 45 -s 5 2>/dev/null
    ```

    *note: 2>/dev/null is used in this workshop to suppress error messages due to certificate validation errors*

    A successful start should eventually show an output similar to the following:

    ```log
    NOTE: POD labeled sas-readiness in namespace gel-viya is sas-readiness-84d8ddf856-2jpx9
    NOTE: Viya namespace gel-viya is running Stable 2022.09 : 20220927.1664289732021
    NOTE: All checks passed. Marking as ready. The first recorded failure was 23m20s ago.
    NOTE: Readiness detected based on parameters used.
    NOTE: Testing  for 5 consecutive minutes of STABILITY.  Test number 1 of 30
    NOTE: Testing  for 5 consecutive minutes of STABILITY.  Test number 2 of 30
    ...
    ...
    NOTE: Testing  for 5 consecutive minutes of STABILITY.  Test number 30 of 30
    NOTE: All checks passed. Marking as ready. The first recorded failure was 23m20s ago.
    NOTE: namespace gel-viya stable.
    ```

### Watching pod status using the "kubectl get pods" command

You can also use standard kubectl commands to watch the status.

```sh
watch kubectl get pods -n gel-viya -o wide
```

Or, to filter on status:

```sh
watch 'kubectl get pods -n gel-viya -o wide | grep 0/ | grep -v Completed'
```

### Monitoring the cluster with OpenShift console

The OpenShift web console lets you see the nodes, pods, configuration, logs etc... very easily. You can also exec inside pods to debug issues.

Logon to the OpenShift web console with the `gatedemo003` user (If you do not remember the address, there should be a bookmark in Chrome).

When you are in the OpenShift console, it may useful to open the Workloads->Pods page, then filter on the `gel-viya` project

  ![OCPconsoleViyaNamespace](/img/OCP_console_filter_Viya_Namespace.png)

## Validation

### Connect to your Viya applications

* Run the command below to get the SAS Drive url printed in the shell terminal, then you can just click on it (with the CTRL key).

    ```bash
    echo "https://$(oc -n gel-viya get route sas-drive-app-root -o jsonpath="{.spec.host}")/"
    ```

You should use a browser from the Windows client machine in your RACE Collection. If you prefer, you may be able to copy the URL and navigate from your laptop/desktop. If this connection does not work, probably there are network rules preventing it. In this case, simply revert to using the Windows client machine in your RACE Collection.

After the SAS Logon page appears, connect as ```sastest1``` (regular user) or ```sasadm``` (SAS Administrator) (The password for both is "Metadata0").

## Next Steps

For now, this is the end of the workshop. Feel free to experiment using the SAS Viya environment you just installed.

Before leaving, remember to [cleanup](/04_Deployment/04_999_Cleanup.md)!

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
* [04 Deployment / 04 025 Manually Deploy Viya](/04_Deployment/04_025_Manually_Deploy_Viya.md)**<-- you are here**
* [04 Deployment / 04 999 Cleanup](/04_Deployment/04_999_Cleanup.md)
* [README](/README.md)
<!-- endnav -->
