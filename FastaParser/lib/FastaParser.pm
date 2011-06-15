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

    my $FASTAS = new IO::Scalar \$body;
    tie my @fastas, 'Tie::File::AnyData::Bio::Fasta', $FASTAS;

    foreach my $fasta ( @fastas ) {
        my( $header, $payload ) = split( "\n", $fasta, 2 );
        $payload =~ s/\n//g;

        $result->{$header} = $payload;
    }

    return( $result );
};

true;
