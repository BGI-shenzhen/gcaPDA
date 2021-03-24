#!/usr/bin/perl

use strict;
use warnings;

my $detail=shift;
my $cv=shift;

open IN,"< $detail" or die $!;
my %Chr;
<IN>;
while(<IN>){
	chomp;
	my @line=split(/\t/,$_);
	$Chr{$line[1]}=$line[0];
}
close IN;
open IN,"< $cv" or die $!;
print "gmt\tchr\tstart\tend\tpos\tres\n";
<IN>;
while(<IN>){
	chomp;	
	my @line=split("\t",$_);
	if($Chr{$line[1]} != $Chr{$line[2] || $line[4]<0}){
#		print STDERR join("\t",@line),"\n";
		next;
	}else{
		print "$line[0]\t$Chr{$line[1]}\t";
		print join("\t",@line[1..$#line]),"\n";
#		print join("\t",@line),"\n";
	}
}
close IN;
