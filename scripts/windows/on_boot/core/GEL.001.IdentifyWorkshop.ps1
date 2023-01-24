Write-Verbose "$('*'*30)`n$(Get-Date -UFormat '%Y-%m-%d %T') Starting $PSCommandPath"
$MODULE="$Global:codeDir\gellow\scripts\common\common_functions.psm1"

Import-Module $MODULE -Force

#Get collection ID from vars file
$RACECollectionID=$(Get-VarsFile).race_coll_id

# for other workshops there may be multiple workshops using the same collection ID.
# With this one, we have different collections for each workshop, so the next result should be unique.

#Filter C:\GELScripts\all_workshop_and_collections.txt by our raceID
#The result has format similar to :
#| PSGEL300-sas-viya-4-deployment-on-red-hat-openshift-container-platform | Collection | 333991 | VIYA4COLL1VMW | main | main | yes | viya4 |
#| PSGEL300-sas-viya-4-deployment-on-red-hat-openshift-container-platform | Collection | 372700 | VIYA4COLL1AZU | main | main | yes | viya4 |
#so we'll only keep the 1st field
$workshopURL= $(Get-Collections | Where { $_ -Like "* $RACECollectionID *"}).Split('|')[1].Trim()
Write-Debug $workshopURL

$myhash=@{}
$myhash.workshop_id=$workshopURL.Split('-')[0].Trim()
$myhash.workshop_name=$workshopURL.Split('-',2)[1].Replace("-"," ").Trim()
Write-Debug ($myhash| Out-String)

Update-VarsFile -gellowVars $myhash

Write-Output "*** DONE $PSCommandPath"