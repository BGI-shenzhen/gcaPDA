# gcaPDA
Gamete cell assisted chromosome-scale phased diploid assembler


## Installation


### Prerequisites
------
Before running gcaPDA, please install the following softwares. </br>

    R(v3.4.3): require packages: optparse, HMM,Hapi, etc.
    FALCON/pb-assembly(falcon-kit 1.4.4): https://github.com/PacificBiosciences/pb-assembly 
    juicer: https://github.com/aidenlab/juicer 
    3d-dna: https://github.com/aidenlab/3d-dna 
    bbmap:  https://jgi.doe.gov/data-and-tools/bbtools/bb-tools-user-guide/bbmap-guide 
    bowtie2 (v2.3.5.1): http://bowtie-bio.sourceforge.net/bowtie2/index.shtml 
    samtools (v1.9): http://www.htslib.org/download 
    bcftools (v1.9):  http://www.htslib.org/download 
    Hapi: https://cran.r-project.org/web/packages/Hapi/ 
    yak: https://github.com/lh3/yak
    hifiasm: https://github.com/chhylp123/hifiasm 
  
## Step by step analysis command  


### Part I. building an initial assembly 

- Run FALCON/pb-assembly(using HiFi reads as input):

      .  /opt/Anaconda/Anaconda2/anaconda2/bin/activate
      source activate pb-assembly
      fc_run fc_run_maize.cfg  (./files/fc_run_maize.cfg)

- Run Juicer and 3d-dna (Hi-C scaffolding)
    
      python juicer/misc/generate_site_positions.py $enzyme  Maize.p_ctg.fa  Maize.p_ctg.fa
      perl get_sequence_length.pl Maize.p_ctg.fa > Maize.p_ctg.fa.size.txt
      juicer.sh -d ./ -s $enzyme -p Maize.p_ctg.fa.size.txt -y Maize.p_ctg.fa_$enzyme.txt -z  Maize.p_ctg.fa  (put your Hi-C FASTQ files under folder ./fastq)
      3d-dna/run-asm-pipeline.sh -m haploid -r 2 Maize.p_ctg.fa merged_nodups.txt (merged_nodups.txt file was generated by juicer.sh)


### Part II. reconstruction of haplotypes


- Gamete cell reads preprossing:
    
      bbmap/bbduk.sh -Xmx3g in=S1_1.fq.gz in2=S2_2.fq.gz out=S1_1.clean.fq.gz  out2=S1_2.clean.fq.gz  ref=BGISEQ.adapter.fa threads=4 ktrim=r k=17 mink=7 hdist=1 tpe tbo qtrim=rl trimq=15 minlength=80

- Building mapping index:

        bowtie2-build initial.ref.fa  initial.ref 
    
- Gamete cell reads mapping (using sample S1 as example):
    
      bowtie2 -p 4 -X 800 --rg-id S1 --rg S1 -x  initial.ref   -1 S1_1.clean.fq.gz -2 S1_2.clean.fq.gz > S1.sam
      samtools sort -@ 4 S1.sam >S1.bam  && samtools index S1.bam
   
 - SNP calling and filtering:
    
       bcftools mpileup -b bam.list  -d 500 -f  initial.ref.fa   -q 10 --ff SECONDARY -a AD,ADF,ADR,DP,SP  -Ob -o maizeF1.bcf
       bcftools call -o maizeF1.call.bcf -Ob -cv -p 0.01 maizeF1.bcf
       bcftools filter -e '%QUAL<20 || INFO/AF1 <0.3 || INFO/AF1 >0.7' -g 5  -Ov maizeF1.call.bcf |grep -v INDEL |awk '$5!~/,/' >maizeF1.filter.vcf
    
- Gamete cell quality control:

      perl SNPStatv2.pl maizeF1.filter.vcf $depth_cutoff >maizeF1.filter.vcf.stat
      Rscript SNPStatPlot.R -f maizeF1.filter.vcf.stat
      identify low quality cells based on missing SNP rate and heterozygous SNP rate
      perl extractAndReformat.pl  maizeF1.filter.vcf 5 >genotype.matrix
      cut -f XX,XX,XX --complement genotype.matrix >genotype.removeLowQ.matrix.txt  (XX,XX refers to column number of failed cells)
      
- Reconstruction of chromosome-scale haplotypes
    
      Rscript --vanilla RunHapi.R -f genotype.removeLowQ.matrix.txt  -o genotype.removeLowQ.matrix.txt.out.txt
      Rscript --vanilla draw.R -m  genotype.removeLowQ.matrix.txt.out.txt   -c [Cent.txt](./files/Cent.txt)

### Part III. partition and normalization of gamete cell


- Parsing haplotype blocks from Hapi result
    
      Rscript --vanilla IdentifyCVv2.R -f genotype.removeLowQ.matrix.txt.out.txt -o cvOutput 
      perl addChr.pl genotype.removeLowQ.matrix.txt.out.txt  cvOutput >cvOutput.chr
      perl process_cv_output.pl  cvOutput.chr  1000000 >cvOutput.chr.clean 2>cvOutput.chr.clean.filtered
      perl CV2PhasedBlock.pl Chr.Len cvOutput.chr.clean  5000000   (it will output files: S1.block, S2.block,...S40.block)
      using sample S1 as an example:
      cut -f $CHROM,$POS,$S1,$hap1,$hap2 genotype.removeLowQ.matrix.txt.out.txt >S1.txt
      perl BlockOrigin.pl S1.block S1.txt (it will output files: S1.block.hap1 and S1.block.hap2)
      
- Extracting gamete reads according to haplotype blocks (using sample S1 as an example):
    
      samtools view -h -L S1.block.hap1 S1.bam | samtools view -h  -bS - >S1.hap1.bam 
      samtools view -h -L S1.block.hap2 S1.bam | samtools view -h  -bS - >S1.hap2.bam

- Merging haplotype reads:
    
      samtools merge -@ 4 -b hap1.bam.list  hap1.merged.bam  
      samtools merge -@ 4 -b hap2.bam.list  hap2.merged.bam
      
- Sorting bam file by read names:
      
      samtools sort -@ 4 -n -o hap1.merged.sortByName.bam  hap1.merged.bam
      samtools sort -@ 4 -n -o hap2.merged.sortByName.bam  hap2.merged.bam
      
- Extracting haplotype reads from bam files:
    
      samtools  fastq  -N  -F 0x900 -@ 4 -1 hap1.read1.fq -2 hap1.read2.fq -s hap1.singleton.fq  hap1.merged.sortByName.bam
      samtools  fastq  -N  -F 0x900 -@ 4 -1 hap2.read1.fq -2 hap2.read2.fq -s hap2.singleton.fq  hap2.merged.sortByName.bam
      rm hap1.merged.bam  hap2.merged.bam hap1.merged.sortByName.bam hap2.merged.sortByName.bam (optional)
      
- Normalization of haplotype reads: 
    
      bbnorm.sh in=hap1.read1.fq in2=hap1.read2.fq out=hap1.40x.read1.fq out2=hap1.40x.read2.fq target=40 prefilter=t -Xmx400g threads=40  tmpdir=./ percentile=25  hist=in.hist.txt histout=out.hist.txt
      bbnorm.sh in=hap2.read1.fq in2=hap2.read2.fq out=hap2.40x.read1.fq out2=hap2.40x.read2.fq target=40 prefilter=t -Xmx400g threads=40  tmpdir=./ percentile=25  hist=in.hist.txt histout=out.hist.txt

### Part IV. generating chromosome-scale phased diploid assembly


- Breaking normalized haplotype reads into k-mers:
    
      yak  count  -b37 -t32 -o hap1.yak <(cat hap1.40x.read1.fq hap1.40x.read2.fq) <(cat hap1.40x.read1.fq hap1.40x.read2.fq)
      yak  count  -b37 -t32 -o hap2.yak <(cat hap2.40x.read1.fq hap2.40x.read2.fq) <(cat hap2.40x.read1.fq hap2.40x.read2.fq)

- Running hifiasm:
    
      hifiasm -t 100 -1 hap1.yak  -2 hap2.yak   -o MaizeF1  simulated.B73.HiFi.gz  simulated.SK.HiFi.gz
      awk '/^S/{print ">"$2;print $3}' MaizeF1.hap1.p_ctg.gfa > MaizeF1.hap1.p_ctg.fa
      awk '/^S/{print ">"$2;print $3}' MaizeF1.hap2.p_ctg.gfa > MaizeF1.hap2.p_ctg.fa
      
- Running Juicer and 3d-DNA (Hi-C scaffolding) as described in Part I.
    
      run juicer and 3d-DNA using MaizeF1.hap1.p_ctg.fa as input
      run juicer and 3d-DNA using MaizeF1.hap2.p_ctg.fa as input
  
## Citation  

To be determined
