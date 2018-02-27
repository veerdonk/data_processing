args = commandArgs(trailingOnly=TRUE)

orthologs <- read.delim(paste0(args[1], "orthologs.txt"), header = FALSE)
coorthologs <- read.delim(paste0(args[1], "coorthologs.txt"), header = FALSE)
inparalogs <- read.delim(paste0(args[1], "inparalogs.txt"), header = FALSE)

jpeg(args[2])
barplot(c(length(orthologs$V1), length(coorthologs$V1), length(inparalogs$V1)),
        names.arg = c("orthologs", "coorthologs", "inparalogs"),
        main = "Number of gene relations found",
        xlab = "orthology type",
        ylab = "number of genes",
        col = rainbow(3))
dev.off()