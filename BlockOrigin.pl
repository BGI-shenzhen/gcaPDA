#!/usr/bin/perl

use strict;
use warnings;

my $blockList=shift;
my $genotype=shift;
my $out1=shift;
my $out2=shift;

open IN,"< $blockList" or die $!;
my %data;
while(<IN>){
	chomp;
	my @line=split(/\t/,$_);
	push @{$data{$line[0]}},[$line[1],$line[2],0,0];
}
close IN;
open IN,"< $genotype" or die $!;
<IN>;
while(<IN>){
	chomp;
	my @line=split(/\t/,$_);
	next if($line[2] eq 'NA');
	next if($line[3] eq 'NA' or $line[4] eq 'NA');
	for(my $i=0;$i<@{$data{$line[0]}};$i++){
		if($line[1] >=$data{$line[0]}[$i][0] && $line[1] <=$data{$line[0]}[$i][1]){
			if($line[2] eq $line[3]){
				$data{$line[0]}[$i][2]++;
			}elsif($line[2] eq $line[4]){
				$data{$line[0]}[$i][3]++;
			}else{
				print STDERR join("\t",@line),"\n";
			}
		}
		next;
	}
}
close IN;
#open OUT1, "> $blockList.hap1" or die $!;
open OUT1, ">$out1" or die $!;
#open OUT2, "> $blockList.hap2" or die $!;
open OUT2, "> $out2" or die $!;
foreach my $key(sort {$a<=>$b} keys %data){
	my @array=@{$data{$key}};
	for(my $k=0;$k<@array;$k++){
		if($array[$k][2]>$array[$k][3]){
			print OUT1 "chr$key\t";
			print OUT1 join("\t",@{$array[$k]}),"\n";
		}else{
			print OUT2 "chr$key\t";
			print OUT2 join("\t",@{$array[$k]}),"\n";
		}
	}	
}
close OUT1;
close OUT2;
