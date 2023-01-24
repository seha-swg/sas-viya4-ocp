![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Deploy SAS Viya 4 in OpenShift

* [Introduction](#introduction)
* [Create a sitedefault file](#create-a-sitedefault-file)
* [Configure CAS](#configure-cas)
  * [Configure CAS MPP](#configure-cas-mpp)
  * [Adjust RAM and CPU Resources for CAS](#adjust-ram-and-cpu-resources-for-cas)
* [Configure PostgreSQL](#configure-postgresql)
* [Configure TLS for the cluster ingress controller](#configure-tls-for-the-cluster-ingress-controller)
* [Create the storage class patch for the RWX StorageClass](#create-the-storage-class-patch-for-the-rwx-storageclass)
* [Create the kustomization file](#create-the-kustomization-file)
* [Next Steps](#next-steps)
* [Complete Hands-on Navigation Index](#complete-hands-on-navigation-index)

## Introduction

At this point, the OpenShift cluster should be ready and all pre-requisites should have been completed and verified.
The next steps are to customize the deployment files, then perform the deployment. Most of these steps are not specific to OpenShift, but rather tailored to each customer's Viya environment (in our case, to this workshop environment).

## Create a sitedefault file

Some configuration settings can be pre-loaded using a `sitedefault.yaml` file. To simplify user management for this workshop, we provide a file already configured to connect to our Azure Active Directory - the same used by the OpenShift cluster.

1. Copy the provided file in the proper location with the following command:

    ```bash
    # Copy the site-default
    cp /opt/gellow_code/scripts/loop/gelenable/gelenable_site-config/gelenable-sitedefault.yaml \
       ~/project/gelocp/site-config/
    ```

## Configure CAS

### Configure CAS MPP

By default CAS is installed with a SMP CAS Server; in this workshop we want to use a MPP CAS Server.

1. Run the commands below to configure CAS with 2 workers.

    ```bash
    # Set the desired number of workers
    CAS_WORKERS=2
    # Copy the sample PatchTransformer and configure the desired number of workers
    sed -e "s/{{ NUMBER-OF-WORKERS }}/${CAS_WORKERS}/g" \
        ~/project/gelocp/sas-bases/examples/cas/configure/cas-manage-workers.yaml \
        > ~/project/gelocp/site-config/cas-manage-workers.yaml
    ```

### Adjust RAM and CPU Resources for CAS

In our environment there are no nodes labeled for CAS workloads, so it is not possible to use the CAS auto-resourcing capability. For this reason, we have to set our own RAM and CPU resources manually.

1. Run the commands below to configure CAS resources.

    ```bash
    # Set the required number of workers
    # In this workshop we keep the numbers low on purpose to be able to use smaller machines
    CAS_CPU_=1
    CAS_MEMORY=2Gi
    # Copy the sample PatchTransformer and configure the desired number of workers
    sed -e "s/{{ AMOUNT-OF-RAM }}/${CAS_MEMORY}/g" \
        -e "s/{{ NUMBER-OF-CORES }}/${CAS_CPU_}/g" \
        ~/project/gelocp/sas-bases/examples/cas/configure/cas-manage-cpu-and-memory.yaml \
        > ~/project/gelocp/site-config/cas-manage-cpu-and-memory.yaml
    ```

## Configure PostgreSQL

In this environment we are using an internal instance of PostgreSQL, we have to configure it according to the deployment guide.

1. Run the commands below to copy and configure the files required by internal PostgreSQL

    ```bash
    cp ~/project/gelocp//sas-bases/examples/configure-postgres/internal/pgo-client/* \
       ~/project/gelocp/site-config/configure-postgres/internal/pgo-client/
    # the files we need to modify are write-protected. Change the permission
    chmod u+w ~/project/gelocp/site-config/configure-postgres/internal/pgo-client/*
    # our environment does not include the sas-crunchy-data-cdspostgres database, remove it from the scheduled backup
    sed -i -e "s/sched_bkup sas-crunchy-data-cdspostgres;//" \
        ~/project/gelocp/site-config/configure-postgres/internal/pgo-client/kustomization.yaml
    ```

## Configure TLS for the cluster ingress controller

By default all internal and external communications are TLS encrypted.
SAS Viya, by default, provides an OpenSSL-based certificate generator to dynamically create internal certificates when required.

For this workshop, there are no IT-provided certificates for the cluster ingress controller; for this reason, you have to configure SAS Viya to use the OpenSSL certificate generator also to generate the external certificates.

On other Kubernetes platforms, using the NGINX ingress controller, the certificate generator can generate ingress certificates on-the-flight, when required. On OCP, instead, the Red Hat OpenShift Ingress Operator requires that a secret containing the ingress certificates and key be pre-created independently of the network route resources - similar to the use case of customer-provided ingress certificates. The certificates must be stored in a secret named in the route’s `cert-utils-operator.redhat-cop.io/certs-from-secret` annotation.

An example of the code that creates an ingress controller certificate and stores it in a secret is provided in `sas-bases/examples/security/openssl-generated-ingress-certificate.yaml`. Unless there are special requirements - described in the file itself - the file can be included as-is.

1. Run the commands below to copy the file used to generate the ingress certificate in the site-config/security directory:

    ```bash
    # Copy the file used to generate the ingress certificate
    cp ~/project/gelocp/sas-bases/examples/security/openssl-generated-ingress-certificate.yaml \
       ~/project/gelocp/site-config/security/openssl-generated-ingress-certificate.yaml
    ```

## Create the storage class patch for the RWX StorageClass

We previously verified that the OCP cluster has a storage class configured as per SAS Viya system requirements. Now we have to create a patch file that will be referenced in the `kustomization.yaml` file to specify which PersistentVolumeClaims should use the ReadWriteMany StorageClass.

1. Run the following code the create the patch file:

    ```bash
    cat > ~/project/gelocp/site-config/storageclass.yaml <<-EOF
    kind: RWXStorageClass
    metadata:
      name: wildcard
    spec:
      storageClassName: sas-azurefile #With sas UID/GID
    EOF
    ```

## Create the kustomization file

As a final step, let's create the kustomization.yaml file that references all the configurations that were just defined above.
Note that we include all specific OpenShift changes, including the files to remove the seccomp annotations and change the fsGroup id, as we explained in the previous exercise.

1. Run the following code:

    ```bash
    ### Set the FQDN of the ingress
    NS="gel-viya"
    # get the base domain from OpenShift ingress
    APPS_DOMAIN=$(oc get ingresscontroller.operator.openshift.io -n openshift-ingress-operator -o jsonpath='{.items[].status.domain}')
    INGRESS_FQDN="${NS}.${APPS_DOMAIN}"
    echo "SAS Viya Namespace: ${NS}"
    echo "SAS Viya Ingress: ${INGRESS_FQDN}"

    cat > ~/project/gelocp/kustomization.yaml <<-EOF
    ---
    namespace: ${NS}
    resources:
      - sas-bases/base
      - sas-bases/overlays/network/route.openshift.io/v1/route                           ## OCP: route instead of ingress
      - sas-bases/overlays/cas-server
      - sas-bases/overlays/internal-postgres
      - site-config/configure-postgres/internal/pgo-client
      - sas-bases/overlays/internal-elasticsearch
      - sas-bases/overlays/update-checker
    #  - sas-bases/overlays/cas-server/auto-resources                                    ## no CAS auto-resources, since no node has been labeled for CAS
      - site-config/security/openssl-generated-ingress-certificate.yaml                  ## causes openssl to generate an ingress certificate and key and store them in a secret

    configurations:
      - sas-bases/overlays/required/kustomizeconfig.yaml

    transformers:
      - sas-bases/overlays/internal-elasticsearch/sysctl-transformer.yaml
      - sas-bases/overlays/startup/ordered-startup-transformer.yaml
      - sas-bases/overlays/required/transformers.yaml
    #  - sas-bases/overlays/cas-server/auto-resources/remove-resources.yaml              ## no CAS auto-resources, since no node has been labeled for CAS
      - sas-bases/overlays/internal-elasticsearch/internal-elasticsearch-transformer.yaml
      # custom settings
      - site-config/cas-manage-workers.yaml
      - site-config/cas-manage-cpu-and-memory.yaml
      # OCP security settings
      - sas-bases/overlays/security/container-security/remove-seccomp-transformer.yaml   ## OCP: remove seccomp
      - site-config/security/update-fsgroup.yaml                                         ## OCP: use an fsGroup permitted by OCP restricted SCC

    components:
      - sas-bases/components/security/core/base/full-stack-tls
      - sas-bases/components/security/network/route.openshift.io/route/full-stack-tls    ## OCP: route instead of ingress

    patches:
    - path: site-config/storageclass.yaml
      target:
        kind: PersistentVolumeClaim
        annotationSelector: sas.com/component-name in (sas-backup-job,sas-data-quality-services,sas-commonfiles,sas-cas-operator,sas-pyconfig,sas-event-stream-processing-studio-app,sas-reference-data-deploy-utilities,sas-model-publish)

    configMapGenerator:
      - name: ingress-input
        behavior: merge
        literals:
          - INGRESS_HOST=${INGRESS_FQDN}

      - name: sas-shared-config
        behavior: merge
        literals:
          - SAS_SERVICES_URL=https://${INGRESS_FQDN}

    secretGenerator:
      - name: sas-consul-config
        behavior: merge
        files:
          - SITEDEFAULT_CONF=site-config/gelenable-sitedefault.yaml
    EOF
    ```

After you revise the base kustomization.yaml file, continue your SAS Viya deployment as documented.

---

## Next Steps

At this point, you have prepared and customized all of the deployment files.
The next step is to perform SAS Viya deployment.

Click [here](/04_Deployment/04_025_Manually_Deploy_Viya.md) to move onto the next exercise: ***04 025 Manually Deploy Viya***

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
* [04 Deployment / 04 024 Customize Viya Deployment on OpneShift](/04_Deployment/04_024_Customize_Viya_Deployment.md)**<-- you are here**
* [04 Deployment / 04 025 Manually Deploy Viya](/04_Deployment/04_025_Manually_Deploy_Viya.md)
* [04 Deployment / 04 999 Cleanup](/04_Deployment/04_999_Cleanup.md)
* [README](/README.md)
<!-- endnav -->
