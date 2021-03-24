#!/usr/bin/perl

use strict;
use warnings;

my $cv=shift;
my $cutoff=shift;

open IN,"<$cv" or die $!;
<IN>;
my @data;
while(<IN>){
	my $str=$_;
	chomp;
	my @line=split(/\t/,$_);
	my $span=$line[3]-$line[2]+1;
#	print "$line[0]\t$startChr\t$startPos\t$endPos\t$span\n";
	push @data,[$line[0],$line[1],$line[2],$line[3],$span];
}
close IN;
my $sample=$data[0][0];
my $chr=$data[0][1];
my $start=$data[0][2];
my $end=$data[0][3];
my @tmp; my @clean;
push @tmp,$data[0];
for(my $i=1;$i<@data;$i++){
 #       if($sample eq $data[$i][0] &&  $chr eq $data[$i][1] && ($data[$i][2]-$end+1)<1000000){
  #              push @{$data[$i-1]},"filter";
   #             push @{$data[$i]},"filter";
    #    }
#                $sample=$data[$i][0];
 #               $chr=$data[$i][1];
  #              $end=$data[$i][3];
	if($data[$i][0] eq $tmp[-1][0] && $data[$i][1] eq $tmp[-1][1] && ($data[$i][2]-$tmp[-1][3]+1)<$cutoff){
		push @tmp, $data[$i];
	}else{
		&process_data(\@tmp, \@clean);
		push @tmp, $data[$i];
	}
}
&process_data(\@tmp, \@clean);

for(my $h=0;$h<@clean;$h++){
	if($clean[$h][-1] eq 'filter'){
		print STDERR join("\t",@{$clean[$h]}),"\n";
	}else{
		print join("\t",@{$clean[$h]}),"\n";
	}
}

sub process_data {
	my ($array_A,$array_B)=@_;
	if(@$array_A == 1){
		push @$array_B,$array_A->[0];
		@$array_A=();
	}elsif(@$array_A %2==0){
		for(my $j=0;$j<@$array_A;$j++){
			push @{$array_A->[$j]},"filter";
			push @$array_B, $array_A->[$j];
		}
		@$array_A=();
	}else{
		for(my $k=0;$k<@$array_A;$k++){
			push @{$array_A->[$k]},"filter";
			push @$array_B, $array_A->[$k];
		}
		my $span=$array_A->[-1]->[3]-$array_A->[0]->[2]+1;
		push @$array_B,[$array_A->[0]->[0],$array_A->[0]->[1],$array_A->[0]->[2],$array_A->[-1]->[3],$span,"new"];
		@$array_A=();
	}
}

