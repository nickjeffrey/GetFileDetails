# powershell script to recursively query a directory and return attributes for all files in CSV format

# OUTSTANDING TASKS
# -----------------
# add error checks to confirm CreationTime,LastAccessTime,LastWriteTime values exist before calculating epoch seconds
# add documentation explaining how some filesystems do not track LastAccessTime 
# add -verbose flag
# Change the datestamp format for $CreationTime to yyyymmddhhmmss
# add columns for CreationTimeDays,AccessTimeDays,ModificationTimeDays

# CHANGE LOG
# ----------
# 2023-06-30	njeffrey	Script created


# check to see if $dirname was provided on the command line
param(
    [string]$dirname,
    [string]$md5sum
)

# Confirm the $dirname variable exists
if ($dirname) {
   Write-Host "Found parameter `"-dirname $dirname`" on command line"
} else {
   Write-Host "Use these parameters: "
   Write-Host "  -dirname \\server\share\subdir   or   -dirname x:\path\to\dir"
   Write-Host "  -md5sum yes|no  (defaults to yes)"
   exit
}

if ( $md5sum -eq "no" ) {
   Write-Host "Found parameter `"-md5 no`" on command line, skipping md5 checksum calculations"
} else {
   $md5sum = "yes"
}

# Confirm the folder specified by $dirname exists 
if (Test-Path $dirname) {
   Write-Host "Confirming folder exists: $dirname"
} else {
   Write-Host "Cannot access directory $dirname"
   exit
}




#output the CSV column headers
Write-Host ""
Write-Host "Filename,Bytes,CreationTimeEpoch,AccessTimeEpoch,LastWriteTimeEpoch,CreationTime_yyyymmddHHMMSS,LastAccessTime_yyyymmddHHMMSS,LastWriteTime_yyyymmddHHMMSS,MD5sum,DaysSinceModified"

Get-ChildItem "$dirname" -Recurse -File | ForEach-Object {
    # 
    # Get the full path and filename, size in bytes
    #
    $filename           = $_.FullName
    $bytes              = $_.Length
    #
    # Get file attributes: CreationTime, LastAccessTime, LastWriteTime
    #
    $CreationTime        = Get-Date -date $_.CreationTime -Uformat %Y%m%d%H%M%S     	#datestamp format yyddmmHHMMSS
    $CreationTimeEpoch   = Get-Date -date $_.CreationTime -UFormat %s   	 	#datestamp in epoch seconds
    $CreationTimeEpoch   = [math]::Round($CreationTimeEpoch)           			#round to nearest second

    $LastAccessTime      = Get-Date -date $_.LastAccessTime -Uformat %Y%m%d%H%M%S     	#datestamp format yyddmmHHMMSS
    $LastAccessTimeEpoch = Get-Date -date $_.LastAccessTime -UFormat %s    		#datestamp in epoch seconds
    $LastAccessTimeEpoch = [math]::Round($LastAccessTimeEpoch)           		#round to nearest second

    $LastWriteTime       = Get-Date -date $_.LastWriteTime -Uformat %Y%m%d%H%M%S     	#datestamp format yyddmmHHMMSS
    $LastWriteTimeEpoch  = Get-Date -date $_.LastWriteTime -UFormat %s    		#datestamp in epoch seconds
    $LastWriteTimeEpoch  = [math]::Round($LastWriteTimeEpoch)           		#round to nearest second


    #
    # Get the MD5 checksum of the file
    # Warning: this can be very time-consuming for large folders
    #
    if ( $md5sum -eq "yes" ) {
       $md5             = (Get-FileHash $filename -Algorithm MD5).Hash
    } else {
       $md5= 0
    }
    #
    # Calculate days since file was modified, to make it easy to find stale files
    $epoch = Get-Date -Uformat %s
    $DaysSinceModified = ($epoch - $LastWriteTimeEpoch)/60/60/24    #convert seconds to days
    $DaysSinceModified = [math]::Round($DaysSinceModified)          #round to nearest day 
    #
    # print the details in CSV format
    #
    Write-Host "`"$filename`",$bytes,$CreationTimeEpoch,$LastAccessTimeEpoch,$LastWriteTimeEpoch,`"$CreationTime`",`"$LastAccessTime`",`"$LastWriteTime`",$md5,$DaysSinceModified"
}



