<#	
.SYNOPSIS
ExpdpSchema.ps1 does a parallel Datapump export for specified instance and schema
	
.DESCRIPTION
ExpdpSchema.ps1 uses Oracle 12c Datapump expdp utility in serial or parallel mode. Produces p dumps, p being the parallel parameter. 
ExpdpSchema.ps1 can run on the server hosting the instance or from a remote server through SQL*NET

.Parameter connectStr
SQL*NET string to connect to instance. Mandatory.

.Parameter dpUser
Datapump user. Mandatory. 

.Parameter dpPwd
Datapump user password. Mandatory.

.Parameter schema
Schema to dump. Mandatory.

.Parameter parallel
number of parallel process for Datapump. Default is 6, min is 1, max is 10.
expdp runs in serial mode when parallel = 1

.Parameter directory
Datapump directory. Default is DATAPUMP.

.Parameter content
Content to export. Possible values are 'ALL','DATA_ONLY','METADATA_ONLY'. Default is 'ALL'.

.Parameter compressionAlgorithm
Level of expdp dumps compression. Possible values are 'BASIC', 'LOW','MEDIUM','HIGH'. Default is 'MEDIUM'.

.Parameter dumpfileName
dumps root filename. Default is expdp.

.Parameter dumpfileChunkSize
Size in GB of dumpfile chunks. Possible values are 1G, 2G, 4G, 8G, 16G. Default is 2G.

.Parameter estimateOnly
Estimates the dump size. No data is dumped. Possible values are 'Y','N'. Default is 'Y'.

.Parameter showParameterFile
To display expdp parameter file. Possible values are 'Y','N'. Default is 'N'.

.INPUTS

.OUTPUTS
Log file in datapump directory
Set of p expdp dumps

.Example 
ExpdpSchema -connectStr orcl -schema scott -parallel 1 -dumpfileName orcl_scott -estimateOnly Y

.Example
ExpdpSchema -connectStr orcl -parallel 8 -schema scott -directory DUMPTEMP -dumpFilename orcl_scott -content all -compression high -estimateOnly n	
#>

[CmdletBinding()] param(
  [Parameter(Mandatory=$True)] [ValidateLength(4,20)] [ValidatePattern('^[a-zA-Z]+[a-zA-B0-9]+')] [string]$connectStr,
  [ValidateLength(2,12)] [string]$dpUser = 'dp',
  [ValidateLength(4,12)] [string]$dpPwd = 'LuxVie21c',
  [Parameter(Mandatory=$True)] [ValidateLength(2,40)] [string]$schema,
  [ValidateRange(1,20)] [int]$parallel = 10,
  [ValidateSet('1G','2G','4G','8G','16G')] [string]$dumpfileChunkSize = '2G',
  [string]$directory = 'DATAPUMP',
  [ValidateSet('ALL','DATA_ONLY','METADATA_ONLY')] [string]$content = 'ALL',
  [ValidateSet('BASIC','LOW','MEDIUM','HIGH')] [string]$compressionAlgorithm = 'MEDIUM',
  [string]$dumpfileName = 'expdp',
  [ValidateSet('Y','N')] [string]$estimateOnly = 'Y',
  [ValidateSet('Y','N')] [string]$showParameterFile = 'N'
)

$thisScript = $MyInvocation.MyCommand
write-host "`nThisScript is $thisScript"
write-host "Parameters are :"
write-host "           connectStr is $connectStr"
write-host "               dpUser is $dpUser"
write-host "               schema is $schema"
write-host "            directory is $directory"
write-host "              content is $content"
write-host "         dumpfileName is $dumpfileName"
write-host "dumpfileNameChunkSize is $dumpfileChunkSize"
write-host "             parallel is $parallel"
write-host "              content is $content"
Write-Host " compressionAlgorithm is $compressionAlgorithm"
write-host "         estimateOnly is $estimateOnly"

#$tstamp = get-date -Format 'yyyyMMddTHHmm'
$tstamp = get-date -Format 'yyyyMMddTHH'

# Connection to instance
$cnx = "$dpUser/$dpPwd@$connectStr"

$job_name = 'expdp_' + $schema
Write-Output "`njob_name is $job_name"

$dumpfileName = $dumpfileName + '_' + "$tstamp"
# dump filename when dumping in parallel
if ( $parallel -gt 1 ) {
  $dumpfile  = $dumpfileName + '_%u.dmp'
}
else {
  $dumpfile = $dumpfileName + '.dmp'
}

$logfile      = $dumpfileName + '.txt'
$parfile      = 'c:\temp\' + $dumpfileName + '.par'

If (Test-Path $parfile){
  Remove-Item $parfile
  #Write-Host "Removed $parfile"
}

if ( $estimateOnly -eq 'N' ) {
  $parfile_txt = @"
JOB_NAME=$job_name
DIRECTORY=$directory
DUMPFILE=$dumpfile
FILESIZE=$dumpfileChunkSize
CONTENT=$CONTENT
COMPRESSION=ALL
COMPRESSION_ALGORITHM=$compressionAlgorithm
FLASHBACK_TIME=systimestamp
LOGFILE=$logfile
REUSE_DUMPFILES=Y
SCHEMAS=$schema
LOGTIME=ALL
KEEP_MASTER=NO
METRICS=Y
EXCLUDE=STATISTICS
"@
}
else {
  $parfile_txt = @"
JOB_NAME=$job_name
DIRECTORY=$directory
COMPRESSION=ALL
FLASHBACK_TIME=systimestamp
LOGFILE=$logfile
SCHEMAS=$schema
KEEP_MASTER=NO
METRICS=Y
LOGTIME=ALL
ESTIMATE_ONLY=YES
"@
}

# Add PARALLEL to parameter file when needed
if ( $parallel -gt 1 ) {
  $parfile_txt = $parfile_txt + "`nPARALLEL=$parallel";
}

# Make parmeter file usable by expdp
$parfile_txt | Out-File $parfile -encoding ascii

if ( $showParameterfile -eq 'Y' ) {
  write-host "`nexpdp parameter file content"
  gc $parfile
}

# record in history file
$histRec = @"
expdp, $tstamp, $connectStr, $schema, $parallel, $content, $dumpfileName, $compressionAlgorithm
"@
$histRec | Out-File 'c:\temp\datapump.txt' -Append

# workaround for very slow expdp
$enableEvent = "alter system set events'immediate trace name mman_create_def_request level 6';"
$enableEvent | sqlplus $cnx

expdp $cnx parfile=$parfile 
