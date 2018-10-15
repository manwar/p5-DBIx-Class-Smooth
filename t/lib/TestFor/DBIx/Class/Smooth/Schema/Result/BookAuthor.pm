use 5.20.0;
use strict;
use warnings;

package TestFor::DBIx::Class::Smooth::Schema::Result::BookAuthor;

# ABSTRACT: ...
# AUTHORITY
our $VERSION = '0.0001';

use TestFor::DBIx::Class::Smooth::Schema::Result;
use DBIx::Class::Smooth -all;
use experimental qw/postderef signatures/;

primary_belongs Book => IntegerField();
primary_belongs Author => IntegerField();

1;