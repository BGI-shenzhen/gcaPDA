#!/usr/bin/perl

use strict;

my $file=shift;
my $DP_cutoff=shift;

open IN,"< $file" or die $!;

my @array;
while(<IN>){
	next if(/^##/);
	chomp;
	my @line=split(/\t/,$_);
	if(/^#CHROM/){
		for(my $i=9;$i<@line;$i++){
			push @array,[$line[$i],0,0,0,0];
			# Sample, Missing, HomoRef, Heter, HomoAlt
		}
	}else{
		for(my $j=9;$j<@line;$j++){
			my @tmp=split(/:/,$line[$j]);
			if($tmp[2] <5){
				$array[$j-9][1]++;  # Define as missing if DP <5
			}else{
				if($tmp[0] eq '0/0'){
					$array[$j-9][2]++;
				}elsif($tmp[0] eq '0/1'){
					$array[$j-9][3]++;
				}elsif($tmp[0] eq '1/1'){
					$array[$j-9][4]++;
				}
			}
		}
	}
}
close IN;
print "Sample\tMissing\tHomoRef\tHeter\tHomoAlt\tTotal_loci\tTotal_call\tHeter_rate_a\tHeter_rate_b\tMissing_rate\n";
for(my $k=0;$k<@array;$k++){
	print join("\t",@{$array[$k]});
	my $total=$array[$k][1]+$array[$k][2]+$array[$k][3]+$array[$k][4];
	my $total_call=$array[$k][2]+$array[$k][3]+$array[$k][4];
	my $Heter_rate_a=($array[$k][3]/$total)*100;
	$Heter_rate_a=sprintf("%.2f",$Heter_rate_a);
	my $Heter_rate_b=($array[$k][3]/$total_call)*100;
	$Heter_rate_b=sprintf("%.2f",$Heter_rate_b);
	my $Missing_rate=($array[$k][1]/$total)*100;
	$Missing_rate=sprintf("%.2f",$Missing_rate);
	print "\t$total\t$total_call\t$Heter_rate_a\t$Heter_rate_b\t$Missing_rate\n";
}
