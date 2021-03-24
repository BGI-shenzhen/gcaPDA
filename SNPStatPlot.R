#!/usr/bin/env  Rscript
library(optparse)
option_list <- list(
	 make_option(c("-f", "--file"), type="character", default=NULL,
              help="dataset file name", metavar="character"),
	make_option(c("-m", "--Het_cutoff"), type="numeric", default=5,
		help="Heterozygous SNP rate should lower than this value [default= %default]", metavar="numeric"),
	make_option(c("-l", "--Missing_lower_limit"), type="numeric", default=30,
		help="SNP missing rate should be higher than this value [default= %default]", metavar="numeric"),
	make_option(c("-u", "--Missing_upper_limit"), type="numeric", default=70,
		help="SNP missing rate should be lower than this value [default= %default]", metavar="numeric")
)
opt_parser = OptionParser(option_list=option_list)
opt = parse_args(opt_parser)
if (is.null(opt$file)){
  print_help(opt_parser)
  stop("At least one argument must be supplied (input file).n", call.=FALSE)
}
data <- read.table(opt$file,header=TRUE,stringsAsFactors=FALSE,check.names=FALSE)
png(paste(opt$file,".heter.png",sep=""),res=300,width=2400,height=1000)
plot(rownames(data),data$Heter_rate_b,ylab="Heterozygous rate (%)",xlab="",xaxt="n",cex=0.5,col="blue")+abline(h=opt$Het_cutoff,col="red")
axis(1,at=rownames(data),labels=data$Sample,las=2)
dev.off()
png(paste(opt$file,".missing.png",sep=""),res=300,width=2400,height=1500)
plot(rownames(data),data$Missing_rate,ylab="Missing rate (%)",xlab="",xaxt="n",cex=0.5,col="blue")+abline(h=opt$Missing_lower_limit,col="red")+abline(h=opt$Missing_upper_limit,col="red")
axis(1,at=rownames(data),labels=data$Sample,las=2)
dev.off()
