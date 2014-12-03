################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::WebServer;
################################################################################
use parent qw(Exporter);
################################################################################
our $VERSION = "0.0.1";
################################################################################

use strict;
use warnings;

################################################################################

# define our functions to be exported
BEGIN { our @EXPORT = qw(register_handler); }

################################################################################

# import shared stuff
use OCBNET::Plack::Apps;
use OCBNET::Plack::Options;

################################################################################
################################################################################

sub new
{
	my ($pkg, $config) = @_;
	my $server = { config => $config };
	return bless $server, $pkg;
}

################################################################################
################################################################################

sub run
{

	my ($server) = @_;

	require Plack::Runner;
	require Plack::Builder;
	require Plack::App::URLMap;
	require Plack::App::Proxy;
	require Plack::App::Directory;

	require OCBNET::Plack::App::File;
	require OCBNET::Plack::App::Echo;
	require OCBNET::Plack::App::Proxy;
	require OCBNET::Plack::App::Directory;

	# modular third party handlers
	my $path = $ENV{'path'};
	require OCBNET::Plack::Filter::SHTML;
	$ENV{'path'} = $path;

	my $config = $server->{'config'};
	my $urlmap = Plack::App::URLMap->new;

	# check for valid mount point
	unless ($config->{'mounts'})
	{ die "no mount points found"; }
	my $mounts = $config->{'mounts'};
	unless (UNIVERSAL::isa($mounts, "ARRAY"))
	{ $mounts = [ $mounts ]; }
	unless (scalar(@{$mounts}))
	{ die "no mount points found"; }

	foreach my $mount (@{$mounts})
	{
		# check for valid arguments
		unless ($mount->{'mount'})
		{ die "invalid mount point"; }
		my $mnt = $mount->{'mount'};
		unless (exists $mount->{'type'})
		{ $mount->{'type'} = 'directory'; }
		my $type = $mount->{'type'};
		unless (exists $apps{$type})
		{ die "invalid mount type: $type"; }
		# store a reference to the server
		$mount->{'server'} = $server;
		# create a new post processor instance
		my $proc = $apps{$type}->new($mount);
		# register app at given mount point
		$urlmap->map($mnt => $proc->to_app);
	}

	my @longopt;
	# create app instance
	my $app = $urlmap->to_app;
	# create a new runner instance
	my $runner = Plack::Runner->new;

	# pass options to server
	foreach my $opt (@options)
	{
		# check and get from config
		next unless $config->{$opt};
		my $val = $config->{$opt};
		# collect all options for plack
		push @longopt, '--' . $opt, $val;
	}
	# pass array options which can occur multiple times
	push @longopt, map { ('-M', $_) } @{$config->{'modules'} || []};
	push @longopt, map { ('-I', $_) } @{$config->{'includes'} || []};
	# now pass the option to plack runner
	$runner->parse_options(@longopt);
	# run should not return anyway
	return $runner->run($app);

}

################################################################################
################################################################################
1;