use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0100';

use Carp qw/croak/;
use List::Util qw/uniq/;
use List::SomeUtils qw/any/;
use boolean;
use Sub::Exporter::Progressive -setup => {
    exports => [qw/
        true
        false
        Relationship
        ForeignKey
        BitField
        TinyIntField
        SmallIntField
        MediumIntField
        IntegerField
        BigIntField
        SerialField
        BooleanField
        NumericField
        NonNumericField
        DecimalField
        FloatField
        DoubleField
        VarcharField
        CharField
        VarbinaryField
        BinaryField
        TinyTextField
        TextField
        MediumTextField
        LongTextField
        TinyBlobField
        BlobField
        MediumBlobField
        LongBlobField
        EnumField
        DateField
        DateTimeField
        TimestampField
        TimeField
        YearField
    /],
};

use experimental qw/postderef signatures/;

sub merge($first, $second) {
    my $merged = do_merge($first, $second);

    if(!exists $merged->{'extra'}) {
        $merged->{'extra'} = {};
    }
    $merged->{'_smooth'} = {};

    for my $key (keys $merged->%*) {
        if($key =~ m{^-(.*)}) {
            my $clean_key = $1;
            $merged->{'extra'}{ $clean_key } = delete $merged->{ $key };
        }
        elsif($key eq 'many') {
            $merged->{'_smooth'}{'has_many'} = delete $merged->{'many'} || [];
        }
        elsif($key eq 'might') {
            $merged->{'_smooth'}{'might_have'} = delete $merged->{'might'} || [];
        }
        elsif($key eq 'one') {
            $merged->{'_smooth'}{'has_one'} = delete $merged->{'one'} || [];
        }
        elsif($key eq 'across') {
            my $acrosses = delete $merged->{'across'};
            for (my $i = 0; $i < scalar $acrosses->@*; ++$i) {
                my $from = $acrosses->[$i];
                my $to = $acrosses->[$i + 1];
                $merged->{'_smooth'}{'across'}{ $from }{ $to } = 1;
            }
        }
    }

    my %alias = (
        nullable => 'is_nullable',
        auto_increment => 'is_auto_increment',
        foreign_key => 'is_foreign_key',
        default => 'default_value',
    );

    for my $alias (keys %alias) {
        if(exists $merged->{ $alias }) {
            my $actual = $alias{ $alias };
            $merged->{ $actual } = delete $merged->{ $alias };
        }
    }

    if(exists $merged->{'default_sql'}) {
        if(!defined $merged->{'default_sql'}) {
            delete $merged->{'default_sql'};
            $merged->{'default_value'} = \'NULL';
        }
        else {
            my $default_sql = delete $merged->{'default_sql'};
            $merged->{'default_value'} = \$default_sql;
        }
    }

    if(!scalar keys $merged->{'_smooth'}->%*) {
        delete $merged->{'_smooth'};
    }
    if(!scalar keys $merged->{'extra'}->%*) {
        delete $merged->{'extra'};
    }
    return $merged;
}

sub do_merge($first, $second) {
    my $merged = {};
    for my $key (uniq (keys %{ $first }, keys %{ $second })) {
        if(exists $first->{ $key } && !exists $second->{ $key }) {
            $merged->{ $key } = $first->{ $key };
        }
        elsif(!exists $first->{ $key } && exists $second->{ $key }) {
            $merged->{ $key } = $second->{ $key };
        }
        else {
            if(ref $first->{ $key } ne 'HASH' && $second->{ $key } ne 'HASH') {
                $merged->{ $key } = $first->{ $key };
            }
            else {
                $merged->{ $key } = do_merge($first->{ $key }, $second->{ $key });
            }
        }
    }

    return $merged;
}

# this can only be used in the best case, where we can lift the definition from the primary key it points to
# and also does belongs_to<->has_many relationships
sub ForeignKey(%settings) {
    # 'sql' is the attr to the relationship
    # 'related_name' is the name of the inverse relationship, set to undef to skip creation
    # 'related_sql' is the attr to the inverse relationship
    my @approved_keys = qw/nullable indexed sql related_name related_sql/;
    my @keys_in_settings = keys %settings;

    KEY:
    for my $key (@keys_in_settings) {
        next KEY if any { $key eq $_ } @approved_keys;
        delete $settings{ $key };
    }

    return merge { _smooth_foreign_key => 1 }, \%settings;
}


# data types - integers
sub _integer_type($type, $settings = {}) {
    return merge { data_type => $type, is_numeric => 1 }, $settings;
}

sub BitField(%settings) {
    return _integer_type(bit => \%settings);
}
sub TinyIntField(%settings) {
    return _integer_type(tinyint => \%settings);
}
sub SmallIntField(%settings) {
    return _integer_type(smallint => \%settings);
}
sub MediumIntField(%settings) {
    return _integer_type(mediumint => \%settings);
}
sub IntegerField(%settings) {
    return _integer_type(integer => \%settings);
}
sub BigIntField(%settings) {
    return _integer_type(bigint => \%settings);
}
sub SerialField(%settings) {
    return _integer_type(serial => \%settings);
}
sub BooleanField(%settings) {
    return _integer_type(boolean => \%settings);
}
# / integers

sub NumericField(%settings) {
    return merge { is_numeric => 1 }, \%settings;
}
sub NonNumericField(%settings) {
    return merge { is_numeric => 0 }, \%settings;
}


# data types - other numericals
sub DecimalField(%settings) {
    return _float_and_double(decimal => \%settings);
}

sub _float_and_double($type, $settings = {}) {
    return merge { data_type => $type, is_numeric => 1 }, $settings;
}
sub FloatField(%settings)  {
    return _float_and_double(float => \%settings);
}
sub DoubleField(%settings) {
    return _float_and_double(double => \%settings);
}

# data types - strings
sub _charvar($type, $settings) {
    return merge { data_type => $type, is_numeric => 0 }, $settings;
}
sub VarcharField(%settings) {
    return _charvar(varchar => \%settings);
}
sub CharField(%settings) {
    return _charvar(char => \%settings);
}
sub VarbinaryField(%settings) {
    return _charvar(varbinary => \%settings);
}
sub BinaryField(%settings) {
    return _charvar(binary => \%settings);
}

sub _blobtext($text, $settings) {
    return merge { data_type => shift, is_numeric => 0 }, $settings;
}
sub TinyTextField(%settings) {
    return _blobtext(tinytext => \%settings);
}
sub TextField(%settings) {
    return _blobtext(text => \%settings);
}
sub MediumTextField(%settings) {
    return _blobtext(mediumtext => \%settings);
}
sub LongTextField(%settings) {
    return _blobtext(longtext => \%settings);
}
sub TinyBlobField(%settings) {
    return _blobtext(tinyblob => \%settings);
}
sub BlobField(%settings) {
    return _blobtext(blob => \%settings);
}
sub MediumBlobField(%settings) {
    return _blobtext(mediumblob => \%settings);
}
sub LongBlobField(%settings) {
    return _blobtext(longblob => \%settings);
}

sub EnumField(%settings) {
    if(exists $settings{'extra'} && exists $settings{'extra'}{'list'}) {
        # all good
    }
    elsif(exists $settings{'-list'}) {
        if(exists $settings{'extra'}) {
            $settings{'extra'}{'list'} = delete $settings{'list'};
        }
        else {
            $settings{'extra'} = { list => delete $settings{'list'} };
        }
    }
    else {
        croak qq{'enum' expects '-list => [qw/the possible values/]' or 'extra => { list => [qw/the possible values/] }'};
    }
    return merge { data_type => 'enum', is_numeric => 0 }, \%settings;
}

# data types - dates and times
sub _dates_and_times($type, $settings) {
    return merge { data_type => shift, is_numeric => 0 }, $settings;
}
sub DateField(%settings) {
    return _dates_and_times(date => \%settings);
}
sub DateTimeField(%settings) {
    return _dates_and_times(datetime => \%settings);
}
sub TimestampField(%settings) {
    return _dates_and_times(timestamp => \%settings);
}
sub TimeField(%settings) {
    return _dates_and_times(time => \%settings);
}
sub YearField(%settings) {
    return _dates_and_times(year => \%settings);
}

1;

__END__

=pod

=head1 SYNOPSIS

    use DBIx::Class::Smooth;

=head1 DESCRIPTION

DBIx::Class::Smooth is ...

=head1 SEE ALSO

=cut
