#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use File::Basename;

use Data::Dumper;

###########################################################################
###########################################################################
##                                                                       ##
## Copyright 2021, Simon Andrews    (simon.andrews@babraham.ac.uk)       ##
##                 Steven Wingett   (steven.wingett@babraham.ac.uk)      ##
##                 Felix Krueger    (felix.krueger@babraham.ac.uk)       ##
##                 Mark Fiers       (Plant & Food Research, NZ)          ##
##                                                                       ##
## This program is free software: you can redistribute it and/or modify  ##
## it under the terms of the GNU General Public License as published by  ##
## the Free Software Foundation, either version 3 of the License, or     ##
## (at your option) any later version.                                   ##
##                                                                       ##
## This program is distributed in the hope that it will be useful,       ##
## but WITHOUT ANY WARRANTY; without even the implied warranty of        ##
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         ##
## GNU General Public License for more details.                          ##
##                                                                       ##
## You should have received a copy of the GNU General Public License     ##
## along with this program.  If not, see <http://www.gnu.org/licenses/>. ##
###########################################################################
###########################################################################


##########################################################
#Check arguments ok

my %config;
my $config_result = GetOptions(
    "help" => \$config{help},
    "zip" => \$config{zip}
);
die "Could not parse options" unless ($config_result);

if ($config{help}) {
    print <DATA>;
    exit(0);
}

unless (@ARGV) {
    warn "Please specify files to process.\n";
    print <DATA>;
    exit(1);
}

#Pass file names as command-line arguments
my @files = deduplicate_array(@ARGV);

#Process each file in turn
foreach my $file (@files) {
    
    my $outfile = basename($file);
	$outfile =~ s/\.gz$//;
	$outfile =~ s/\.(txt|seq|fastq|fq)$//i;
	$outfile .= "_tags_removed.fastq";
	$outfile .= '.gz' if ($config{zip});

   if ($config{zip}) {    #Declared outside of subroutine
        open( OUT, "| gzip -c - > $outfile" ) or die "Couldn't write to file '$outfile' : $!";
    } else {
        open( OUT, ">$outfile" ) or die "Could not write to '$outfile' : $!";
    }

    #Process File
    print "Processing file: '$file'\n";
    my $fh = cleverOpen($file); 
     
    while(<$fh>){
        my $header = $_;
        chomp $header;

        unless($header =~ /^@/){
            warn "Not valid FASTQ format header:\n";
            warn "$header\n";
            die "Please check input FASTQ file $file.\n";
        }

        my @header_elements = split(/#/, $header);
        if(scalar @header_elements > 1){   #Only remove if there is a # symbol 
            pop @header_elements;
        }
        $header = join('#', @header_elements);

        print OUT "$header\n";
        print OUT scalar <$fh>;
        print OUT scalar <$fh>;
        print OUT scalar <$fh>;
    }

    close $fh or die "Could not close filehandle on '$file' : $!";
    close OUT or die "Could not close filehandle on '$outfile' : $!";
}

print "Done\n";

exit (0);



##########################################################
# Subroutines
##########################################################


#######################
##Subroutine "cleverOpen":
##Opens a file with a filhandle suitable for the file extension
sub cleverOpen{
  my $file  = shift;
  my $fh;
  
	if( $file =~ /\.bam$/){
		open( $fh, "samtools view -h $file |" ) or die "Couldn't read '$file' : $!";  
	}elsif ($file =~ /\.gz$/){
		open ($fh,"zcat $file |") or die "Couldn't read $file : $!";
	} else {
		open ($fh, $file) or die "Could not read $file: $!";
    }
  return $fh;
}


###############################################################
#Sub: deduplicate_array
#Takes and array and returns the array with duplicates removed
#(keeping 1 copy of each unique entry).
sub deduplicate_array {
    my @array = @_;
    my %uniques;

    foreach (@array) {
        $uniques{$_} = '';
    }
    my @uniques_array = keys %uniques;
    return @uniques_array;
}


__DATA__

Remove FastQ Screen tags from FASTQ files

SYNOPSIS

remove_tags.pl [OPTIONS]... [FASTQ FILE]...

FUNCTION

FastQ Screen filtering adds tags to FASTQ read
headers, denoting the genome or genomes to which
a given reads maps. These tags may need to be
removed for subsequent analysis (e.g. removing 
UMI duplicates in which the UMI sequence should
be at the end of the FASTQ read header).

COMMAND LINE OPTIONS

--help           Print program help and exit
--zip            Gzip output
