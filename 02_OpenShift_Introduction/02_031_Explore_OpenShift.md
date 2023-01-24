![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Explore your OpenShift Container Platform cluster

* [Introduction](#introduction)
* [Find the address of your OpenShift cluster](#find-the-address-of-your-openshift-cluster)
* [Interact with OCP using the command line](#interact-with-ocp-using-the-command-line)
  * [Logon and set the CLI configuration file for the OCP cluster](#logon-and-set-the-cli-configuration-file-for-the-ocp-cluster)
  * [Familiarize with the CLI](#familiarize-with-the-cli)
* [Interact with OCP using the web console](#interact-with-ocp-using-the-web-console)
  * [Find the address of the web console](#find-the-address-of-the-web-console)
  * [Log into the OCP web console](#log-into-the-ocp-web-console)
* [Next Steps](#next-steps)
* [Complete Hands-on Navigation Index](#complete-hands-on-navigation-index)

## Introduction

In this workshop, we use an OpenShift Container Platform (OCP) cluster, which has been automatically installed on Azure and is dedicated for your use within this workshop.

The objective of this exercise is to learn how to interact with the OCP cluster, both with command-line tools and through the OpenShift web console.

## Find the address of your OpenShift cluster

To connect to your cluster you need the server API address. For this workshop we have configured it to be `https://api.<clientHostname>.gelenable.sas.com:443`. In a customer environment, a cluster administrator should give it to you.

1. Open the connection to sasnode01 in MobaXterm on the Windows client

1. Use the following commands to print the API address of your cluster and store it for later use

    ```bash
    OCP_API_URL="https://api.$(hostname -s).gelenable.sas.com:443"

    echo "API_URL=${OCP_API_URL}" > ~/OCPurls.txt
    cat ~/OCPurls.txt

    # Save the OCP_API_URL info for next time we re-login
    ansible localhost -m lineinfile \
      -a "dest=~/.bashrc \
          regexp='^export OCP_API_URL' \
          line='export OCP_API_URL=$(grep API_URL ~/OCPurls.txt | cut -d= -f2)'" \
          --diff
    ```

1. Verify that there are no firewalls blocking the connection, using the following command

    ```bash
    curl -k ${OCP_API_URL}/version
    ```

    This should be successful and print an output similar to the following:

    ```json
    {
      "major": "1",
      "minor": "23",
      "gitVersion": "v1.23.5+012e945",
      "gitCommit": "3c28e7a79b58e78b4c1dc1ab7e5f6c6c2d3aedd3",
      "gitTreeState": "clean",
      "buildDate": "2022-07-13T08:38:41Z",
      "goVersion": "go1.17.10",
      "compiler": "gc",
      "platform": "linux/amd64"
    }
    ```

## Interact with OCP using the command line

We will first learn how to interact wit the OpenShift cluster using the command-line

### Logon and set the CLI configuration file for the OCP cluster

The OpenShift CLI, `oc`, is a superset of `kubectl`: it supports all kubectl commands and options, plus it offers additional capabilities, specific to OpenShift.

Just as kubectl, to connect to a cluster it needs some configuration parameters, as options on the command-line or, better, in a kubeconfig file.

Just as with other kubernetes flavors, access to the OCP cluster requires proper credentials. For this cluster, we have configured the `gatedemo003` user to have full cluster administration rights.

1. Try anonymous access, to verify that the connection is working, but your access is denied:

    ```sh
    oc --insecure-skip-tls-verify --server $OCP_API_URL whoami
    ```

    You should see something like the following:

    ```log
    [cloud-user@pdcesx03051 ~]$ oc --server $OCP_API_URL --insecure-skip-tls-verify whoami
    Error from server (Forbidden): users.user.openshift.io "~" is forbidden: User "system:anonymous" cannot get resource "users" in API group "user.openshift.io" at the cluster scope
    ```

1. Use the CLI to logon as `gatedemo003` with password `Metadata0`. This will create a valid kubeconfig file that will be used for any subsequent access to the cluster. At a customer site, a cluster administrator may provide you the required connection details, or, directly, a client kubeconfig already configured for use.

    ```sh
    oc login --server $OCP_API_URL -u gatedemo003
    ```

    You should be asked to confirm it's OK to use an unknown certificate output - enter `y`. Then the cli should ask to enter the password - enter `Metadata0`

    ```log
    [cloud-user@pdcesx03051 ~]$ $ oc login --server $OCP_API_URL -u gatedemo003
    The server uses a certificate signed by an unknown authority.
    You can bypass the certificate check, but any data you send to the server could be intercepted by others.
    Use insecure connections? (y/n): y

    Authentication required for https://api.pdcesx03051.gelenable.sas.com:443 (openshift)
    Username: gatedemo003
    Password:
    Login successful.

    You have access to 65 projects, the list has been suppressed. You can list all projects with 'oc projects'

    Using project "default".
    Welcome! See 'oc help' to get started.
    ```

1. Have a look at the kubeconfig that has been automatically created and verify that it is valid also for the regular `kubectl` cli:

    ```sh
    oc config view
    kubectl get ns
    ```

    You should see something like the following:

    ```log
    [cloud-user@pdcesx03051 ~]$ oc config view
    apiVersion: v1
    clusters:
    - cluster:
        insecure-skip-tls-verify: true
        server: https://api.pdcesx03051.gelenable.sas.com:443
    name: api-pdcesx03051-gelenable-sas-com:443
    contexts:
    - context:
        cluster: api-pdcesx03051-gelenable-sas-com:443
        namespace: default
        user: gatedemo003/api-pdcesx03051-gelenable-sas-com:443
    name: default/api-pdcesx03051-gelenable-sas-com:443/gatedemo003
    current-context: default/api-pdcesx03051-gelenable-sas-com:443/gatedemo003
    kind: Config
    preferences: {}
    users:
    - name: gatedemo003/api-pdcesx03051-gelenable-sas-com:443
    user:
        token: REDACTED
    [cloud-user@pdcesx03051 ~]$ kubectl get ns
    NAME                                               STATUS   AGE
    default                                            Active   3h17m
    kube-node-lease                                    Active   3h17m
    kube-public                                        Active   3h17m
    kube-system                                        Active   3h17m
    openshift                                          Active   3h8m
    openshift-apiserver                                Active   3h11m
    openshift-apiserver-operator                       Active   3h16m
    openshift-authentication                           Active   3h11m
    openshift-authentication-operator                  Active   3h16m
    openshift-cloud-controller-manager                 Active   3h16m
    openshift-cloud-controller-manager-operator        Active   3h16m
    openshift-cloud-credential-operator                Active   3h16m
    openshift-cloud-network-config-controller          Active   3h16m
    openshift-cluster-csi-drivers                      Active   3h16m
    openshift-cluster-machine-approver                 Active   3h16m
    openshift-cluster-node-tuning-operator             Active   3h16m
    openshift-cluster-samples-operator                 Active   3h16m
    openshift-cluster-storage-operator                 Active   3h16m
    openshift-cluster-version                          Active   3h17m
    openshift-config                                   Active   3h16m
    openshift-config-managed                           Active   3h16m
    openshift-config-operator                          Active   3h16m
    openshift-console                                  Active   3h2m
    openshift-console-operator                         Active   3h2m
    openshift-console-user-settings                    Active   3h2m
    openshift-controller-manager                       Active   3h11m
    openshift-controller-manager-operator              Active   3h16m
    openshift-dns                                      Active   3h10m
    openshift-dns-operator                             Active   3h16m
    openshift-etcd                                     Active   3h17m
    openshift-etcd-operator                            Active   3h16m
    openshift-host-network                             Active   3h14m
    openshift-image-registry                           Active   3h16m
    openshift-infra                                    Active   3h17m
    openshift-ingress                                  Active   3h10m
    openshift-ingress-canary                           Active   3h5m
    openshift-ingress-operator                         Active   3h16m
    openshift-insights                                 Active   3h16m
    openshift-kni-infra                                Active   3h16m
    openshift-kube-apiserver                           Active   3h17m
    openshift-kube-apiserver-operator                  Active   3h17m
    openshift-kube-controller-manager                  Active   3h17m
    openshift-kube-controller-manager-operator         Active   3h17m
    openshift-kube-scheduler                           Active   3h17m
    openshift-kube-scheduler-operator                  Active   3h16m
    openshift-kube-storage-version-migrator            Active   3h11m
    openshift-kube-storage-version-migrator-operator   Active   3h16m
    openshift-machine-api                              Active   3h16m
    openshift-machine-config-operator                  Active   3h16m
    openshift-marketplace                              Active   3h16m
    openshift-monitoring                               Active   3h16m
    openshift-multus                                   Active   3h14m
    openshift-network-diagnostics                      Active   3h14m
    openshift-network-operator                         Active   3h16m
    openshift-node                                     Active   3h8m
    openshift-oauth-apiserver                          Active   3h11m
    openshift-openstack-infra                          Active   3h16m
    openshift-operator-lifecycle-manager               Active   3h16m
    openshift-operators                                Active   3h16m
    openshift-ovirt-infra                              Active   3h16m
    openshift-ovn-kubernetes                           Active   3h14m
    openshift-service-ca                               Active   3h11m
    openshift-service-ca-operator                      Active   3h16m
    openshift-user-workload-monitoring                 Active   3h16m
    openshift-vsphere-infra                            Active   3h16m
    ```

    If you look at the namespaces in the cluster (`kubectl get ns`) you should see all of the system ones: this is only possible because we are using an administrative identity as cluster administrators.

    > Some people prefer interacting with Kubernetes clusters with applications such as [Lens](https://k8slens.dev/). Although Lens is not used in this workshop, if you want to use it you can download and install the latest version of Lens on the RACE client machine. If you have it already installed on your desktop, and if you are VPN'ed directly to SAS Cary Headquarters, that will work too. In both cases, you can use this same kubeconfig to connect Lens to this OpenShift Cluster. It is saved in the default location: `~/.kube/config`

<!--
Auto-logon for the cheatcodes
```bash
# when running with autodeploy, it takes up to 5 minutes for the OCP OAuth pods to accept LDAP logins
timeout 900s bash -c "\
  until \
    oc login --insecure-skip-tls-verify --server $OCP_API_URL -u gatedemo003 -p Metadata0 ;\
  do sleep 60; done"
```
-->

### Familiarize with the CLI

Now we will run some `oc` commands to familiarize with the environment and with the CLI, while checking the cluster. Remember, with most of the commands, you could use `kubectl` as well!

1. Check some connection details

    ```sh
    oc whoami
    oc whoami --show-server
    oc whoami --show-console
    ```

    You should see output similar to the following:

    ```log
    [cloud-user@pdcesx03051 ~]$ oc whoami
    gatedemo003
    [cloud-user@pdcesx03051 ~]$ oc whoami --show-server
    https://api.pdcesx03051.gelenable.sas.com:443
    [cloud-user@pdcesx03051 ~]$ oc whoami --show-console
    https://console-openshift-console.apps.pdcesx03051.gelenable.sas.com
    ```

1. Verify that all cluster nodes are ready:

    ```sh
    oc get nodes
    ```

    You should see output similar to the following:

    ```log
    NAME                            STATUS   ROLES    AGE   VERSION
    sasdemo-p03051-controlplane-0   Ready    master   50m   v1.23.5+012e945
    sasdemo-p03051-controlplane-1   Ready    master   50m   v1.23.5+012e945
    sasdemo-p03051-controlplane-2   Ready    master   50m   v1.23.5+012e945
    sasdemo-p03051-worker-1         Ready    worker   47m   v1.23.5+012e945
    sasdemo-p03051-worker-2         Ready    worker   47m   v1.23.5+012e945
    sasdemo-p03051-worker-3         Ready    worker   47m   v1.23.5+012e945
    sasdemo-p03051-worker-4         Ready    worker   47m   v1.23.5+012e945
    sasdemo-p03051-worker-5         Ready    worker   47m   v1.23.5+012e945
    ```

## Interact with OCP using the web console

Red Hat OpenShift Container Platform includes a web console that provides a graphical user interface to visualize and interact with your projects and perform administrative, management, and troubleshooting tasks. You see the nodes, pods, configuration, logs etc... very easily. You can also exec inside pods to debug issues.

The web console runs as pods on the control plane nodes in the openshift-console project.

### Find the address of the web console

You may have noticed that we already printed the address of the web console with one the previous `oc` commands.

1. Use the following commands to print it again  and store it for later use

    ```bash
    OCP_CONSOLE_URL=$(oc whoami --show-console)

    echo "OCP_CONSOLE_URL=${OCP_CONSOLE_URL}" >> ~/OCPurls.txt
    cat ~/OCPurls.txt

    # Save the OCP_API_URL info for next time we re-login
    ansible localhost -m lineinfile \
      -a "dest=~/.bashrc \
          regexp='^export OCP_CONSOLE_URL' \
          line='export OCP_CONSOLE_URL=${OCP_CONSOLE_URL}'" \
          --diff
    ```

### Log into the OCP web console

You can access the web console in two ways:

- CRTL+click on the console URL printed in the terminal.
- Select the *Red Hat OpenShift console* bookmark in Chrome.

On the log in page, select the gelenable-adds option, then log in with the same administrative account that we already used with the CLI: `gatedemo003` with password `Metadata0`

![](/img/OCPConsoleLogin.png)

You should be greeted by the Overview Home page

![](/img/OCPConsoleHome.png)

Spend a few minutes browsing around the pages in the left pane to familiarize with the console.

The topmost drop down lets you switch between the **Administrator** and the **Developer** perspectives:

![](/img/OCPConsolePerspectives.png)

For the sake of SAS Viya administration, we will only work in the Administrator perspective. The Developer one is mostly tailored to developers that deploy custom-made applications.

For additional information about the OCP web console, refer to Red Hat official documentation at <https://access.redhat.com/documentation/en-us/openshift_container_platform/4.10/html/web_console>

---

## Next Steps

**Congratulations ! You should now be connected to a running OCP cluster.** :-)

Now that you can use the OCP cluster, the next exercise will perform the required prerequisites for Viya deployment.

Click [here](/04_Deployment/04_021_Perform_the_Prerequisites.md) to move onto the next exercise: ***04 021 Perform the Prerequisites***

---

## Complete Hands-on Navigation Index

<!-- startnav -->
* [01 Workshop Introduction / 01 011 Access the Environment](/01_Workshop_Introduction/01_011_Access_the_Environment.md)
* [01 Workshop Introduction / 01 012 Verify the Environment](/01_Workshop_Introduction/01_012_Verify_the_Environment.md)
* [01 Workshop Introduction / 01 999 Fast track with cheatcodes](/01_Workshop_Introduction/01_999_Fast_track_with_cheatcodes.md)
* [02 OpenShift Introduction / 02 031 Explore OpenShift](/02_OpenShift_Introduction/02_031_Explore_OpenShift.md)**<-- you are here**
* [04 Deployment / 04 021 Perform the Prerequisites](/04_Deployment/04_021_Perform_the_Prerequisites.md)
* [04 Deployment / 04 022 Prepare for Viya Deployment](/04_Deployment/04_022_Prepare_for_Viya_Deployment.md)
* [04 Deployment / 04 023 Prepare for OpenShift](/04_Deployment/04_023_Prepare_for_OpenShift.md)
* [04 Deployment / 04 024 Customize Viya Deployment](/04_Deployment/04_024_Customize_Viya_Deployment.md)
* [04 Deployment / 04 025 Manually Deploy Viya](/04_Deployment/04_025_Manually_Deploy_Viya.md)
* [04 Deployment / 04 999 Cleanup](/04_Deployment/04_999_Cleanup.md)
* [README](/README.md)
<!-- endnav -->
