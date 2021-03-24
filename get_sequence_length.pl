#!/usr/bin/perl

use strict;
use warnings;

my $file=shift;

if($file=~/.gz$/){
	open IN, "gzip -dc $file |" or die $!;
}else{
	open IN, "< $file" or die $!;
}
open OUT,"> $file.length" or die $!;
my %length;
$/='>';<IN>;$/="\n";
while(<IN>){
	chomp;
	my $id=$1 if(/^(\S+)/);
#	$id=~s/\//\_/g;
	$/='>';
	my $seq=<IN>;
	chomp($seq);
	$seq=~s/\s//g;
	my $length=length($seq);
	$/="\n";
	print OUT "$id\t$length\n";
#	$seq=~s/\s*//g;
#	$length{$id}=length($seq);
}
close IN;
close OUT;
