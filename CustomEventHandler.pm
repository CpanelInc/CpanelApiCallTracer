package Cpanel::CustomEventHandler;

# cpanel12 - CustomEventHandler.pm                      Copyright(c) 2008 cPanel, Inc.
#                                                           All rights Reserved.
# copyright@cpanel.net                                         http://cpanel.net
# This code is subject to the cPanel license. Unauthorized copying is prohibited
#
# VERSION 1.0
#

use strict;
use Cpanel::Logger ();
use Data::Dumper;

# this version of CustomEventHandler.pm will throw debug output for API calls into /usr/local/cpanel/logs/error_log
# Also required is the modified version of Data::Dumper available in this directory, please see it's headers for installation
# It can be adjusted to ONLY show certain calls by adjusting the commented out return line

sub event {
    my ( $apiv, $type, $module, $event, $cfgref, $dataref ) = @_;
		# Essential!! removing this line will cause UI glitches in the cPanel interface
    my @ignore = (
        'branding', 'getcharset',    'printvar', 'langprint',
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
            open( APIHANDLE, ">", "/dev/shm/apiout.tmp" );
            select(APIHANDLE);
        }
        if ( $type eq 'post' ) {
            select(STDOUT);
            close(APIHANDLE);
            open( my $apihandle, "<", "/dev/shm/apiout.tmp" );
            print STDERR "-----\noutput\n\n";
            while ( my $line = readline($apihandle) )
            {
                print STDOUT $line;
                print STDERR $line . "\n\n";
            }
        }
    } elsif ($apiv eq '2' && $type eq 'post' ) {
			print STDERR "-----\n\$dataref\n\n" . Dumper($dataref);
		}
		print STDERR "\n--------------------\n";
			return 1;
}

1;
