#!/usr/bin/env  Rscript
library(Hapi)
library(optparse)
 
option_list <- list(
	 make_option(c("-m", "--matrix"), type="character", default=NULL, 
              help="haplotype matrix outputted by Hapi haplitype reconstruction", metavar="character"),
	make_option(c("-c", "--cent"), type="character", default=NULL, 
              help="Centromere information of reference genome [default= %default]", metavar="character"),
	make_option(c("-n","--SampleNumber"),type="numeric", default=1,
	      help="Specific No. of samples in the input SNP matrix [default= %default]",metavar="numeric")
)
 
opt_parser = OptionParser(option_list=option_list)
opt = parse_args(opt_parser)
if (is.null(opt$matrix)){
  print_help(opt_parser)
  stop("At least one argument must be supplied (input file)", call.=FALSE)
}


hapOutput <- read.table(opt$matrix,header=TRUE,stringsAsFactors=FALSE,check.names=FALSE)
HC <- subset(hapOutput, hap1 !="NA" )
HC <- subset(HC, total>5)
HC <- subset(HC, rate==1)
HC <- subset(HC, confidence!="L")
SK <- read.table(opt$cent,header=TRUE,stringsAsFactors=FALSE)
rownames(SK) <-SK$chr
SK <- SK[,1:3]
samples <-colnames(HC)
Endcolumn<-opt$SampleNumber+5
samples <-samples[c(3,6:Endcolumn)]
for (s in samples){
	y <- numeric(nrow(HC))
	y[HC[[s]] == HC$hap1] <-0
	y[HC[[s]] != HC$hap1] <-1
	HC$tmp <- NULL
	HC$tmp <- y
	test <-HC[,c(1,2,ncol(HC))]
	colnames(test) <-c("chr","pos","hap")
	test2 <- subset(test,HC[[s]] !="NA")
	pdf(paste(s,".pdf",sep = ""))
	adev<-dev.cur()
	png(paste(s,".png",sep = ""), bg = "transparent")
	dev.control("enable")
	print(hapiGameteView(chr = SK, hap = test2))
	dev.copy(which=adev)
	dev.off()
	dev.off()
}
