#!/usr/bin/perl

use strict;
use warnings;

my $ChrLen=shift;
my $cvList=shift;
my $block_length_cutoff=shift;
my $outdir=shift;

open IN,"< $ChrLen" or die $!;
my %Len;
while(<IN>){
	chomp;
	my @line=split(/\t/,$_);
	$Len{$line[0]}=$line[1];
}
close IN;
open IN,"< $cvList" or die $!;
my %data;
while(<IN>){
	chomp;
	my @line=split(/\t/,$_);
#	$line[0]=~s/\./-/g;
	push @{$data{$line[0]}{$line[1]}},[$line[2],$line[3]];
}
close IN;
my @array;
foreach my $key(keys %data){
	foreach my $chr(keys %Len){
		if(! exists $data{$key}{$chr}){
			push @array,[$chr,1,$Len{$chr}];
		}else{
			my @tmp_array=sort{$a->[0] <=> $b->[0]} @{$data{$key}{$chr}};
			my @blocks;
			for(my $i=0;$i<@tmp_array;$i++){
				push @blocks, $tmp_array[$i][0];
				push @blocks, $tmp_array[$i][1];
			}
			unshift @blocks, 1;
			push @blocks, $Len{$chr};
			for(my $j=0;$j<@blocks;$j+=2){
				push @array, [$chr, $blocks[$j],$blocks[$j+1]] if(($blocks[$j+1]-$blocks[$j]+1)>$block_length_cutoff);
			}
		}
	}
	@array=sort{$a->[0] <=> $b->[0] or $a->[1] <=> $b->[1]} @array;
	open TMP,"> $outdir/$key.block" or die $!;
	for(my $k=0;$k<@array;$k++){
		print TMP join("\t",@{$array[$k]}),"\n";
	}
	close TMP;
	@array=();
}
