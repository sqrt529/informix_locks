#!/usr/bin/perl
# informix_locks.pl - Prints usernames from users which are holding a lock in a table
#
# Copyright (C) 2010 Joachim "Joe" Stiegler <blablabla@trullowitsch.de>
# 
# This program is free software; you can redistribute it and/or modify it under the terms
# of the GNU General Public License as published by the Free Software Foundation; either
# version 3 of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with this program;
# if not, see <http://www.gnu.org/licenses/>.
#
# --
# 
# Version: 1.0 - 2010-10-13

use warnings;
use strict;
use Getopt::Std;

our ($opt_i, $opt_n, $opt_t);

sub usage {
    print "Usage: $0 -i INFORMIXSERVER -n TABLENAME -t TYPE\n";
    exit (1);
}

if (!(getopts("i:n:t:"))) {
    usage();
}
elsif ( (!defined($opt_i)) || (!defined($opt_n)) || (!defined($opt_t)) ) {
    usage();
}
else {
    $ENV{"INFORMIXSERVER"} = $opt_i;
    $ENV{"INFORMIXSHMBASE"} = 0;
    $ENV{"INFORMIXDIR"} = "/opt/IBM/informix";
    $ENV{"PATH"} = $ENV{"PATH"}.":".$ENV{"INFORMIXDIR"}."/bin";

	my @input = `echo "select owner from syslocks where tabname='$opt_n' and type='$opt_t';" | dbaccess sysmaster 2>/dev/null`;
	my @sessions;

	foreach my $sessid (@input) {
		$sessid =~ s/^\s+|\s+$//g;
		next if ($sessid =~ /^$|Database selected|Database closed|owner|retrieved/i);
		if ($sessid =~ /^[0-9].*$/) {
			push @sessions, $sessid;
		}
	}

	my @oninput = `onstat -u`;
	my @usernames;
	my @lockingusers;
	
	foreach my $line (@oninput) {
		next if ($line =~ /^$|^[a-z]|[a-z]$/);
		my @current = split(' ', $line);
		push @usernames, ($current[2], $current[3]);
	}

	my(%mask, @results);
	$results[$_] = [] foreach (0 .. 3);

	foreach my $element (@sessions) {
		$mask{$element} |= 1
	}

	foreach my $element (@usernames) {
		$mask{$element} |= 2
	}

	foreach my $element (keys %mask) {
	    push @{$results[0]}, $element."\n";
	    push @{$results[$mask{$element}]}, $element."\n";
	}

	foreach my $result (@{$results[3]}) {
		for (my $i=0; $i <= scalar(@usernames) -1; $i+=2) {
			if ($usernames[$i] =~ /[^\D]$/) {
				if ($result == $usernames[$i]) {
					push @lockingusers, $usernames[$i+1];
				}
			}
		}
	}

	foreach my $luser (@lockingusers) {
		my ($name,$passwd,$uid,$gid,$quota,$comment,$gcos,$dir,$shell,$expire) = getpwnam($luser);
		print "$name ($comment)\n"; 
	}
}
