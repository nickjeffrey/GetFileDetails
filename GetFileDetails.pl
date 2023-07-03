#!/bin/perl -w
#
#
# perl script to recursively query a directory and return attributes for all files in CSV format

# CHANGE LOG
# ----------
# 2023-06-30	njeffrey	Script created



use strict;				#enforce good coding practices
use Getopt::Long;                       #allow --long-switches to be used as parameters   	  yum -y install perl-Getopt-Long
use Digest::file;			#perl module for calculating md5sum/sha checksum of file  yum -y install perl-Digest-file

# declare variables
my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks);
my ($sourcedir,$sourcedir_filenames,$filelist);
my ($verbose,$get_md5sum,$epoch);
my ($opt_h,$opt_v,$opt_m,$opt_s,$opt_f);
my ($source_filename,$source_size,$source_ctime,$source_ctime_days,$source_atime,$source_atime_days,,$source_mtime,$source_mtime_days,$source_md5sum);
$verbose    = "no";			#yes|no flag to increase verbosity for debugging
$get_md5sum = "yes"; 			#yes|no flag to calculate the md5 checksum for each file



sub get_options {
   #
   # this gets the command line parameters provided by the users
   #
   print "running get_options subroutine \n" if ($verbose eq "yes");
   #
   Getopt::Long::Configure('bundling');
   GetOptions(
      "h"   => \$opt_h, "help"        => \$opt_h,
      "v"   => \$opt_v, "verbose"     => \$opt_v,
      "m=s" => \$opt_m, "md5sum=s"    => \$opt_m,
      "s=s" => \$opt_s, "sourcedir=s" => \$opt_s,
      "f=s" => \$opt_f, "filelist=s"  => \$opt_f,
   );
   #
   #
   #
   # If the user supplied -h or --help, generate the help messages
   if( defined( $opt_h ) ) {
      print "Examples: \n";
      print "   $0 --help    \n";
      print "   $0 --verbose --md5sum=yes|no --sourcedir=/path/to/folder \n";
   }
   #
   #
   #
   # If the user supplied -v or --verbose switch, use verbose output for debugging
   if( defined( $opt_v ) ) {
      $verbose = "yes";
   }
   #
   # If the user supplied -m or --md5sum=yes|no, set the flag to capture the md5sum of each file (warning: I/O intensive)
   $get_md5sum = "yes"; 			#default to "yes" if --md5sum=yes|no was not provided as a parameter
   if( defined( $opt_m ) ) {
      if ($opt_m eq "no") {
         $get_md5sum = "no"; 			#default to "yes" if --md5sum=yes|no was not provided as a parameter
      } elsif ($opt_m eq "yes") {
         $get_md5sum = "yes"; 			#default to "yes" if --md5sum=yes|no was not provided as a parameter
      } else {
         $get_md5sum = "yes"; 			#default to "yes" if --md5sum=yes|no was not provided as a parameter
      }
   } 
   print "NOTE: md5sum hashes of each file will be collected.  This is a disk-intensive operation. \n" if ($get_md5sum eq "yes");
   print "NOTE: md5sum hashes of each file will not be collected.  \n"                                 if ($get_md5sum eq "no");
   #
   # If the user supplied -s or --sourcedir, set the $sourcedir variable to the directory containing the source files
   if( defined( $opt_s ) ) {
      $sourcedir = $opt_s;
   }
   #
   # If the user supplied -f or --filelist, set the $filelist variable to the text file containing the list of filenames in $sourcedir
   if( defined( $opt_f ) ) {
      $filelist = $opt_f;
   }
}                       #end of subroutine





sub get_sourcedir {
   #
   # Confirm the sourcedir was provided as a command line parameter
   unless ($opt_s) {
      print "ERROR: Use this syntax: $0 --sourcedir=/path/to/folder \n";
      exit
   }
   #
   # confirm the sourcedir exists
   if ( ! -d "$sourcedir" ) {
      print "ERROR: could not find directory $sourcedir \n";
      exit;
   }
   #
   # Figure out the name of the text file containing the filenames in the $sourcedir
   #
   if ($opt_f) {					#check to see if user provided --filelist=/path/to/file as a parameter
      $sourcedir_filenames = $opt_f;
   } else {						#the --filelist parameter was not provided, so generate a list of files
      $sourcedir_filenames = $sourcedir;
      $sourcedir_filenames =~ s/^\/mnt\///;       	 	#get rid of /mnt/ from beginning of string
      $sourcedir_filenames =~ s/^\/data/data/;  		#change /data to data
      $sourcedir_filenames =~ s/\//\./g;  			#change / to .
      $sourcedir_filenames =~ s/$/\.filelist\.txt/;  	#append .filelist.txt 
   }
   print "sourcedir is $sourcedir \n";
   print "filelist  is $sourcedir_filenames \n";
}






sub get_source_filenames {
   #
   # generate a listing of every filename in the source folder
   # Since the files have already been copied to the local machine, we assume the local files already exist, so do not generate a listing of local files.
   # This assumption will be tested by validating that the same filename/size/datestamp/md5sum exists on the source and the target folders.
   #
   print "running subroutine get_source_filenames \n" if ($verbose eq "yes");
   #
   if (   -f "$sourcedir_filenames" ) { 
      print "NOTE: file $sourcedir_filenames already exists.  Using existing list of filenames. \n";
   }
   if ( ! -f "$sourcedir_filenames" ) {
      print "Getting list of all filenames under $sourcedir \n";
      `/usr/bin/find $sourcedir -type f > $sourcedir_filenames`;
   }
}


sub get_file_details {
   #
   # get the size, datestamp, md5sum of each file
   #
   print "running subroutine get_file_details \n" if ($verbose eq "yes");
   #
   #
   #
   # stat the file to get size and datestamp
   # The state command returns the following:
   # 0  dev      device number of filesystem
   # 1  ino      inode number
   # 2  mode     file mode  (type and permissions)
   # 3  nlink    number of (hard) links to the file
   # 4  uid      numeric user ID of file's owner
   # 5  gid      numeric group ID of file's owner
   # 6  rdev     the device identifier (special files only)
   # 7  size     total size of file, in bytes	                     <---- we want file size in bytes
   # 8  atime    last access time in seconds since the epoch
   # 9  mtime    last modify time in seconds since the epoch          <---- we want the last modification time in seconds since epoch
   # 10 ctime    inode change time in seconds since the epoch (*)
   # 11 blksize  preferred I/O size in bytes for interacting with the file (may vary from file to file) 
   # 12 blocks   actual number of system-specific blocks allocated on disk (often, but not always, 512 bytes each)
   #
   #
   # Check to see if the output textfile containing the file size/date/md5sum already exists
   if ( -f "${sourcedir_filenames}.details" ) {
      print "ERROR: Output file ${sourcedir_filenames}.details already exists.  Please delete and try again. \n";
      exit;
   }
   # Create the output file
   open (OUT,">>${sourcedir_filenames}.details") or die "Cannot open $sourcedir_filenames.details for appending $! \n";
   # The output file will be in CSV format, so put column headings in as the first line of the file\.
   print OUT "filename,bytes,CreationTimeEpoch,CreationTimeDays,AccessTimeEpoch,AccessTimeDays,ModificationTimeEpoch,ModificationTimeDays,md5sum\n";
   #
   #
   # Open the text file containing a list of all the filenames from the $sourcedir
   open (IN,"$sourcedir_filenames")              or die "Cannot open $sourcedir_filenames for reading $! \n";
   while (<IN>) {            				#read a line from filehandle
      next unless (/^\//);				#skip lines that do not begin with / character
      chomp;						#remove newline character from end of filename
      $source_filename = $_;				#put into variable for use later
      #
      # confirm the source file exists
      #
      if ( ! -f "$source_filename" ) {                  		#confirm the file exists
         print     "ERROR: Cannot find file $source_filename \n";	#echo to screen
         print OUT "ERROR: Cannot find file $source_filename \n"; 	#write to logfile
      }                                            	#end of if block
      next if ( ! -f "$source_filename" );		#skip if the source filename does not exist 
      #
      # confirm the file is readable
      #
      if ( ! -r "$source_filename" ) {                  		#confirm the file exists
         print     "ERROR: file $source_filename is not readable \n";	#echo to screen
         print OUT "ERROR: file $source_filename is not readable \n"; 	#write to logfile
      }                                            	#end of if block
      next if ( ! -r "$source_filename" );		#skip if the source filename is not readable
      #
      # Get the filename,size,last modification time on the source file
      print "   checking file $source_filename size and datestamp \n" if ($verbose eq "yes");
      ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($source_filename);      
      $source_size  = $size;
      $source_ctime = $ctime;
      $source_atime = $atime;
      $source_mtime = $mtime;
      #
      # Convert epoch seconds to nearest day
      #
      $epoch = time();							#number of seconds since epoch	
      $source_ctime_days = ($epoch - $ctime)/60/60/24; 			#convert seconds to days
      $source_atime_days = ($epoch - $atime)/60/60/24;			#convert seconds to days
      $source_mtime_days = ($epoch - $mtime)/60/60/24;			#convert seconds to days
      #
      $source_ctime_days = sprintf("%.0f", $source_ctime_days); 	#truncate to zero decimal places, nearest day is close enough
      $source_atime_days = sprintf("%.0f", $source_atime_days); 	#truncate to zero decimal places, nearest day is close enough
      $source_mtime_days = sprintf("%.0f", $source_mtime_days); 	#truncate to zero decimal places, nearest day is close enough
      #
      #
      # Get the md5sum checksum of the source file and target file
      $source_md5sum = 0;						#initialize variable to avoid undef errors if --md5sum parameter is not used
      if ($get_md5sum eq "yes") {					#check to see if the --md5sum=yes option was provided as a command line parameter
         # This step is disk I/O intensive because it has to read the contents of every file in the directory
         #
         # If you do not have the perl-Digest-file package, make a system call to /usr/bin/md5sum
         #$md5sum = `/usr/bin/md5sum \"$filename\"`;			#surround filename with quotes in case there are spaces in filename
         #$md5sum =~ s/ .*//;						#just keep the first field of output (the md5sum), get rid of trailing filename
         #chomp $md5sum;						#remove newline from end of variable
         #
         use Digest::file qw(digest_file_hex);				#call the Digest::file perl module
         if ( (-f "$source_filename") && (-r "$source_filename") ) {    #confirm the source file exists and is readable
            eval {							#catch any exceptions if the $source_filename is not readable
               $source_md5sum = digest_file_hex("$source_filename","MD5"); #get the md5sum of the source file
            };
            if ($@) {							#the $@ variable will only be populated if an exception was thrown
               print     "ERROR: Could not read $source_filename \n";
               print OUT "ERROR: Could not read $source_filename \n";
            }
         }
      }
      # 
      #
      # Write the details (filename,size,last modification time, md5sum) to a file
      print     "$source_filename,$source_size,$source_ctime,$source_ctime_days,$source_atime,$source_atime_days,$source_mtime,$source_mtime_days,$source_md5sum\n" if ($verbose eq "yes");
      print OUT "$source_filename,$source_size,$source_ctime,$source_ctime_days,$source_atime,$source_atime_days,$source_mtime,$source_mtime_days,$source_md5sum\n"; 
   }                                               #end of while loop
   close IN;                                       #close filehandle
   close OUT;                                      #close filehandle

}



#----------------- main body of script --------------------
get_options;
get_sourcedir;
get_source_filenames;	
get_file_details;


