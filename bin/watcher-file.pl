#!/usr/bin/perl
#
# Description: Monitor file modified lines to resolv problem of LogStash with CIFS shared point.
#
#
# Author:
#        Gabriel Prestes (gabriel.prestes@ilegra.com)
#
#06-22-2017 : Created

# Modules
use strict;
use POSIX;
use Getopt::Long;
use File::Basename;

# ENVs
$ENV{"USER"}="root";
$ENV{"HOME"}="/root";
$ENV{TZ} = 'America/Sao_Paulo';

# Global variables
our $name = basename($0, ".pl");
our $version="0.1";
our $date=strftime("%Y-%m-%d",localtime);
our $path = "/opt/external-logs";
our $log = "$path/log/watcher-$date.log";
our ($opt_file, $opt_help, $opt_verbose, $opt_version);

sub main {

        # --- Get Options --- #
        getoption();

        # --- Create log and var directory --- #
        my @cmd = `mkdir -p $path/log`;
        my @cmd = `mkdir -p $path/var`;

        # --- Check and write pid --- #
        if(check_pid() == 0){

                logger("----------------------");
                logger("|PROGRAM OUT: CRITICAL - Another job in execution($path/var/$name.pid)|");
                logger("----------------------");
                exit(1);

        } else {

                write_pid();

        }

        # --- Init agent --- #
        logger("----------------------");
        logger("|PROGRAM OUT: INIT AGENT - $date|");
        logger("----------------------");

        # --- Rotate logs more than 15 days --- #
        my $cmd;
        logger("----------------------");
        logger("|PROGRAM OUT: LOGs - Search for more than 15 days old|");
        logger("----------------------");
        $cmd=`\$\(which find\) $path/logs/*.log -name "*" -mtime +15 -exec \$\(which rm\) -rf {} \\; > /dev/null 2>&1`;

        # --- Get and Set Positions --- #
        getsetposition();

        # --- End agent --- #
        logger("----------------------");
        logger("|PROGRAM OUT: END AGENT - $date|");
        logger("----------------------");

        exit_program();

}

sub getsetposition {

        my $cmd;
        my $oldlines = 0;
        my $newlines = 0;
        my $difflines = 0;
        my $orgfile = "/mnt/$opt_file.log";
        my $dstfile = "/opt/external-logs/$opt_file.log";


        if ( ! -e "$path/$opt_file-lines.db" ) {

                system("echo \"0\" > $path/$opt_file-lines.db");

        }

        $oldlines = `/bin/cat $path/$opt_file-lines.db`;
        chomp($oldlines);

        if( -e $orgfile ) {

                $cmd = `wc -l $orgfile`;

                if ($cmd =~ m/^(.+) $orgfile$/){

                        $newlines = $1;
                        system("echo \"$newlines\" > $path/$opt_file-lines.db");

                }

        }

        if ($oldlines > $newlines) {

                logger("----------------------");
                logger("|PROGRAM OUT: File rotate|");
                logger("----------------------");
                $difflines = $newlines;

        } else {

                $difflines = $newlines - $oldlines;

        }

        logger("OLD LINES : $oldlines - > NEW LINES : $newlines -> DIFF LINES : $difflines");

        if ($difflines == 0){

                logger("----------------------");
                logger("|PROGRAM OUT: NO NEW LINES|");
                logger("----------------------");

        }

        elsif ($difflines > 0) {

                system ("/usr/bin/tail -n $difflines $orgfile >> $dstfile");
                logger("----------------------");
                logger("|PROGRAM OUT: $difflines input in $dstfile|");
                logger("----------------------");

        } else {

                logger("----------------------");
                logger("|PROGRAM OUT: Unexpected return|");
                logger("----------------------");

        }

}

sub exit_program {

        my $cmd;

        $cmd=`\$\(which rm\) -rf $path/var/$name.pid`;

        exit;

}

sub check_pid {

        if(-e "$path/var/$name.pid"){

                return 0;

        } else {

                return 1;

        }

}


sub write_pid {

        my $cmd;

        $cmd=`\$\(which touch\) $path/var/$name.pid`;

        return 1;

}

sub error {

        print "|ERROR - Unexpected return - contact support|\n";
        exit_program();

}

sub getoption {

     Getopt::Long::Configure('bundling');
     GetOptions(
            'F|file=s'                 => \$opt_file,
            'V|version'                 => \$opt_version,
            'h|help'                    => \$opt_help,
            'v|verbose=i'               => \$opt_verbose,
        );

     if($opt_help){

             printHelp();
             exit;

     }

     if($opt_version){

             print "$name\.pl - '$version'\n";
             exit;

     }

     if(!$opt_verbose){

             $opt_verbose = 0;

     }

     if(!$opt_file){

             printHelp();
             exit;

     }

}

sub logger {

        return (0) if (not defined $opt_verbose);

        my $msg = shift (@_);

        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
        $wday++;
        $yday++;
        $mon++;
        $year+=1900;
        $isdst++;

        if ($opt_verbose == 0){

                print "$msg\n";

        }

        else {

           open(LOG, ">>$log") or do error();
           printf LOG ("%02i/%02i/%i - %02i:%02i:%02i => %s\n",$mday,$mon,$year,$hour,$min,$sec,$msg);
           close(LOG);

        }

}

sub printHelp {

                my $help = <<'HELP';

                Monitor file modified lines to resolv problem of LogStash with CIFS shared point

                Arguments:

                -F  : file prefix to monitor
                -V  : Version
                -h  : Help
                -v 1: Send to log
                -v 0: Show log in console

                Required APIs:

                use strict;
                use Getopt::Long;
                use POSIX;
                use File::Basename;


                E.g: $path/bin/watcher-file.pl -v 1





HELP

                system("clear");
                print $help;

}

&main