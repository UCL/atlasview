#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)
cat(args[1], "\n")
encrypted <- scrypt::hashPassword(args[1])
cat(encrypted, "\n")

