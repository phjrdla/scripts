[CmdletBinding()] param(
  [Parameter(Mandatory=$True) ] [string]$connectStr,
  [Parameter(Mandatory=$True) ] [string]$username,  [Parameter(Mandatory=$True) ] [string]$password = $( Read-Host -asSecureString "Input password" )
)

$cnx = "$username/$password@$connectStr"

write-output '##########################################################################################################'
$tstamp = get-date -Format 'yyyyMMdd-hhmmss'
write-output "Daily checks for $connectStr on $tstamp"
write-output '##########################################################################################################'
 
##########################################################################################################
function RestoreValidate {
  param( $cnx )

  $thisFunction = '{0}' -f $MyInvocation.MyCommand
  write-output "`nThis is function $thisFunction"
  write-output "`nValidate restore database"

  $rcv = @"
connect target $cnx
CONFIGURE DEVICE TYPE 'SBT_TAPE' PARALLELISM 10 BACKUP TYPE TO BACKUPSET;
restore database validate;
"@
  $rcv | rman
}

RestoreValidate $cnx

write-output '##########################################################################################################'
$tstamp = get-date -Format 'yyyyMMdd-hhmmss'
write-output "End of validate for $connectStr on $tstamp"
write-output '##########################################################################################################'
