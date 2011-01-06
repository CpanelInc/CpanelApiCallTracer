package Cpanel::CustomEventHandler;

# Copyright (c) 2011, cPanel, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted provided
# that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this list of conditions and the
#   following disclaimer.
# * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the
#   following disclaimer in the documentation and/or other materials provided with the distribution.
# * Neither the name of the cPanel, Inc. nor the names of its contributors may be used to endorse or promote
#   products derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

use strict;
use Cpanel::Logger ();
use Data::Dumper;

# this version of CustomEventHandler.pm will throw debug output for API calls into /usr/local/cpanel/logs/error_log
# Also required is the modified version of Data::Dumper available in this directory, please see it's headers for installation
# It can be adjusted to ONLY show certain calls by adjusting the commented out line #33

my $out_file = '/dev/shm/apiout.tmp';

sub event {
    my ( $apiv, $type, $module, $event, $cfgref, $dataref ) = @_;

    # Essential!! removing this line will cause UI glitches in the cPanel interface
    my @ignore = (
        'branding', 'getcharset',    'printvar',   'langprint',
        'ui',       'magicrevision', 'relinclude', 'relrawinclude'
    );
    return 1 if grep( /$module/, @ignore ) && $apiv eq '1';
    return 1 if $module eq 'branding';

    ###
    # Filter Line, If you are looking for a specific call, uncommment and modify this
    ###

    #	return 1 if $module ne "email" || $event ne "addpop";

    print STDERR "$module:$event\n";
    print STDERR '$apiv = ' . $apiv . "\n";
    print STDERR '$type = ' . $type . "\n";
    print STDERR "-----\n\$cfgref\n\n" . Dumper($cfgref) . "\n";

    if ( $apiv eq '1' ) {
        if ( $type eq 'pre' ) {
            print STDERR $module . ':' . $event . " ";
            open( APIHANDLE, ">", $out_file );
            select(APIHANDLE);
        }
        if ( $type eq 'post' ) {
            select(STDOUT);
            close(APIHANDLE);
            open( my $apihandle, "<", $outfile );
            print STDERR "-----\noutput\n\n";
            while ( my $line = readline($apihandle) ) {
                print STDOUT $line;
                print STDERR $line . "\n\n";
            }
            close( $apihandle );
            unlink $out_file;
        }
    }
    elsif ( $apiv eq '2' && $type eq 'post' ) {
        print STDERR "-----\n\$dataref\n\n" . Dumper($dataref);
    }
    print STDERR "\n--------------------\n";
    return 1;
}

1;
