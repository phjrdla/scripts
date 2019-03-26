<#	
.SYNOPSIS
ExpdpFull.ps1 does a parallel Datapump export for specified instance and schema
	
.DESCRIPTION
ExpdpFull.ps1 uses Oracle 12c Datapump expdp utility in serial or parallel mode. Produces p dumps, p being the parallel parameter. 
ExpdpFull.ps1 can run on the server hosting the instance or from a remote server through SQL*NET

.Parameter connectStr
SQL*NET string to connect to instance. Mandatory.

.Parameter connectAsSys
to connect 'as SYS'. Only when script runs on database host. Possible values are 'Y','N'. Default is 'Y'. Mandatory.

.Parameter dpUser
Datapump user. Mandatory. 

.Parameter dpPwd
Datapump user password. Mandatory.

.Parameter parallel
number of parallel process for Datapump. Default is 4, min is 1, max is 8.
expdp runs in serial mode when parallel = 1

.Parameter directory
Datapump directory. Default is DATAPUMP.

.Parameter content
Content to export. Possible values are 'ALL','DATA_ONLY','METADATA_ONLY'. Default is 'ALL'.

.Parameter compressionAlgorithm
Level of expdp dumps compression. Possible values are 'BASIC', 'LOW','MEDIUM','HIGH'. Default is 'MEDIUM'.

.Parameter dumpfileName
dumps root filename. Default is expdp.

.Parameter estimateOnly
Estimates the dump size. No data is dumped. Possible values are 'Y','N'. Default is 'Y'.

.Parameter showParameterFile
To display expdp parameter file. Possible values are 'Y','N'. Default is 'N'.

.INPUTS

.OUTPUTS
Log file in datapump directory
Set of p expdp dumps

.Example 
ExpdpFull -connectStr orcl -parallel 1 -dumpfileName orcl_full -estimateOnly Y

.Example
ExpdpFull -connectStr orcl -parallel 8 -directory DUMPTEMP -dumpFilename orcl_full -content all -compression high -estimateOnly n	
#>

[CmdletBinding()] param(
  [Parameter(Mandatory=$True)] [ValidateLength(4,12)] [ValidatePattern('^[a-zA-Z]+[a-zA-B0-9]+')] [string]$connectStr,
  [string]$connectAsSys = 'N',
  [ValidateLength(2,12)] [string]$dpUser = 'dp',
  [ValidateLength(4,12)] [string]$dpPwd = 'dpclv',
  [ValidateRange(1,12)] [int]$parallel = 4,
  [string]$directory = 'DATAPUMP',
  [ValidateSet('ALL','DATA_ONLY','METADATA_ONLY')] [string]$content = 'ALL',
  [ValidateSet('BASIC','LOW','MEDIUM','HIGH')] [string]$compressionAlgorithm = 'MEDIUM',
  [string]$dumpfileName = 'expdp',
  [ValidateSet('Y','N')] [string]$estimateOnly = 'Y',
  [ValidateSet('Y','N')] [string]$showParameterFile = 'N',
  [Parameter(Mandatory=$True) ] [ValidateSet('Y','N')] [string]$connAsSys = 'N'
)

$thisScript = $MyInvocation.MyCommand
write-host "`nThisScript is $thisScript"
write-host "Parameters are :"
write-host "          connectStr is $connectStr"
write-host "        connectAsSys is $connectAsSys"
write-host "              dpUser is $dpUser"
write-host "           directory is $directory"
write-host "             content is $content"
write-host "        dumpfileName is $dumpfileName"
write-host "            parallel is $parallel"
Write-Host "compressionAlgorithm is $compressionAlgorithm"
write-host "        estimateOnly is $estimateOnly"

$tstamp = get-date -Format 'yyyyMMddTHH'

# Connection to instance# Define connect string to database
if ( $connAsSys -eq 'Y' ) {
  $env:ORACLE_SID = $connectStr
  $cnx = '''/ as sysdba'''
}
else {
  $cnx = "$dpUser/$dpPwd@$connectStr"
}

$job_name = 'expdpfull_' + $connectStr
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
$parfile      = $dumpfileName + '.par'

If (Test-Path $parfile){
  Remove-Item $parfile
  #Write-Host "Removed $parfile"
}

# FLASHBACK_TIME=systimestamp

if ( $estimateOnly -eq 'N' ) {
  $parfile_txt = @"
JOB_NAME=$job_name
DIRECTORY=$directory
DUMPFILE=$dumpfile
CONTENT=$CONTENT
COMPRESSION=ALL
COMPRESSION_ALGORITHM=$compressionAlgorithm
LOGFILE=$logfile
REUSE_DUMPFILES=Y
FULL=Y
LOGTIME=ALL
KEEP_MASTER=NO
METRICS=Y
EXCLUDE=STATISTICS
FLASHBACK_TIME=systimestamp
"@
}
else {
  $parfile_txt = @"
JOB_NAME=$job_name
DIRECTORY=$directory
COMPRESSION=ALL
COMPRESSION_ALGORITHM=$compressionAlgorithm
LOGFILE=$logfile
FULL=Y
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

expdp $cnx parfile=$parfile 

#expdp `'$cnx`' parfile=$parfile 2>&1 | % { "$_" }
