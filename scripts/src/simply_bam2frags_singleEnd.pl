#Bam file input
#only ouptut fragment(read pair) location, barcode, and counts(duplicates)
#perl simply_bam2pairs.pl  --read_file example_reads.bam  --output_file fragments.pairs.bed --samtools_path SAMTOOLS_PATH

use strict;

#Receive options from command line
use Getopt::Long;

my $samtools_path; 
my $read_file;
my $output_file;
my $output_len_file;

GetOptions( 'read_file=s' => \$read_file  
          , 'output_file=s' => \$output_file 
          , 'samtools_path=s' => \$samtools_path
          );


use File::Basename;

(my $read_file_name,my $read_file_path,my $read_file_suffix) = fileparse($read_file,qr"\..[^.]*$");

if($read_file_suffix ne ".bam")
{
    print("!!!!!!!!!!!!!!!! INPUT ERROR : Unrecognized file type: $read_file_suffix !!!!!!!!!!!!!!!!!!!!\n");
    print("Sorry, I just work with bam  input files. \n");
    die("Make sure that the read file format and file extension is correct. \n");
}


open(READ, "$samtools_path/samtools view $read_file |" ) or die("Cannot read $read_file \n");
open(OUT, ">$output_file" ) or die("Cannot write $output_file \n");

# save the fragment length into a file for calculating insert size
$output_len_file = $output_file.".len";

open(OUT_Len, ">$output_len_file" ) or die("Cannot write $output_len_file \n");

print("Now I am starting to process read file: $read_file .\n");
print "...\n";
my $read_file_counter = 0;

my $btime = time;

my %frags = ();



while(<READ>)
{
   $read_file_counter++;

	 chomp;
	 my $chrom = "XXXXXX";
     my $start = "XXXXXX";
     my $end = "XXXXXX";
     my $seq = "XXXXXX";
     my $len = "XXXXXX";
     my $barcode = "XXXXXX";

	 my @array = split /\t/;
     $seq = $array[9];
     $len = length($seq);
     print OUT_Len $len."\n" ; ## save all fragment length

     $chrom = $array[2];
     ## add 4 bps to the left to adjust the TN5 occupancy
     $start = $array[3] - 4;
     $end = $len + $start - 1;
    

     my @tmp_array = split /:/, $array[0];
	   
	$barcode = $tmp_array[0];
     my $frag_id = $chrom."\t".$start."\t".$end."\t".$barcode;

    if(exists($frags{$frag_id})){

       $frags{$frag_id}++;
       
    }else{
      $frags{$frag_id} = 1;
    }
   
	   
 
  
}#while(<READ>)

close OUT_Len;
close READ;
print("I have read $read_file_counter reads from input read file: $read_file .\n");


print("Now I am writing the output to $output_file .\n");



#foreach my $frag_id (sort keys %frags)
foreach my $frag_id (keys %frags)
{

   print OUT $frag_id."\t".$frags{$frag_id}."\n" ;
}
close OUT;
my $etime = time;
my $elapsed = $etime - $btime;

print("It takes $elapsed seconds totally.\n");

#print(" Now I am sorting the fragment file...\n");

#`sort -k1,1 -k2n,3n $output_file > tmp_frags`;
#`mv tmp_frags $output_file`;

print("Output fragments is in the file $output_file  . \n");






