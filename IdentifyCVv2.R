#!/Assemble/local/softwares/R/R-3.4.3/bin/Rscript
library(Hapi)
library(HMM)
library(optparse)
 
option_list <- list(
	 make_option(c("-f", "--file"), type="character", default=NULL, 
              help="input file name", metavar="character"),
	make_option(c("-o", "--out"), type="character", default="out.txt", 
              help="output file name [default= %default]", metavar="character")
)
 
opt_parser = OptionParser(option_list=option_list)
opt = parse_args(opt_parser)
if (is.null(opt$file)){
  print_help(opt_parser)
  stop("At least one argument must be supplied (input file).n", call.=FALSE)
}

hapOutput <- read.table(opt$file,header=TRUE,stringsAsFactors=FALSE,check.names=FALSE)
HC <- subset(hapOutput, hap1 !="NA" )
HC <- subset(HC, total>5)
HC <- subset(HC, rate==1)
HC <- subset(HC, confidence!="L")
ncolumn <- ncol(HC)
h1 <-ncolumn-4
h2 <-ncolumn-3
SampleEndCol <-ncolumn-5
hap <- HC[,h1:h2]
gmt <- HC[,6:SampleEndCol]
rownames(gmt)=HC$POS
rownames(hap)=HC$POS
cvOutput <- hapiIdentifyCV(hap = hap, gmt = gmt)
write.table(cvOutput,file=opt$out,sep="\t",quote=FALSE ,row.names=FALSE)
