![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Preparing for OpenShift

* [Introduction](#introduction)
* [Workload Node Placement Considerations](#workload-node-placement-considerations)
* [Security Context Constraints and Service Accounts](#security-context-constraints-and-service-accounts)
  * [1. Define the custom SCCs](#1-define-the-custom-sccs)
  * [2. Assign the custom SCCs to Service Accounts](#2-assign-the-custom-sccs-to-service-accounts)
* [Additional Security Considerations](#additional-security-considerations)
  * [SCCs and file system permissions](#sccs-and-file-system-permissions)
  * [Remove Secure Computing Mode (seccomp) settings](#remove-secure-computing-mode-seccomp-settings)
* [Modifications to the kustomization.yaml file](#modifications-to-the-kustomizationyaml-file)
* [Next Steps](#next-steps)
* [Complete Hands-on Navigation Index](#complete-hands-on-navigation-index)

## Introduction

Some deployment steps for OpenShift are different from those required for other infrastructures. This section describes those differences.

## Workload Node Placement Considerations

OpenShift clusters are often homogenous, because all worker nodes have the same HW specification. It is not common to create nodepools dedicated to specific classes of software.

For this reason, it is recommended to disable the CAS autoresource capability when deploying the software, and manually set resource limits for CAS.

It is still recommended to label one or more nodes (or even all, if desired) for the SAS Compute workload, to enable the pre-pull job to download the images on the node(s).

If you decide to taint nodes, remember to leave some nodes untainted (by default at least 2 nodes). This is to allow the scheduling of non-SAS Viya pods, such as the default ingress controller.

1. For this workshop, we will label worker nodes 1 and 2 for compute. Let's start by checking the existing settings:

    ```bash
    # check the current labels and taints:
    kubectl get nodes -o=custom-columns=NAME:.metadata.name,LABELS:.metadata.labels
    kubectl get nodes -o=custom-columns=NAME:.metadata.name,TAINTS:.spec.taints
    ```

    Result of running code above will look similar to this:

    ```log
    $ kubectl get nodes -o=custom-columns=NAME:.metadata.name,LABELS:.metadata.labels
    sasdemo-p03051-controlplane-0   map[beta.kubernetes.io/arch:amd64 beta.kubernetes.io/instance-type:Standard_D4ds_v4 beta.kubernetes.io/os:linux failure-domain.beta.kubernetes.io/region:eastus2 failure-domain.beta.kubernetes.io/zone:0 kubernetes.io/arch:amd64 kubernetes.io/hostname:sasdemo-p03051-controlplane-0 kubernetes.io/os:linux node-role.kubernetes.io/master: node.kubernetes.io/instance-type:Standard_D4ds_v4 node.openshift.io/os_id:rhcos topology.kubernetes.io/region:eastus2 topology.kubernetes.io/zone:0]
    sasdemo-p03051-controlplane-1   map[beta.kubernetes.io/arch:amd64 beta.kubernetes.io/instance-type:Standard_D4ds_v4 beta.kubernetes.io/os:linux failure-domain.beta.kubernetes.io/region:eastus2 failure-domain.beta.kubernetes.io/zone:0 kubernetes.io/arch:amd64 kubernetes.io/hostname:sasdemo-p03051-controlplane-1 kubernetes.io/os:linux node-role.kubernetes.io/master: node.kubernetes.io/instance-type:Standard_D4ds_v4 node.openshift.io/os_id:rhcos topology.kubernetes.io/region:eastus2 topology.kubernetes.io/zone:0]
    sasdemo-p03051-controlplane-2   map[beta.kubernetes.io/arch:amd64 beta.kubernetes.io/instance-type:Standard_D4ds_v4 beta.kubernetes.io/os:linux failure-domain.beta.kubernetes.io/region:eastus2 failure-domain.beta.kubernetes.io/zone:0 kubernetes.io/arch:amd64 kubernetes.io/hostname:sasdemo-p03051-controlplane-2 kubernetes.io/os:linux node-role.kubernetes.io/master: node.kubernetes.io/instance-type:Standard_D4ds_v4 node.openshift.io/os_id:rhcos topology.kubernetes.io/region:eastus2 topology.kubernetes.io/zone:0]
    sasdemo-p03051-worker-1         map[beta.kubernetes.io/arch:amd64 beta.kubernetes.io/instance-type:Standard_D8ds_v4 beta.kubernetes.io/os:linux failure-domain.beta.kubernetes.io/region:eastus2 failure-domain.beta.kubernetes.io/zone:0 kubernetes.io/arch:amd64 kubernetes.io/hostname:sasdemo-p03051-worker-1 kubernetes.io/os:linux node-role.kubernetes.io/worker: node.kubernetes.io/instance-type:Standard_D8ds_v4 node.openshift.io/os_id:rhcos topology.kubernetes.io/region:eastus2 topology.kubernetes.io/zone:0]
    sasdemo-p03051-worker-2         map[beta.kubernetes.io/arch:amd64 beta.kubernetes.io/instance-type:Standard_D8ds_v4 beta.kubernetes.io/os:linux failure-domain.beta.kubernetes.io/region:eastus2 failure-domain.beta.kubernetes.io/zone:0 kubernetes.io/arch:amd64 kubernetes.io/hostname:sasdemo-p03051-worker-2 kubernetes.io/os:linux node-role.kubernetes.io/worker: node.kubernetes.io/instance-type:Standard_D8ds_v4 node.openshift.io/os_id:rhcos topology.kubernetes.io/region:eastus2 topology.kubernetes.io/zone:0]
    sasdemo-p03051-worker-3         map[beta.kubernetes.io/arch:amd64 beta.kubernetes.io/instance-type:Standard_D8ds_v4 beta.kubernetes.io/os:linux failure-domain.beta.kubernetes.io/region:eastus2 failure-domain.beta.kubernetes.io/zone:0 kubernetes.io/arch:amd64 kubernetes.io/hostname:sasdemo-p03051-worker-3 kubernetes.io/os:linux node-role.kubernetes.io/worker: node.kubernetes.io/instance-type:Standard_D8ds_v4 node.openshift.io/os_id:rhcos topology.kubernetes.io/region:eastus2 topology.kubernetes.io/zone:0]
    sasdemo-p03051-worker-4         map[beta.kubernetes.io/arch:amd64 beta.kubernetes.io/instance-type:Standard_D8ds_v4 beta.kubernetes.io/os:linux failure-domain.beta.kubernetes.io/region:eastus2 failure-domain.beta.kubernetes.io/zone:0 kubernetes.io/arch:amd64 kubernetes.io/hostname:sasdemo-p03051-worker-4 kubernetes.io/os:linux node-role.kubernetes.io/worker: node.kubernetes.io/instance-type:Standard_D8ds_v4 node.openshift.io/os_id:rhcos topology.kubernetes.io/region:eastus2 topology.kubernetes.io/zone:0]
    sasdemo-p03051-worker-5         map[beta.kubernetes.io/arch:amd64 beta.kubernetes.io/instance-type:Standard_D8ds_v4 beta.kubernetes.io/os:linux failure-domain.beta.kubernetes.io/region:eastus2 failure-domain.beta.kubernetes.io/zone:0 kubernetes.io/arch:amd64 kubernetes.io/hostname:sasdemo-p03051-worker-5 kubernetes.io/os:linux node-role.kubernetes.io/worker: node.kubernetes.io/instance-type:Standard_D8ds_v4 node.openshift.io/os_id:rhcos topology.kubernetes.io/region:eastus2 topology.kubernetes.io/zone:0]
    $ kubectl get nodes -o=custom-columns=NAME:.metadata.name,TAINTS:.spec.taints
    NAME                            TAINTS
    sasdemo-p03051-controlplane-0   [map[effect:NoSchedule key:node-role.kubernetes.io/master]]
    sasdemo-p03051-controlplane-1   [map[effect:NoSchedule key:node-role.kubernetes.io/master]]
    sasdemo-p03051-controlplane-2   [map[effect:NoSchedule key:node-role.kubernetes.io/master]]
    sasdemo-p03051-worker-1         <none>
    sasdemo-p03051-worker-2         <none>
    sasdemo-p03051-worker-3         <none>
    sasdemo-p03051-worker-4         <none>
    sasdemo-p03051-worker-5         <none>
    ```

1. Now apply the label `workload.sas.com/class=compute`

    ```bash
    kubectl label nodes $(kubectl get nodes | grep worker-[1,2] | awk '{print $1}' | tr '\n' ' ') workload.sas.com/class=compute
    ```

    Result of running code above will look similar to this:

    ```log
    $ kubectl label nodes $(kubectl get nodes | grep worker-[1,2] | awk '{print $1}' | tr '\n' ' ') workload.sas.com/class=compute
    node/sasdemo-p03051-worker-1 labeled
    node/sasdemo-p03051-worker-2 labeled
    ```

## Security Context Constraints and Service Accounts

A deployment in OpenShift requires multiple custom security context constraints (SCCs) to provide permissions to SAS Viya services. SCCs are required in order to enable the Pods to run.

The full list of required SCCs is variable and depends on the products within your SAS Viya order.

The files used to define these SCCs and assign them to the Service Accounts used by Viya pods are available under the \<deploy\>/sas-bases directory tree.

The process consists of 2 steps:

1. Define the custom SCCs required by Viya by applying the provided yaml files.
1. Bind each SCC to the Service Account (SA) used by the pod the needs it.

Both steps require elevated privileges and should be performed by a cluster administrator (in our env, gatedemo003)

### 1. Define the custom SCCs

1. As a quick way to find the manifest files, submit the following command:

    ```bash
    cd ~/project/gelocp
    find ./sas-bases -name "*scc*.yaml"
    ```

    You should get the following list:

    ```log
    $ find ./sas-bases -name "*scc*.yaml"
    ./sas-bases/examples/cas/configure/cas-server-scc-host-launch.yaml
    ./sas-bases/examples/cas/configure/cas-server-scc-sssd.yaml
    ./sas-bases/examples/cas/configure/cas-server-scc.yaml
    ./sas-bases/examples/configure-elasticsearch/internal/openshift/sas-opendistro-scc.yaml
    ./sas-bases/examples/crunchydata/openshift/pgo-backrest-scc.yaml
    ./sas-bases/examples/crunchydata/openshift/pgo-scc.yaml
    ./sas-bases/examples/sas-connect-spawner/openshift/sas-connect-spawner-scc.yaml
    ./sas-bases/examples/sas-programming-environment/watchdog/sas-watchdog-scc.yaml
    ./sas-bases/overlays/migration/openshift/migration-job-scc.yaml
    ./sas-bases/overlays/sas-microanalytic-score/service-account/sas-microanalytic-score-scc.yaml
    ```

* You should review the README files that accompany each SCC because some SCCs have some additional configuration settings (i.e. OpenSearch), or are only required in specific cases (.i.e CAS or Migration)
* The SAS/CONNECT SCC is not required anymore if you accept the default configuration. The `sas-connect-spawner-scc.yaml` file is still provided in case you decide to revert to the legacy SAS/CONNECT behavior (see the readme for further details).
* OpenSearch requires changes to a few kernel settings (this is true for every deployment, it is not specific to OCP). SAS provides the `sysctl-transformer.yaml` file to apply the necessary sysctl parameters to configure the kernel, but this requires special privileges that are denied by default by OCP. Therefore, before you apply the `sas-opendistro-scc.yaml` file, you must modify it to enable these privileges.

    > At customer sites, the OpenShift administrator may prefer to use the OpenShift Machine Config Operator to apply the required sysctl changes. In that case, no modification to the default sas-opendistro-scc.yaml is required.

1. Use the following command to apply the required changes to `sas-opendistro-scc.yaml`:

    ```bash
    yq4 eval '
        .allowPrivilegeEscalation = true,
        .allowPrivilegedContainer = true,
        .runAsUser.type = "RunAsAny"' \
        ./sas-bases/examples/configure-elasticsearch/internal/openshift/sas-opendistro-scc.yaml > ./site-config/sas-opendistro-scc.yaml
    ```

1. Finally, apply all the required SCC definition files (**This step requires full cluster admin privileges**):

    ```bash
    # verify we are logged in as the gatedemo003 cluster administrator
    oc whoami
    # CAS: pick only one of cas-server-scc.yaml or cas-server-scc-host-launch.yaml
    oc apply -f ./sas-bases/examples/cas/configure/cas-server-scc.yaml
    # PostgreSQL
    oc apply -f ./sas-bases/examples/crunchydata/openshift/pgo-backrest-scc.yaml
    oc apply -f ./sas-bases/examples/crunchydata/openshift/pgo-scc.yaml
    # SAS/CONNECT is not required anymore by default
    #oc apply -f ./sas-bases/examples/sas-connect-spawner/openshift/sas-connect-spawner-scc.yaml
    # SPRE
    oc apply -f ./sas-bases/examples/sas-programming-environment/watchdog/sas-watchdog-scc.yaml
    # MAS
    oc apply -f ./sas-bases/overlays/sas-microanalytic-score/service-account/sas-microanalytic-score-scc.yaml
    # OpenSearch
    oc apply -f ./site-config/sas-opendistro-scc.yaml
    ```

    You should get a confirmation message for each SCCs file applied.

### 2. Assign the custom SCCs to Service Accounts

At this point, nothing has been deployed yet. Therefore, you don’t have any Service Accounts in your OpenShift project. This fact doesn’t matter; you can apply those SCCs to non-existing Service Accounts, and the Service Accounts will adopt the SCCs when they are created.

1. Bind the SCC you just defined to the appropriate Service Account (**This step requires full cluster admin privileges**):

    ```bash
    cd ~/project/gelocp/
    NS="gel-viya"
    oc -n ${NS} adm policy add-scc-to-user sas-cas-server -z sas-cas-server
    #oc -n ${NS} adm policy add-scc-to-user sas-connect-spawner -z sas-connect-spawner
    oc -n ${NS} adm policy add-scc-to-user pgo -z pgo-pg
    oc -n ${NS} adm policy add-scc-to-user pgo -z pgo-target
    oc -n ${NS} adm policy add-scc-to-user pgo-backrest -z pgo-default
    oc -n ${NS} adm policy add-scc-to-user pgo-backrest -z pgo-backrest
    oc -n ${NS} adm policy add-scc-to-user sas-opendistro -z sas-opendistro
    oc -n ${NS} adm policy add-scc-to-user sas-microanalytic-score -z sas-microanalytic-score
    oc -n ${NS} adm policy add-scc-to-user sas-watchdog -z sas-programming-environment
    oc -n ${NS} adm policy add-scc-to-user hostmount-anyuid -z sas-programming-environment
    ```

    You should get a confirmation message for each SCCs bound.

## Additional Security Considerations

There are some additional security requirements that are unique to OpenShift and that you must implement:

1. the updating of the `fsGroup` field
1. the removal of the Secure Computing (`seccomp`) profile

### SCCs and file system permissions

SAS Viya includes default `fsGroup` settings that enable file system access. When an fsGroup ID is set for a Pod, any files that are written to a volume within that Pod inherit that fsGroup as their group ID (GID). The fsGroup ID is the owner of the volume and of any files in that volume.

By default, most SAS Viya pods are set to use an fsGroup value=1001

In OpenShift, every project is assigned a dynamically allocated range of IDs, which are used to prevent collisions between each project.

By default, in OpenShift, most pods use a _restricted_ SCC that prohibits using any group ID not included in that range. For this reason, these SAS Viya pods in OpenShift cannot use the 1001 group ID.

SAS provides the `update-fsgroup.yaml` file to help you update the fsGroup in targeted manifests with the correct GID value.

1. Run the following code to find a valid group ID for your environment:

    ```bash
    cd ~/project/gelocp/
    NS="gel-viya"
    # get the ID from OpenShift
    NS_GROUP_ID=$(oc get project ${NS} -o jsonpath='{.metadata.annotations.openshift\.io/sa\.scc\.supplemental-groups}' | cut -f1 -d / )
    echo "The supplemental group ID for the ${NS} namespace is: ${NS_GROUP_ID}"
    ```

1. Use the following command to insert the group ID value that you just found into `update-fsgroup.yaml` and place the resulting file in the proper site-config subdirectory:

    ```bash
    sed -e "s|{{ FSGROUP_VALUE }}|${NS_GROUP_ID}|g" \
        ./sas-bases/examples/security/container-security/update-fsgroup.yaml > ./site-config/security/update-fsgroup.yaml
    ```

### Remove Secure Computing Mode (seccomp) settings

Secure computing mode (seccomp) is a security facility that restricts the actions that are available within a container.

SAS Viya pods, by default, get created with a seccomp profile.

By default, in OpenShift, most pods use a _restricted_ SCC that prohibits specifying a seccomp profile. They must use the default seccomp profile defined by the cri-o runtime.

For this reason, when deploying in OpenShift, you must remove those SAS Viya default seccomp setting by including `sas-bases/overlays/security/container-security/remove-seccomp-transformer.yaml` in your kustomization.yaml file:

```yaml
transformers:
  - sas-bases/overlays/security/container-security/remove-seccomp-transformer.yaml
  ... more transformers block lines ...
```

You will do this when you will create your kustomization.yaml file in the next exercise.

## Modifications to the kustomization.yaml file

OpenShift uses _routes_ for its ingress controllers to expose services within the cluster to the outside world. The initial kustomization.yaml file that is described in the official documentation does not account for routes, so you must change a couple of lines.

1. The first change is required to create routes rather than Ingress resources:

    * From

       ```yaml
       resources:
       - sas-bases/base
       - sas-bases/overlays/network/networking.k8s.io
       - ... additional resources ...
       ```

    * to

       ```yaml
       resources:
       - sas-bases/base
       - sas-bases/overlays/network/route.openshift.io
       - ... additional resources ...
       ```

1. The second change is required to apply TLS security to routes rather than to Ingress resources:

    * From

      ```yaml
      components:
      - sas-bases/components/security/core/base/full-stack-tls
      - sas-bases/components/security/network/networking.k8s.io/ingress/nginx.ingress.kubernetes.io/full-stack-tls
      ```

    * to

      ```yaml
      components:
      - sas-bases/components/security/core/base/full-stack-tls
      - sas-bases/components/security/network/route.openshift.io/route/full-stack-tls
      ```

Again, you will do these configurations when you will create your kustomization.yaml file in the next exercise.

---

## Next Steps

That completes the set-up tasks.

Click [here](/04_Deployment/04_024_Customize_Viya_Deployment.md) to follow the Manual Deployment Method: *04 024 Customize Viya Deployment*

---

## Complete Hands-on Navigation Index
<!-- startnav -->
* [01 Workshop Introduction / 01 011 Access the Environment](/01_Workshop_Introduction/01_011_Access_the_Environment.md)
* [01 Workshop Introduction / 01 012 Verify the Environment](/01_Workshop_Introduction/01_012_Verify_the_Environment.md)
* [01 Workshop Introduction / 01 999 Fast track with cheatcodes](/01_Workshop_Introduction/01_999_Fast_track_with_cheatcodes.md)
* [02 OpenShift Introduction / 02 031 Explore OpenShift](/02_OpenShift_Introduction/02_031_Explore_OpenShift.md)
* [04 Deployment / 04 021 Perform the Prerequisites](/04_Deployment/04_021_Perform_the_Prerequisites.md)
* [04 Deployment / 04 022 Prepare for Viya Deployment](/04_Deployment/04_022_Prepare_for_Viya_Deployment.md)
* [04 Deployment / 04 023 Prepare for OpenShift](/04_Deployment/04_023_Prepare_for_OpenShift.md)**<-- you are here**
* [04 Deployment / 04 024 Customize Viya Deployment](/04_Deployment/04_024_Customize_Viya_Deployment.md)
* [04 Deployment / 04 025 Manually Deploy Viya](/04_Deployment/04_025_Manually_Deploy_Viya.md)
* [04 Deployment / 04 999 Cleanup](/04_Deployment/04_999_Cleanup.md)
* [README](/README.md)
<!-- endnav -->
