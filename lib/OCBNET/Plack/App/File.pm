################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Plack::App::File;
################################################################################
use parent qw(Plack::App::File);
################################################################################
our $VERSION = "0.0.1";
################################################################################

use strict;
use warnings;

################################################################################
# import shared stuff
################################################################################
use OCBNET::Plack::Filter;
################################################################################

################################################################################
# invoked by App::Directory
################################################################################

sub call
{

	my ($self, $env) = @_;

	# implementing a post processing middleware
	return $self->response_cb($self->SUPER::call($env), sub
	{

		my $res = shift;

		# get the content-type from headers
		my $headers = Plack::Util::headers($res->[1]);
		my $content_type = $headers->get('Content-Type') || '';

		# process handlers in order
		foreach my $filter (@filters)
		{
			# match against the stored regex
			# handler must return a sub reference
			if ($content_type =~ m/$filter->[0]/)
			{ return $filter->[1]->new($self, $env) }
		}

		# explicitly
		return;

	});
	# EO response_cb

}
# EO call

################################################################################
# register this basic plack handler
################################################################################

use OCBNET::Plack::Apps qw(register_app);
register_app('file', __PACKAGE__);

################################################################################
################################################################################
1;
