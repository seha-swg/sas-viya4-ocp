![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Fast track with the cheatcodes

* [WARNING](#warning)
* [IDEMPOTENCY](#idempotency)
* [(Re)generate the cheatcodes](#regenerate-the-cheatcodes)
* [Run the cheatcodes](#run-the-cheatcodes)
* [Navigation](#navigation)

## WARNING

The 'cheatcodes' have been developed for this workshop and are **NOT** part of the SAS Viya software, nor are they an official tool supported by SAS. They provide an automated path through the lab exercises.

## IDEMPOTENCY

* The cheatcodes are designed to be idempotent, you should be able to run them as many time as required.

## (Re)generate the cheatcodes

* The cheatcodes are automatically built from md files that are provided in the "PSGEL300-sas-viya-4-deployment-on-red-hat-openshift-container-platform" folder.

* Run these commands to re-generate the cheatcodes for the OCP Hands-on, using the GELLOW cheatcode generator.

    ```sh
    cd ~/PSGEL300-sas-viya-4-deployment-on-red-hat-openshift-container-platform/
    git pull
    # optionally, you can switch to a different version branch
    # ex:
    # git checkout "release/stable-2021.1.6"
    /opt/gellow_code/scripts/cheatcodes/create.cheatcodes.sh /home/cloud-user/PSGEL300-sas-viya-4-deployment-on-red-hat-openshift-container-platform/
    ```

  Now you can directly call the cheatcodes for each step.

## Run the cheatcodes

* To verify the OCP cluster, perform the pre-requisites and deploy Viya 4

    ```sh
    bash -x ~/PSGEL300*/_all.sh
    ```

* To run only a specific exercise, print the content of the `_all.sh` file and copy-paste the command you want to run:

    ```sh
    cat ~/PSGEL300*/_all.sh
    # run exercise "Track-A-Standard/00-Common/00_130_Preparing_for_Openshift.sh":
    bash -x /home/cloud-user/PSGEL300-sas-viya-4-deployment-on-red-hat-openshift-container-platform/Track-A-Standard/00-Common/00_130_Preparing_for_Openshift.sh 2>&1 | tee -a  /home/cloud-user/PSGEL300-sas-viya-4-deployment-on-red-hat-openshift-container-platform/Track-A-Standard/00-Common/00_130_Preparing_for_Openshift.log
    ```

## Navigation

<!-- startnav -->
* [01 Workshop Introduction / 01 011 Access the Environment](/01_Workshop_Introduction/01_011_Access_the_Environment.md)
* [01 Workshop Introduction / 01 012 Verify the Environment](/01_Workshop_Introduction/01_012_Verify_the_Environment.md)
* [01 Workshop Introduction / 01 999 Fast track with cheatcodes](/01_Workshop_Introduction/01_999_Fast_track_with_cheatcodes.md)**<-- you are here**
* [02 OpenShift Introduction / 02 031 Explore OpenShift](/02_OpenShift_Introduction/02_031_Explore_OpenShift.md)
* [04 Deployment / 04 021 Perform the Prerequisites](/04_Deployment/04_021_Perform_the_Prerequisites.md)
* [04 Deployment / 04 022 Prepare for Viya Deployment](/04_Deployment/04_022_Prepare_for_Viya_Deployment.md)
* [04 Deployment / 04 023 Prepare for OpenShift](/04_Deployment/04_023_Prepare_for_OpenShift.md)
* [04 Deployment / 04 024 Customize Viya Deployment](/04_Deployment/04_024_Customize_Viya_Deployment.md)
* [04 Deployment / 04 025 Manually Deploy Viya](/04_Deployment/04_025_Manually_Deploy_Viya.md)
* [04 Deployment / 04 999 Cleanup](/04_Deployment/04_999_Cleanup.md)
* [README](/README.md)
<!-- endnav -->
