![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# SAS Viya 4 - Deployment on Red Hat OpenShift Container Platform

PSGEL300: SAS Viya 4 - Deployment on Red Hat OpenShift Container Platform

This class will cover tasks that are specific to deploying SAS Viya on Red Hat OpenShift Container Platform (OCP).

## Prerequisites

* Understand SAS Viya architecture
* Familiarity with SAS Viya deployments on Kubernetes
* Familiarity with Kubernetes
* Familiarity with Linux commands

## Current SAS Viya Release used in Class

```yaml
Cadence : lts
Version : 2022.09
```

## One deployment, but 2 Methods

* There are two  deployment methods for SAS Viya on OpenShift: **manual deployment**, **deployment operator** (SAS preferred method).

* Each deployment method comes with its unique possibilities and requirements for deploying and maintaining the environment.

* Currently, the workshop only provides exercises to explore the manual deployment method. Exercises to experiment with automation and the deployment operator will be developed next.

* There are [several options](https://access.redhat.com/documentation/en-us/openshift_container_platform/4.10/html/installing/ocp-installation-overview#supported-platforms-for-openshift-clusters_ocp-installation-overview) for the underlying infrastructure that underpins OCP. Compared to other Kubernetes platforms on supported cloud providers (AKS, GKS, AEK), a significant difference for the SAS installer is that SAS does not provide any tool/github project to deploy the OCP cluster. It is a pre-requisite, to be fulfilled by the customer's IT department.

  > For this workshop, we have instrumented a series of scripts to deploy an OpenShift cluster on Azure automatically for you.

## Clean up - why?

**Running SAS Viya in the Cloud is not free!**

* When we create an OCP cluster for you to deploy Viya on it, a lot of infrastructure resources need to be created in the Cloud on your behalf (Virtual Network, VMs, Disks,  Load-balancers, etc...)

* Although we try to reduce them as much as possible (smaller instances), it still generates significant costs: we roughly estimate them at `50 US dollars` when you let your cluster run for 8 hours.

* This is the reason why we provide you ways to clean-up the environment and destroy your cluster once you have completed your training activity.

> Everything in the Azure Active Directory tenant will be automatically deleted each and every Saturday at 12:00 EST.  Do not attempt to book anything during Saturday.

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
* [04 Deployment / 04 999 Cleanup](/04_Deployment/04_999_Cleanup.md)
* [README](/README.md)**<-- you are here**
<!-- endnav -->
