################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Plack::Filter::SHTML;
################################################################################
our $VERSION = "0.0.1";
################################################################################

# helper function
sub new
{

	my $cgi;

	# load when needed
	if (eval { require OCBNET::CGI::SHTML; })
	{ $cgi = OCBNET::CGI::SHTML->new; }
	elsif (eval { require CGI::SHTML; })
	{ $cgi = CGI::SHTML->new; }

	# get input arguments
	my($pkg, $self, $env) = @_;

	# content filter
	return sub {

		# check for valid chunk
		return unless defined $_[0];
		# re-create cgi environment
		local %ENV = (%ENV, %{$env});
		# call to parse fragments
		$cgi->{'_self'} = $self;
		$cgi->{'_env'} = $env;
		$cgi->parse_shtml($_[0]);

	};
	# EO content filter

}
# EO new

################################################################################
# register this basic plack filter
################################################################################

my $mime_re = qr{^(?:text/|application/s?h?tml?\z)};
use OCBNET::Plack::Filter qw(register_filter);
register_filter($mime_re, __PACKAGE__);

################################################################################
################################################################################
1;
