
use strict;
use Getopt::Long::Descriptive;
use Data::Dumper;
use JSON::XS;

=head1 NAME

ws-autometa-<type>

=head1 SYNOPSIS

ws-autometa-<type> <directory>

=head1 DESCRIPTION

Load a <type> object, compute auto metadata, and save to file

=head1 COMMAND-LINE OPTIONS

ws-autometa-<type> [-h] [long options...]
	-h --help   Show this usage message
	
=cut

my @options = (
	       ["help|h", "Show this usage message"]
	      );

my($opt, $usage) = describe_options("%c %o",
				    @options);

print($usage->text), exit if $opt->help;

my $directory = $ARGV[0];

my $JSON = JSON::XS->new->utf8(1);
open (my $fh,"<",$directory."/object.txt");
my $data;
while (my $line = <$fh>) {
	$data .= $line;	
}
close($fh);

my $metadata = {};
#*******************************************************************
#Start type specific code to generate automated metadata
#*******************************************************************
#You data object is loaded as text in "$data"
$data = $JSON->decode($data);
$metadata->{genome_id} = $data->{id};
$metadata->{scientific_name} = $data->{scientific_name};
$metadata->{domain} = $data->{domain};
$metadata->{dna_size} = $data->{dna_size};
$metadata->{num_contigs} = $data->{num_contigs};
$metadata->{gc_content} = $data->{gc_content};
$metadata->{taxonomy} = $data->{taxonomy};
$metadata->{num_features} = @{$data->{features}};
#*******************************************************************
#End type specific code to generate automated metadata
#*******************************************************************
open (my $fhh,">",$directory."/meta.json");
$metadata = $JSON->encode($metadata);	
print $fhh $metadata;
close($fhh);
