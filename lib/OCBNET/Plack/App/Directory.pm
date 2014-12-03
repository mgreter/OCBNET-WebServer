################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Plack::App::Directory;
################################################################################
use parent qw(OCBNET::Plack::App::File);
################################################################################
our $VERSION = "0.0.1";
################################################################################

use strict;
use warnings;

################################################################################
# lot of code is copied from Plack::App::Directory
################################################################################

# route some specific method to base implementation
sub should_handle { &Plack::App::Directory::should_handle }
sub return_dir_redirect { &Plack::App::Directory::return_dir_redirect }

################################################################################
use File::Basename qw(dirname basename);
use File::Spec::Functions qw(canonpath);
################################################################################

sub call {

	my($self, $env) = @_;

	# test if some path was set
	unless (exists $self->{'path'})
	{ die "no root for plack server"; }
	# make sure the path is an array
	unless (UNIVERSAL::isa($self->{'path'}, 'ARRAY'))
	{ $self->{'path'} = [ $self->{'path'} ]; }

	# create a new default response
	my $res = [404, [], ["Not Found"]];

	# search inside all given paths
	foreach my $root (@{$self->{'path'}})
	{
		# update some root variables
		local $self->{'root'} = $root;
		$env->{'DOCUMENT_ROOT'} = $root;
		# call our parent (App::File)
		$res = $self->SUPER::call($env);
		# check for a valid response
		last if $res->[0] eq 200;
		# also allow redirects when a
		# directory is missing a slash
		last if $res->[0] eq 301;
	}

	# no longer needed since we error out
	# unless(scalar(@{$self->{'path'}}))
	# { $res = $self->SUPER::call($env); }

	# return response
	return $res;

};

################################################################################
# load required modules
################################################################################

use DirHandle qw();
use HTTP::Date qw();
use Plack::Util qw();
use Plack::MIME qw();
use URI::Escape qw(uri_escape);

################################################################################
# Stolen from rack/directory.rb and then stolen from App/Directory.pm
################################################################################

my $dir_file = <<HEAD;
<tr>
  <td class='name'><a href='%s'>%s</a></td>
  <td class='size'>%s</td>
  <td class='type'>%s</td>
  <td class='mtime'>%s</td>
</tr>
HEAD

my $dir_page = <<PAGE;
<html><head>
  <title>%s</title>
  <meta http-equiv="content-type" content="text/html; charset=utf-8" />
  <style type='text/css'>
body { font-family: verdana; font-size: 14px; }
table { width:100%%; }
.name { text-align:left; }
.size, .mtime { text-align:right; }
.type { width:14em; }
.mtime { width:18em; }
  </style>
</head><body>
<h1>%s</h1>
<hr />
<table>
  <tr>
    <th class='name'>Name</th>
    <th class='size'>Size</th>
    <th class='type'>Type</th>
    <th class='mtime'>Last Modified</th>
  </tr>
%s
</table>
<hr />
</body></html>
PAGE

################################################################################
################################################################################

# helper function to properly escape an url (only escape names)
my $escape_url = sub { join '/', map { uri_escape($_) } split m{/}, $_[0] };

################################################################################
################################################################################

sub serve_path
{

	my($self, $env, $dir, $fullpath) = @_;

	# call parent if we can serve an actual file
	return $self->SUPER::serve_path($env, $dir, $fullpath) if (-f $dir);
	# redirect if directory has no trailing slash
	my $dir_url = $env->{SCRIPT_NAME} . $env->{PATH_INFO};
	return $self->return_dir_redirect($env) if ($dir_url !~ m{/$});

	# test if some path was set
	unless (exists $self->{'path'})
	{ die "no root for plack server"; }
	# make sure the path is an array
	unless (UNIVERSAL::isa($self->{'path'}, 'ARRAY'))
	{ $self->{'path'} = [ $self->{'path'} ]; }

	# accumulated files and directories
	my (%children, @mounts, @dirs, @files);
	# add parent directory only if we are not at root level
	my @top = ([ '../', '../', '', 'directory', '' ]) if $dir_url ne '/';

	# get configuration from server
	# introspect to list mount points
	my $server = $self->{'server'} || {};
	my $config = $server->{'config'} || {};
	my $mounts = $config->{'mounts'} || [];

	foreach my $mount (@{$mounts})
	{
		# get the directory where it is mounted
		my $dirname = dirname $mount->{'mount'};
		next if $dirname eq $mount->{'mount'};
		# add mounts for the current dir
		my $current = canonpath($dir_url);
		my $mounted = canonpath($dirname);
		next if $current ne $mounted;
		# get the mount type
		my $type = $mount->{'type'};
		$type = 'mount' if $type eq 'directory';
		# create the encoded url to access item
		my $basename = basename $mount->{'mount'};
		my $url = $escape_url->($dir_url . $basename);
		# create a new file entry to be rendered
		my $file = [ $url, $basename, '-', $type, '' ];
		# add some additional information for proxy mounts
		$file->[4] = $mount->{'remote'} if ($type eq 'proxy');
		# append slashes since we are directories
		$file->[0] .= '/'; $file->[1] .= '/';
		# push to render
		push @mounts, $file;
	}

	# search inside all given paths
	foreach my $root (@{$self->{'path'}})
	{
		# use the actual root and append path_info
		my $dh = DirHandle->new($root . $env->{PATH_INFO});
		# collect file/dir entries
		next unless defined $dh;
		while (defined(my $ent = $dh->read)) {
			next if $ent eq '.' or $ent eq '..';
			next if exists $children{$ent};
			$children{$ent} = $root;
		}
	}

	# process all entries in children (in sorted order)
	for my $basename (sort { $a cmp $b } keys %children) {

		# create the complete (relative) file path
		my $file = join "/", $children{$basename}, $basename;
		# check if it is a
		my $is_dir = -d $file;
		my @stat = stat _;

		# create a properly escape url
		my $url = $escape_url->($dir_url . $basename);

		# append slashes
		if ($is_dir) {
			$basename .= "/";
			$url      .= "/";
		}

		my $arr = $is_dir ? \@dirs : \@files;
		# create and add file and directory entries to the listening
		my $mime_type = $is_dir ? 'directory' : ( Plack::MIME->mime_type($file) || 'text/plain' );
		push @{$arr}, [ $url, $basename, $stat[7], $mime_type, HTTP::Date::time2str($stat[9]) ];

	}
	# EO each file/dir

	# sort the listening afterwards (otherwise, mounts are on top)
	@dirs = sort { $a->[1] cmp $b->[1] } @dirs if $config->{'sort'};
	@files = sort { $a->[1] cmp $b->[1] } @files if $config->{'sort'};
	@mounts = sort { $a->[1] cmp $b->[1] } @mounts if $config->{'sort'};

	# to the templating and create the final result
	my $path  = Plack::Util::encode_html("Index of " .$dir_url);
	my $page  = sprintf $dir_page, $path, $path, join("\n", map {
		sprintf $dir_file, map Plack::Util::encode_html($_), @{$_};
	} @top, @mounts, @dirs, @files);

	# return a new and successfull response with the file listening
	return [ 200, ['Content-Type' => 'text/html; charset=utf-8'], [ $page ] ];

}
# EO serve_path

################################################################################
# register this basic plack proc
################################################################################

use OCBNET::Plack::Apps qw(register_app);
register_app('directory', __PACKAGE__);

################################################################################
################################################################################
1;