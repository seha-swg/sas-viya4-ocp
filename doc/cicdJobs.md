# CI/CD jobs tied to this workshop

1. [test the workshop](#test-the-workshop)
1. [renew PSGEL300 SP credentials](#renew-psgel300-sp-credentials)
1. [renew psgel300sa StorageAccount Keys](#renew-psgel300sa-storageaccount-keys)

## Test the workshop

* Test that the PSGEL300 SP can login to Azure with the certificate on GELWEB. On failure, call the job to [renew the certificate](#renew-psgel300-sp-credentials)

* Test that the psgel300sa SAS read-only key is valid to read the CoreOS VHD image. On failure, call the job to [renew the storage account keys](#renew-psgel300sa-storageaccount-keys)

## Renew PSGEL300 SP credentials

The PSGEL300 service principal has been created with a client certificate that is used by scripts in the workshop to login in batch to Azure.

The certificate is stored to and retrieved from GELWEB. It should be renewed once every few months.

## Renew psgel300sa StorageAccount Keys

The psgel300sa storage account is defined in the GEL subscription and is used to manage/access the storage that holds the CoreOS VHD image used to deploy OCP.

There are 2 keys that can be renewed:

1. main StorageAccount key. Gives complete access to the account and the storage. It is used by a GEL member to upload the CoreOS image.
1. read-only SAS key. Created from the previous key, is used in the workshop to access the CoreOS image. When the previous key is invalidated or re-created, this should be, too.

Instructions: <https://docs.microsoft.com/en-us/azure/storage/common/storage-account-keys-manage?tabs=azure-portal#manually-rotate-access-keys>
