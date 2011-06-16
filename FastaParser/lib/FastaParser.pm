package FastaParser;
use IO::Scalar;
use PerlIO::eol;
use Spreadsheet::SimpleExcel;
use Tie::File::AnyData::Bio::Fasta;
use Dancer ':syntax';

set serializer => 'JSON';

our $VERSION = '0.1';

get '/' => sub {
    template 'index';
};

put qr{/fasta/(csv|xls)} => sub {
    my( $format ) = splat;
    debug $format;

    my $result;

    my $body = request->body;
    defined( $body ) or return;

    # extract the fastas

    my $FASTAS = new IO::Scalar \$body;
    tie my @fastas, 'Tie::File::AnyData::Bio::Fasta', $FASTAS;

    my $extracted;

    foreach my $fasta ( @fastas ) {
        my( $header, $payload ) = split( "\n", $fasta, 2 );
        $payload =~ s/\n//g;

        $extracted->{$header} = $payload;
    }

    close( $FASTAS );

    # now analyze them
    my $stats;
    foreach my $fasta ( keys( %{$extracted} ) ) {
        my $sequence = $extracted->{$fasta};
        if ( defined( $sequence ) ) {
            $stats->{total}++;
        }
        else {
            next;
        }

        my( @positions ) = split( //, $sequence );
        my $cursor = 0;
        while ( @positions ) {
            my $position = shift( @positions );
            push( @{$stats->{positions}->{$cursor}->{$position}}, $fasta );
            $cursor++;
        }
    }

    my( @header ) = ( qw( Position A C T G N Total ) );

    if ( $format eq 'xls' ) {
        $result = Spreadsheet::SimpleExcel->new;

        $result->add_worksheet( 'Results', { -headers => \@header } );
    }
    else {
        $result = join( ',', @header ) . "\n";
    }

    # now summarize them
    foreach my $position ( sort {$a <=> $b } keys ( %{$stats->{positions}} ) ) {
        my( @line ) = $position;
        
        my( $individual ) = ( $stats->{positions}->{$position} );

        my( $a ) = scalar( @{delete( $individual->{a} ) || []} );
        my( $c ) = scalar( @{delete( $individual->{c} ) || []} );
        my( $t ) = scalar( @{delete( $individual->{t} ) || []} );
        my( $g ) = scalar( @{delete( $individual->{g} ) || []} );
        # anything left over?
        my( $n ) = scalar( keys( %{$individual} ) );

        push( @line, sprintf( '%.1f', 100 * ( $a / $stats->{total} ) ) );
        push( @line, sprintf( '%.1f', 100 * ( $c / $stats->{total} ) ) );
        push( @line, sprintf( '%.1f', 100 * ( $t / $stats->{total} ) ) );
        push( @line, sprintf( '%.1f', 100 * ( $g / $stats->{total} ) ) );
        push( @line, sprintf( '%.1f', 100 * ( $n / $stats->{total} ) ) );
        push( @line, sprintf( '%.1f', 100 * ( ( $a + $c + $t + $g + $n ) / $stats->{total} ) ) );

        if ( $format eq 'xls' ) {
            $result->add_row( 'Results', \@line );
        }
        else {
            $result = join( ',', @line ) . "\n";
        }
    }

    # now return the results
    if ( $format eq 'xls' ) {
        return( $result->output );
    }
    else {
        return( $result );
    }
};

true;
