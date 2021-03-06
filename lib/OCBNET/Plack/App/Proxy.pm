################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Plack::App::Proxy;
################################################################################
use parent qw(Plack::App::Proxy);
################################################################################
our $VERSION = "0.0.1";
################################################################################

use strict;
use warnings;

################################################################################

# no implementation yet
# keep for future overloads

################################################################################
# register this basic plack handler
################################################################################

use OCBNET::Plack::Apps qw(register_app);
register_app('proxy', __PACKAGE__);

################################################################################
################################################################################
1;
