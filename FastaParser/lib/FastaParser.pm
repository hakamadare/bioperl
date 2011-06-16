package FastaParser;
use IO::Scalar;
use PerlIO::eol;
use Tie::File::AnyData::Bio::Fasta;
use Dancer ':syntax';

set serializer => 'JSON';

our $VERSION = '0.1';

get '/' => sub {
    template 'index';
};

put '/fasta' => sub {
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

    # now summarize them
    foreach my $position ( sort {$a <=> $b } keys ( %{$stats->{positions}} ) ) {
        my( @line ) = $position;
        
        my( $individual ) = ( $stats->{positions}->{$position} );
        my( $a ) = defined( $individual->{a} ) ? scalar( @{$individual->{a}} ) : 0;
        my( $c ) = defined( $individual->{c} ) ? scalar( @{$individual->{c}} ) : 0;
        my( $t ) = defined( $individual->{t} ) ? scalar( @{$individual->{t}} ) : 0;
        my( $g ) = defined( $individual->{g} ) ? scalar( @{$individual->{g}} ) : 0;
        my( $n ) = defined( $individual->{n} ) ? scalar( @{$individual->{n}} ) : 0;

        push( @line, sprintf( '%.1f', 100 * ( $a / $stats->{total} ) ) );
        push( @line, sprintf( '%.1f', 100 * ( $c / $stats->{total} ) ) );
        push( @line, sprintf( '%.1f', 100 * ( $t / $stats->{total} ) ) );
        push( @line, sprintf( '%.1f', 100 * ( $g / $stats->{total} ) ) );
        push( @line, sprintf( '%.1f', 100 * ( $n / $stats->{total} ) ) );
        push( @line, sprintf( '%.1f', 100 * ( ( $a + $c + $t + $g + $n ) / $stats->{total} ) ) );

        $result .= join( ',', @line ) . "\n";
    }

    return( $result );
};

true;
