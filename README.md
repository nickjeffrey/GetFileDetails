# GetFileDetails
Get filename, size, creation time, access time, modification time, checksum for all files in a folder

# Overview
These scripts (PowerShell for Windows environments, perl for UNIX-like environments) are used to gather details for all files in a directory tree, including:
- full path and filename
- size in bytes
- file creation time (in seconds since epoch and days)
- file access time (in seconds since epoch and days)
- file modification time (in seconds since epoch and days)
- MD5 checksum

# Usage

For Windows environments:
    ```  powershell.exe X:\path\to\GetFileDetails.ps1 --dirname=\\server\share\subdir --md5sum=yes|no```

For UNIX    environments:
    ```   /path/to/GetFileDetails.pl --sourcedir=/path/to/sourcedir --verbose --md5sum=yes|no```

Output will be a CSV file that can be viewed in a spreadsheet for further analysis
