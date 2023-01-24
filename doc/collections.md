![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Collections used in this workshop

* [Instructions](#instructions)
* [Collection Index](#collection-index)
* [Collections details](#collections-details)
  * [Booking options](#booking-options)
  * [RACE machines in collection](#race-machines-in-collection)

## Instructions

* The Collection Index is a data-driving table relied on by GELLOW scripts for automation and configuration.
* list all RACE collection id's which will use GELLOW
* do not change the name or location of this file
* do not remove projects from the list
* do not change the format of the table, or the order of the columns
* the order of the lines does not matter

## Collection Index

| Type | Collection Numerical ID | Collection Name | gellow branch | Workshop Branch | Visible to Partners | Loop Category |
|  ---  |  ---  |  ---  | --- | --- | --- | --- |
| Collection | 458049 | PSGEL300_001_GE_VM | main | main | no | gelenable |
| Collection | 467796 | PSGEL300_001_GE_AZU | main | main | yes | gelenable |

## Collections details

### Booking options

* VMWare-based jumphosts:
  * Collection using *PSGEL300 SAS Viya Deploy Red Hat OpenShift* subscription in the *GELEnable* Azure tenant
    <http://race.exnet.sas.com/Reservations?action=new&imageId=458049&imageKind=C&comment=PSGEL300%20Viya4%20Deploy%20OCP%20VMWare&purpose=PST&sso=PSGEL300&schedtype=SchedTrainEDU&startDate=now&endDateLength=0&discardonterminate=y>
  * DEV Collection using *PSGEL300 SAS Viya Deploy Red Hat OpenShift* subscription in the *GELEnable* Azure tenant
    <http://race.exnet.sas.com/Reservations?action=new&imageId=458049&imageKind=C&comment=PSGEL300%20Viya4%20Deploy%20OCP%20VMWare%20_GELLOWBR_validation_%20_WKSHPBR_dev_&purpose=PST&sso=PSGEL300&schedtype=SchedTrainEDU&startDate=now&endDateLength=0&discardonterminate=y>
* Azure-based jumphosts:
  * Collection using *PSGEL300 SAS Viya Deploy Red Hat OpenShift* subscription in the *GELEnable* Azure tenant
    <http://race.exnet.sas.com/Reservations?action=new&imageId=467796&imageKind=C&comment=PSGEL300%20Viya4%20Deploy%20OCP%20Azure&purpose=PST&sso=PSGEL300&schedtype=SchedTrainEDU&startDate=now&endDateLength=0&discardonterminate=y>

### RACE machines in collection

| Machine OS | RACE image id | alias | ServerType | Name |
|  ---  |  ---  |  ---  | --- | --- |
| Linux | 1824497 | sasnode01 | GEL_VVOL | GELLOW_LNX_VMWARE |
| Windows | 1845782 | sasclient | GEL_VVOL | GELLOW_WIN_CLIENT_VMW |
| Linux | 1824495 | sasnode01 | AzureUSEast | GELLOW_LNX_AZURE |
| Windows | 2314621 | sasclient | AzureUSEast | GELLOW_WIN_CLIENT_AZ |
