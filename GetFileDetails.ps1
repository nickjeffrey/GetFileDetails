# powershell script to recursively query a directory and return attributes for all files in CSV format




# OUTSTANDING TASKS
# -----------------
# add -verbose flag




# CHANGE LOG
# ----------
# 2023-06-30	njeffrey	Script created


# USAGE NOTES
# -----------
# This script will recursively query all the files in a directory tree, returning info about:
# filename, size, CreationTime,AccessTime,ModifiedTime,MD5sum
#
# This script should be run from a PowerShell prompt like this: PS C:\path> .\scriptname.ps1 -dirname "\\server\share\subdir" -md5sum yes|no
#
# HINT: Do not execute this shell from a Windows cmd.exe command prompt like this: powershell.exe x:\path\to\script.ps1
# because cmd.exe does not understand embedded quotes in parameters, and this script has syntax like: PS c:\> .\scriptname.ps1 -dirname "x:\path to\blah" 
#
# Please note that some filesystems do not track the LastAccessTime attribute, so this value may be the same as the CreationTime attribute.


# check to see if $dirname was provided on the command line
param(
    [string]$dirname,
    [string]$md5sum
)

# Confirm the $dirname variable exists
if ("$dirname") {						#returns true if the variable name exists
   Write-Output "Found parameter:  -dirname $dirname"
} else {
   Write-Output "Use these parameters: "
   Write-Output "  -dirname `"\\server\share\subdir`"  (example using UNC path,     use quotes if path contains spaces)"
   Write-Output "  -dirname `"x:\path\to\dir`"         (example using drive letter, use quotes if path contains spaces)"
   Write-Output "  -md5sum yes`|no                    (calculate MD5 checksum, defaults to yes)" 	#escape the pipe character with a backtick
   Write-Output "  > MyOutputFile.csv 	            (redirect output to text file instead of STDOUT)"
   exit
}
# Confirm the -md5sum parameter was provided on the command line
if ( $md5sum -eq "no" ) {
   Write-Output "Skipping MD5 checksum calculation due to parameter:  -md5sum no"
} else {
   $md5sum = "yes"
}

# Confirm the folder specified by $dirname exists 
if (Test-Path -PathType Container -Path "$dirname") {	#surround with quotes in case there are embedded spaces
   Write-Output "Confirming folder exists: $dirname"
} else {
   Write-Output "Cannot access directory $dirname"
   exit
}



#
#output the CSV column headers
#
Write-Output " "
Write-Output "Filename,Bytes,MegaBytes,GigaBytes,CreationTimeEpoch,DaysSinceCreation,AccessTimeEpoch,DaysSinceAccess,LastWriteTimeEpoch,DaysSinceModification,MD5sum"


#
# capture the details for each file
#
Get-ChildItem "$dirname" -Recurse -File | ForEach-Object {
    # 
    # Initialize variables to avoid undef errors, just in case the file attributes cannot be retrieved
    #
    $epoch              = 0								#initialize variable to avoid undef errors
    $filename           = "ERROR Could not determine filename"				#initialize variable to avoid undef errors
    $bytes              = 0 								#initialize variable to avoid undef errors
    $megabytes          = 0 								#initialize variable to avoid undef errors
    $gigabytes          = 0 								#initialize variable to avoid undef errors
    $CreationTime       = 0 								#initialize variable to avoid undef errors
    $LastAccessTime     = 0 								#initialize variable to avoid undef errors
    $LastWriteTime      = 0 								#initialize variable to avoid undef errors
    $md5                = 0 								#initialize variable to avoid undef errors
    #
    # Get the current time
    #
    $epoch              = Get-Date -Uformat %s 						#current time in elapsed seconds since epoch 1970-01-01
    #
    # Get the full path and filename, size in bytes
    #
    $filename           = $_.FullName
    $bytes              = $_.Length
    if ($bytes -gt 0) { $megabytes = [math]::Round($bytes/1024/1024)} 			#convert bytes to megabytes, rounded to nearest integer
    if ($bytes -gt 0) { $gigabytes = [math]::Round($bytes/1024/1024/1024)} 		#convert bytes to gigabytes, rounded to nearest integer
    #
    # Get file attributes related to CreationTime
    #
    $CreationTime        = Get-Date -date $_.CreationTime -Uformat %Y%m%d%H%M%S     	#datestamp format yyddmmHHMMSS
    $CreationTimeEpoch   = Get-Date -date $_.CreationTime -UFormat %s   	 	#datestamp in epoch seconds
    $CreationTimeEpoch   = [math]::Round($CreationTimeEpoch)           			#round to nearest second
    $DaysSinceCreation   = ($epoch - $CreationTimeEpoch)/60/60/24    			#convert epoch seconds to days since file was created
    $DaysSinceCreation   = [math]::Round($DaysSinceCreation)          			#round to nearest day 
    #
    # Get file attributes related to LastAccessTime 
    #
    $LastAccessTime      = Get-Date -date $_.LastAccessTime -Uformat %Y%m%d%H%M%S     	#datestamp format yyddmmHHMMSS
    $LastAccessTimeEpoch = Get-Date -date $_.LastAccessTime -UFormat %s    		#datestamp in epoch seconds
    $LastAccessTimeEpoch = [math]::Round($LastAccessTimeEpoch)           		#round to nearest second
    $DaysSinceAccess     = ($epoch - $LastAccessTimeEpoch)/60/60/24    			#convert epoch seconds to days since file was last accessed
    $DaysSinceAccess     = [math]::Round($DaysSinceAccess)          			#round to nearest day 
    #
    # Get file attributes related to LastWriteTime (ie file modification time)
    #
    $LastWriteTime       = Get-Date -date $_.LastWriteTime -Uformat %Y%m%d%H%M%S     	#datestamp format yyddmmHHMMSS
    $LastWriteTimeEpoch  = Get-Date -date $_.LastWriteTime -UFormat %s    		#datestamp in epoch seconds
    $LastWriteTimeEpoch  = [math]::Round($LastWriteTimeEpoch)           		#round to nearest second
    $DaysSinceModified = ($epoch - $LastWriteTimeEpoch)/60/60/24    			#convert epoch seconds to days since file was last modified
    $DaysSinceModified = [math]::Round($DaysSinceModified)          			#round to nearest day 
    #
    # Get the MD5 checksum of the file (can be very time-consuming for large files)
    # HINT: use the "-md5sum no" command line parameter if you do not want MD5 checksums
    #
    if ( $md5sum -eq "yes" ) { 								#check for "-md5sum yes|no" command line parameter
       $md5             = (Get-FileHash $filename -Algorithm MD5).Hash                  #calculate the MD5 checksum
    } else { $md5=0 } 									#skip calculation of the MD5 checksum, put in dummy value of zero
    #
    # print the details in CSV format
    #
    Write-Output "`"$filename`",$bytes,$megabytes,$gigabytes,$CreationTimeEpoch,$DaysSinceCreation,$LastAccessTimeEpoch,$DaysSinceAccess,$LastWriteTimeEpoch,$DaysSinceModified,$md5"
}


