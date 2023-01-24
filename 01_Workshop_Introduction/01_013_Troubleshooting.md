![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Troubleshooting

If you encounter issues while accessing the collection for this workshop, try the troubleshooting tips below.

## You do not have access to the collection

* Issue:

    When booking the collection you receive an error message similar to the following:

    ```log
    You do not have access to Collection 458049  - Viya 4 - Deployment Collection
    ```

    it means that you need to request membership in the STICExnetUsers group.

* Solution:
  * Click [here](mailto:dlistadmin@wnt.sas.com?subject=Subscribe%20STICEXNETUsers) to prepare an email request to join STICExnetUsers group.
  * Send the email as-is, without any changes.
  * You will be notified via email as soon as you have been added to the group. Your account should be ready for use within an hour. Sometimes it can take longer than an hour to propagate your group membership through the SAS network. To expedite the change, you can log out of the SAS network and log back in. Until your group membership is activated, RACE will keep informing you that you are not authorized to reserve the environment.

## Windows Jump Host seems different than the screenshots in the exercises

* Issue:
  * The Windows Jump Host does not show the blue background with the name of this workshop (click [here](/img/WindowsLogon.png) to see an example of the expected background)
  * Chrome on the Windows Jump Host does not have all the expected bookmarks (click [here](/img/WindowsChrome.png) to see an example of the expected bookmarks)

* Solution:
  1. You may have logged in too early, while the environment is still initializing. Please sign out and wait at least 10 minutes before reconnecting.
      > Note: it is not enough to close the remote session, you have to do a full sign out from the Start Menu:
      >
      > ![SignOut](/img/WindowsSignOut.png)
  1. If nothing changes after signing out, waiting, and signing back in, then your best option is to terminate your existing reservation and start a new one. We have found that troubleshooting intermittent RACE problems is not worth the time it takes and as problems happen much less frequently than successful deployments, it is better to just try again with a new set of machines.  Your reservation email should have a link to where you can terminate your current reservation.

## Linux Jump Host does not report a successful initialization

* Issue:
  * When opening MobaXTerm session and checking on the collection status, errors are reported such as in the following log:

    ```log
    $ tail /opt/gellow_work/logs/gellow_summary.log

    ...
    01/31/22 16:01:32:  FAIL  Final message: we detected 4 failure(s) in this RACE collection
    01/31/22 16:01:32:  FAIL  It might not behave properly
    01/31/22 16:01:32:  FAIL  Please book a new collection
    01/31/22 16:01:32: #####################################################################################
    01/31/22 16:01:32: ####### DONE WITH THE BOOTSTRAPPING OF THE MACHINE ##################################
    01/31/22 16:01:32: #####################################################################################
    01/31/22 16:01:32: Done running script gellow.sh start
    ```

* Solution:
  * Your best option is to terminate your existing reservation and start a new one. We have found that troubleshooting intermittent RACE problems is not worth the time it takes and as problems happen much less frequently than successful deployments, it is better to just try again with a new set of machines.  Your reservation email should have a link to where you can terminate your current reservation.
  * If this keeps happening, please post a message in the Q&A forum of the VLE. An instructor may be able to connect to your environment and understand what is going on.
