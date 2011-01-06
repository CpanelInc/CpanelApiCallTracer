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
use Cpanel::Logger      ();
use Cpanel::InMemoryFH  ();
use Data::Dumper;

# this version of CustomEventHandler.pm will print Parameters and Response from API calls into /usr/local/cpanel/logs/error_log
# Also required is the modified version of Data::Dumper available in this directory, please see the README file for notes and information
# This utility can be adjusted to ONLY show certain calls by adjusting the commented out line #49

sub event {
    my ( $apiv, $type, $module, $event, $cfgref, $dataref ) = @_;
    # The line below is a filter line that should be uncommented & modified if you are trying to debug
    # a specific API call
    # return 1 if $module ne "email" || $event ne "addpop";
    
    
    # the @ignore array contains modules that are called frequently and can slow down the cPanel UI to a point where it is nearly unusable
    # If you need to debug one of these modules, simply remove it from the below hash.
    my @ignore = ( 'branding', 'getcharset', 'printvar', 'langprint', 'ui', 'magicrevision', 'relinclude', 'relrawinclude' );
    return 1 if grep( /$module/, @ignore ) && $apiv eq '1';



    if ( $type eq 'pre' && $apiv eq '1' ) {
        $Cpanel::api1_traced = 0;
        if ( tie *APIHANDLE, 'Cpanel::InMemoryFH' ) {
            $Cpanel::api1_traced = 1;
            select(APIHANDLE);
        }
        else {
            print STDERR "could not trap STDOUT\n";
        }
    }
    elsif ( $type eq 'post' ) {
        print STDERR "$module:$event\n\n";
        print STDERR 'API:' . $apiv . "\n";
        print STDERR "Parameters:\n\n" . Dumper($cfgref) . "\n";
        
        # output return data
        if ( $apiv eq '1') {
            my $result;
            read(APIHANDLE, $result, 16777216 ) || print STDERR "failed to read from APIHANDLE:\n";
            select(STDOUT);
            print STDERR "Return:\n\n";
            print STDOUT $result;
            print STDERR $result . "\n\n";
            untie *APIHANDLE;
        }
        elsif ( $apiv eq '2' ) {
            print STDERR "Return:\n\n" . Dumper($dataref)
        }
        
        print STDERR "\n--------------------\n";
    }
    return 1;
}

1;
