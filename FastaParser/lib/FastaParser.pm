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
    foreach my $position ( sort( @{$stats->{positions}} ) ) {
        my( @line ) = ( $position );
    }

    return( $result );
};

true;
