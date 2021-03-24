#!/usr/bin/env  Rscript
library(Hapi)
library(HMM)
library(optparse)
 
option_list <- list(
	 make_option(c("-f", "--file"), type="character", default=NULL, 
              help="dataset file name", metavar="character"),
	make_option(c("-o", "--out"), type="character", default="out.txt", 
              help="output file name [default= %default]", metavar="character"),
	make_option(c("-n", "--supportN"), type="numeric", default=3,
		help="select framework SNP that supported by at least N cells [default= %default]", metavar="numeric")
)
 
opt_parser = OptionParser(option_list=option_list)
opt = parse_args(opt_parser)
if (is.null(opt$file)){
  print_help(opt_parser)
  stop("At least one argument must be supplied (input file).n", call.=FALSE)
}

raw <- read.table(opt$file,header=TRUE,stringsAsFactors=FALSE,check.names=FALSE)
head(raw)
rownames(raw) <- raw$POS
hetDa <- raw[,1:4]
ref <- hetDa$REF
alt <- hetDa$ALT
gmtDa <- raw[,-(1:5)]
gmtDa <- base2num(gmt = gmtDa, ref = ref, alt = alt)
head(gmtDa) 
hmm = initHMM(States=c("S","D"), Symbols=c("s","d"), 
            transProbs=matrix(c(0.99999,0.00001,0.00001,0.99999),2),
            emissionProbs=matrix(c(0.99,0.01,0.01,0.99),2), 
            startProbs = c(0.5,0.5))
gmtDa <- hapiFilterError(gmt = gmtDa, hmm = hmm)
gmtFrame <- hapiFrameSelection(gmt = gmtDa, n = opt$supportN)
imputedFrame <- hapiImupte(gmt = gmtFrame, nSPT = 2, allowNA = 0)
summary(imputedFrame)
draftHap <- hapiPhase(gmt = imputedFrame)
summary(draftHap)
head(draftHap)
draftHap[draftHap$cvlink>=1,]
cvCluster <- hapiCVCluster(draftHap = draftHap, cvlink = 2)
cvCluster
filter <- c()
for (i in 1:nrow(cvCluster)) {
    filter <- c(filter, which (rownames(draftHap) >= cvCluster$left[i] & 
        rownames(draftHap) <= cvCluster$right[i]))
}
length(filter)
if (length(filter) > 0) {
    imputedFrame <- imputedFrame[-filter, ]
    draftHap <- hapiPhase(imputedFrame)
} 
finalDraft <- hapiBlockMPR(draftHap = draftHap, gmtFrame = gmtFrame, cvlink = 1)
summary(finalDraft)
head(finalDraft)
consensusHap <- hapiAssemble(draftHap = finalDraft, gmt = gmtDa)
summary(consensusHap)
head(consensusHap)
consensusHap <- hapiAssembleEnd(gmt = gmtDa, draftHap = finalDraft, 
                                consensusHap = consensusHap, k = 300)
hap1 <- sum(consensusHap$hap1==0)
hap2 <- sum(consensusHap$hap1==1)
hap7 <- sum(consensusHap$hap1==7)
max(hap1, hap2)/sum(hap1, hap2)
snp <- which(rownames(hetDa) %in% rownames(consensusHap))
ref <- hetDa$REF[snp]
alt <- hetDa$ALT[snp]
consensusHap <- num2base(hap = consensusHap, ref = ref, alt = alt)
summary(consensusHap)
head(consensusHap)
hapOutput <- data.frame(raw[snp,], consensusHap,check.names=FALSE)
head(hapOutput)
write.table(hapOutput, file =opt$out,row.names=FALSE,sep="\t", quote = FALSE)
