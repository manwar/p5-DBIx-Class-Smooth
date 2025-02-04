package DBIx::Class::Smooth;

use 5.20.0;
use strict;
use warnings;

# ABSTRACT: Sugar for DBIx::Class
# AUTHORITY
our $VERSION = '0.0102';

1;

=pod

=encoding utf-8

=head1 SYNOPSIS

    #* The schema
    package Your::Schema;

    use parent 'DBIx::Class::Smooth::Schema';

    __PACKAGE__->load_namespaces;


    #* The project-specific DBIx::Class::Candy subclass
    package Your::Schema::Result;

    use parent 'DBIx::Class::Smooth::Result';
    sub base {
        return $_[1] || 'Your::Schema::ResultBase';
    }
    sub default_result_namespace {
        return 'Your::Schema::Result';
    }


    #* The project-specific base class for your result sources
    package Your::Schema::ResultBase;

    use parent 'DBIx::Class::Smooth::ResultBase';
    __PACKAGE__->load_components(qw/.../);


    #* A couple of result source definitions
    package Your::Schema::Result::Publisher;

    use Your::Schema::Result -components => [qw/.../];
    use DBIx::Class::Smooth::Fields -all;

    primary id => IntegerField(auto_increment => true);
        col name => VarcharField(size => 100);


    package Your::Schema::Result::Book;

    use Your::Schema::Result -components => [qw/.../];
    use DBIx::Class::Smooth::Fields -all;

    primary id => IntegerField(auto_increment => true);
    belongs Publisher => ForeignKey();
        col isbn => VarcharField(size => 13);
        col title => VarcharField(size => 150);
        col published_date => DateField();
        col language => EnumField(indexed => 1, -list => [qw/english french german spanish/]);


    #* The project-specific DBIx::Class::Candy::ResultSet subclass
    package Your::Schema::ResultSet;

    use parent 'DBIx::Class::Smooth::ResultSet';

    sub base { $_[1] || 'Your::Schema::ResultSetBase' }


    #* The project-specific base class for your resultsets
    package Your::Schema::ResultSetBase;

    use parent 'DBIx::Class::Smooth::ResultSetBase';

    __PACKAGE__->load_components(qw/
        Helper::ResultSet::DateMethods1
        Smooth::Lookup::DateTime
    /);


    #* In the Book resultset
    package Your::Schema::ResultSet::Book;

    use Turf::Schema::ResultSet -components => [qw/.../];
    use DBIx::Class::Smooth::Q;

    sub get_books_by_year($self, $year) {
        return $self->filter(published_date__year => $year);
    }
    sub get_books_by_either_isbn_or_title($self, $isbn, $title) {
        return $self->filter(Q(isbn => $isbn) | Q(title => $title));
    }


    #* Elsewhere, using the Book resultset
    my $books = $schema->Book->get_books_by_year(2018);


=head1 DESCRIPTION

DBIx::Class::Smooth is a sugar layer for L<DBIx::Class>, partially built on top of L<DBIx::Class::Candy> and L<DBIx::Class::Helpers>.

=head1 STATUS

This is experimental, and an early release at that. I'm using this in a couple of non-critical personal projects, so it hasn't seen heavy use. It would not be surprising if there are bad bugs. Also, it's only been tested on MySQL/MariaDB.

More documentation to follow.
