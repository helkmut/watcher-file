# watcher-file
Monitor file modified lines to resolv problem of LogStash with CIFS shared point


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

