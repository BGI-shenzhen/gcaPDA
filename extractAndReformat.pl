#!/usr/bin/perl

use strict;
use warnings;

my $vcf=shift;
my $cutoff=shift;
open IN,"< $vcf" or die $!;
while(<IN>){
	next if(/^##/);
	chomp;
	my @line=split(/\t/,$_);
	my $alt_count=0;
	if(/^#CHROM/){
		print "CHROM\t$line[1]\t$line[3]\t$line[4]\t$line[2]\t";
		print join("\t",@line[9..$#line]),"\n";
	}else{
		my $ref=$line[3];
		my $alt=$line[4];
		my $id=$line[0]."_".$line[1];
		for(my $i=9;$i<@line;$i++){
			my @tmp=split(/:/,$line[$i]);
			if($tmp[2] <5 || $tmp[2] >100 || $tmp[0] eq '0/1'){
				$line[$i]="NA";
			}elsif($tmp[0] eq '0/0'){
				$line[$i]=$ref;
			}elsif($tmp[0] eq '1/1'){
				$line[$i]=$alt;
				$alt_count++;
			}else{
				print STDERR "$line[$i]\n";
			}
		}
		if($alt_count>$cutoff){
			print "$line[0]\t$line[1]\t$line[3]\t$line[4]\t$id\t";
			print join("\t",@line[9..$#line]),"\n";
		}
	}
}
close IN;
