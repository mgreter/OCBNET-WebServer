################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Plack::App::Echo;
################################################################################
use parent qw(Plack::Component);
################################################################################
our $VERSION = "0.0.1";
################################################################################

use strict;
use warnings;

################################################################################
# echo request and env variables
################################################################################

sub call
{

	# load when needed
	require Data::Dumper;

	# psgi environment
	my ($self, $env) = @_;
	# get a request object from psgi
	my $req = Plack::Request->new($env);

	return [ '200',
		[ 'Content-Type' => 'text/plain' ],
		[ Data::Dumper::Dumper($req) ],
	];

}

################################################################################
# register this basic plack proc
################################################################################

use OCBNET::Plack::Apps qw(register_app);
register_app('echo', __PACKAGE__);

################################################################################
################################################################################
1;