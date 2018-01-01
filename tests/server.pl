eval '(exit $?0)' && eval 'exec perl "$0" ${1+"$@"}'
  & eval 'exec perl "$0" $argv:q'
    if 0;
# A simple netcat-like TCP server.
my $VERSION = '2018-01-01 13:25 UTC';

# Copyright (C) 2014-2018 Free Software Foundation, Inc.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# Written by Guilherme F. Lima

use strict;
use warnings;
use Getopt::Long;

use IO::Socket;
use POSIX qw(:sys_wait_h);

(my $ME = $0) =~ s|.*/||;

my $mode = 'echo';              # server mode
my $pid;                        # pid-file
my $port = 1986;                # server port
my $verbose;                    # true if verbose is on

my $server;                     # server handle
my @child_pid_list;             # list of child server PIDs

sub info {
    my ($msg) = @_;
    $verbose and print "[$$]\t$msg\n";
}

sub done {
    info "server stopped";
    foreach (@child_pid_list) {
        kill 'TERM', $_;
    }
    defined $server && $server->close ();
    exit;
}

$SIG{'CHLD'} = 'IGNORE';        # avoid zombies
$SIG{'TERM'} = 'done';
$SIG{'INT'} = 'done';

sub usage ($) {
    my ($exit_code) = @_;
    my $STREAM = ($exit_code == 0 ? *STDOUT : *STDERR);
    if ($exit_code != 0) {
        print $STREAM "Try '$ME --help' for more information.\n";
    }
    else {
        print $STREAM <<EOF;
Usage: $ME [OPTIONS] [FILE]...

A simple TCP server.

OPTIONS:
  --mode=echo      echoes back all data received (default mode)
  --mode=sink      writes data received from i-th client into i-th FILE
  --mode=source    sends content of i-th FILE to i-th client
  --pid=F          writes server PID to file F
  --port=N         listens at port N (default to 1986)
  --verbose        explain what is being done

  --help           display this help and exit
  --version        output versoin information and exit
EOF
    }
    exit $exit_code;
}

{
    GetOptions (
        help => sub { usage 0 },
        version => sub { print "$ME version $VERSION\n"; exit },
        'mode=s' => \$mode,
        'pid=s' => \$pid,
        'port=i' => \$port,
        'verbose' => \$verbose,
        ) or usage 1;

    ($mode eq 'echo' or $mode eq 'sink' or $mode eq 'source')
        or (warn "$ME: invalid mode '$mode'\n"), usage 1;

    $server = IO::Socket::INET->new (Proto => 'tcp',
                                     LocalAddr => "localhost:$port",
                                     ReuseAddr => 1)
        or die "$ME: cannot create server socket: $!\n";
    $server->listen ();
    $server->autoflush (1);
    info "server started";

    if (defined $pid) {
        info "writing server PID to '$pid'";
        open (my $pidfile, '>:', $pid) or die "$ME: $pid: $!\n";
        print $pidfile $$;
        close ($pidfile);
    }

    my $n = 0;                  # number of clients
    my $max = scalar @ARGV;     # max clients
    my $client;
    while (1) {
        if ($mode ne 'echo' and $n > $max) {
            last;               # nothing to do
        }

        $n++;
        my $client = $server->accept ();
        my $pid = fork;

        # Parent server code:

        if ($pid != 0) {
            $child_pid_list[$n-1] = $pid;
            $client->close ();
            next;
        }

        # Child server code:

        $SIG{'TERM'} = 'DEFAULT';
        $SIG{'INT'} = 'DEFAULT';
        $server->close ();
        my $peerhost = $client->peerhost ();
        my $peerport = $client->peerport ();
        info "client connected from $peerhost:$peerport";

        my $file = $ARGV[$n-1];
        my $src;
        my $dest;

        if ($mode eq 'echo') {
            $src = $dest = $client;
        }
        elsif ($mode eq 'sink') {
            info "opening sink file '$file'";
            $src = $client;
            open ($dest, '>', $file) or die "$ME: $file: $!\n";
        }
        elsif ($mode eq 'source') {
            info "opening source file '$file'";
            open ($src, '<', $file) or die "$ME: $file: $!\n";
            $dest = $client;
        }
        else {
            die "should not reach here";
        }

        my $buf;
        while (sysread ($src, $buf, 4096) > 0) { # sysread avoid buffering
            info "$buf";
            $dest->write ($buf);
            flush $dest;
        }

        undef $src;
        undef $dest;

        info "client disconnected";
        exit;
    }
    $server->close ();
    done ();
}

# Local Variables:
# mode: perl
# eval: (add-hook 'write-file-functions 'time-stamp)
# time-stamp-start: "my $VERSION = '"
# time-stamp-format: "%:y-%02m-%02d %02H:%02M UTC"
# time-stamp-time-zone: "UTC"
# time-stamp-end: "';"
# End:
