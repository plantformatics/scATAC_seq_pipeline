setwd("~/Desktop/sapelo2/single_cell/ATACseq/v2/bulk_alignment/assignBarCodes/")

# load libraries
library(mclust)
library(dplyr)

# load function

# load data
a <- read.table("barcode_clean_counts.txt")

# process
a$log10norm <- log10(a$V2)
a$call <- ifelse(a$log10norm >= log10(500), "nuclei", "background")
a$cumulative <- cumsum(a$log10norm)


# plot initial distributions
a$uniqueBC <- log10(seq(1:nrow(a)))
plot(a$uniqueBC,a$log10norm, lwd=2, type="l",
     xlim=c(0, max(a$uniqueBC)),
     ylim=c(0, max(a$log10norm)),
     col="darkorchid4",
     xlab="log10(unique barcodes)",
     ylab="log10(reads per nucleus)")


##---------------------##
## cluster into groups ##
##---------------------##

# model
BIC <- mclustBIC(a$log10norm)
summary(BIC)
mod1 <- Mclust(a$log10norm, x = BIC)
summary(mod1, parameters = TRUE)


##---------------------##
## plots showing cells ##
##---------------------##

# multi-panel plot
#layout(matrix(c(1:2), nrow=1))

# cumulative distribution
nuc <- nrow(subset(a, a$log10norm >= log10(500)))

plot(a$uniqueBC[1:nuc],a$log10norm[1:nuc], lwd=2, type="l",
     xlim=c(0, max(a$uniqueBC)),
     ylim=c(0, max(a$log10norm)),
     col="darkorchid4",
     xlab="log10(unique barcodes)",
     ylab="log10(reads per nucleus)")

lines(a$uniqueBC[(nuc+1):nrow(a)],a$log10norm[(nuc+1):nrow(a)], 
       lwd=2,
       col="grey75")

text(2,2, labels=paste("n = ",nuc," nuclei", sep=""))

# plot density
#den <- density(a$log10norm, bw=0.01, from=log10(500), to=max(a$log10norm))
#plot(den, col=NA, xlab="log10(reads)", main="")
#polygon(c(0,den$x,0),c(0,den$y,0), col="grey75", border="grey75")

# output good barcodes
b <- subset(a, a$call=="nuclei")
b$uniqueBC <- NULL
write.table(b, file="nuclei_selection.txt", sep="\t", quote=F, row.names=F, col.names=F)
