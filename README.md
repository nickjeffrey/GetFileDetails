# GetFileDetails
Get filename, size, creation time, access time, modification time, checksum for all files in a folder

# Overview
These scripts (PowerShell for Windows environments, perl for UNIX-like environments) are used to gather details for all files in a directory tree, including:
- full path and filename
- size in bytes
- file creation time (in seconds since epoch and days)
- file access time (in seconds since epoch and days)
- file modification time (in seconds since epoch and days)
- MD5 checksum (optional)

# Usage

For Windows environments:

    PS> X:\path\to\GetFileDetails.ps1 -dirname "\\server\share\subdir" -md5sum yes|no

For UNIX    environments:

    /path/to/GetFileDetails.pl --sourcedir=/path/to/sourcedir --md5sum=yes|no --verbose 

Output will be a CSV file that can be viewed in a spreadsheet for further analysis

# Sample CSV Output
|filename|bytes|CreationTimeEpoch|CreationTimeDays|AccessTimeEpoch|AccessTimeDays|ModificationTimeEpoch|ModificationTimeDays|md5sum|
|--------|-----|-----------------|----------------|---------------|--------------|---------------------|--------------------|------|
|/my/path/foo.txt|102576|1671338541|198|1688369516|1|1671338541|198|2f2226871aeecbd1a90046e58bd1252a|
|x:\my\path\bar.txt|10371|1671338572|239|1688369516|1|1671338572|198|c404237c5dd9cb33b2e0a49eba05a038|
|\\\CIFS_server\share\subdir\baz.csv|543705|1673128005|17|1688369516|1|1673128005|7|2e191408caad38b69a8f75a8ca53f443|
|/my/path/subdir1/x.txt|1077|1671329998|18|1688369516|1|1671329998|1|42a30bd0677998d72bd6ce967f182cfe|
|/my/path/subdir2/y.txt|3073|1671330178|4|1688369516|1|1671330178|2|31023e7a5348e02625e92b3997eb803c|

