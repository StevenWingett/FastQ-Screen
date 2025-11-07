#!/usr/bin/perl


# Setup
use warnings;
use strict;
use File::Basename;
use Data::Dumper;

my $file_F = $ARGV[0];
my $file_R = $ARGV[1];


# Open filehandles
my %read_tracker;   # Stores the IDs of reads
my %category_counter = (
    "Forward_Reads" => 0, 
    "Reverse_Reads" => 0, 
    "Paired_Reads" => 0
    );

print"Note: script assumes FASTQ files are sorted by header\n";
print "Processing $ARGV[0] with $ARGV[1]\n";

print "Recording FASTQ IDs in $ARGV[0]\n";
if ( $file_F =~ /\.gz$/ ) {
    open( IN_F, "gunzip -c \'$file_F\' |" ) or do {
        warn "Can't read $file_F: $!";
        return;
    };
} else {
    open( IN_F, $file_F ) or do {
        warn "Can't read $file_F: $!";
        return;
    };
}

while(<IN_F>){
    chomp;
    my $read_id = $_;
    $read_id = (split /\s+/, $read_id)[0];
    scalar <IN_F>;
    scalar <IN_F>;
    scalar <IN_F>;

    #print("$read_id\n");

    # Check if already present
    if(exists $read_tracker{$read_id}) {
       die "FASTQ ID $read_id present multiple times in $file_F!"; 
    } else {
        $read_tracker{$read_id} = 1;
    }
    $category_counter{"Forward_Reads"}++
}

close IN_F or die "Cannot close filehandle on '$file_F' : $!";

#print Dumper \%read_tracker;


# Process R file
print "Recording FASTQ IDs in $ARGV[0]\n";

if ( $file_R =~ /\.gz$/ ) {
    open( IN_R, "gunzip -c \'$file_R\' |" ) or do {
        warn "Can't read $file_R: $!";
        return;
    };
} else {
    open( IN_R, $file_R ) or do {
        warn "Can't read $file_R: $!";
        return;
    };
}

while(<IN_R>){
    chomp;
    my $read_id = $_;
    $read_id = (split /\s+/, $read_id)[0];
    scalar <IN_R>;
    scalar <IN_R>;
    scalar <IN_R>;

    #print("$read_id\n");

    # Check if already present
    if(exists $read_tracker{$read_id}) {
        if($read_tracker{$read_id} > 1) {
            die "FASTQ ID $read_id present multiple times in $file_R!";
        } else {
            $read_tracker{$read_id}++;
            $category_counter{"Paired_Reads"}++
        }
    }
    $category_counter{"Reverse_Reads"}++
}

close IN_R or die "Cannot close filehandle on '$file_R' : $!";
#print Dumper \%read_tracker;


# Read in files and write to output file

foreach my $file ($file_F, $file_R){
    print "Re-reading $file to extract paired reads\n";

    if ( $file =~ /\.gz$/ ) {
        open( IN, "gunzip -c \'$file\' |" ) or do {
            warn "Can't read $file: $!";
            return;
        };
    } else {
        open( IN, $file ) or do {
            warn "Can't read $file: $!";
            return;
        };
    }

    my $outfile = basename($file) . ".paired.fastq.gz";
    print("Writing paired reads to $outfile\n");
    open( OUT, "| gzip -c - > $outfile" ) or die "Couldn't write to file '$outfile' : $!";

    while(<IN>){
        my $read = $_;
        my $read_id = $read;

        chomp $read_id;
        $read_id = (split /\s+/, $read_id)[0];
        
        $read .= scalar <IN>;
        $read .= scalar <IN>;
        $read .= scalar <IN>;

        #print("$read_id\n");

        # Check if already present
        if(exists $read_tracker{$read_id}) {
            if($read_tracker{$read_id} == 2) {  # Present in both files
                # Write to output file
                print OUT $read;

            }
        }
    }
    close IN or die "Cannot close filehandle on '$file' : $!";
    close OUT or die "Cannot close filehandle on '$outfile' : $!";
}

print "Forward Reads: " . $category_counter{'Forward_Reads'};
print "\nReverse Reads: " . $category_counter{'Reverse_Reads'};
print "\nPaired Reads: " . $category_counter{'Paired_Reads'};

print("\nDone\n")