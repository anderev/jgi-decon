#R CMD BATCH -dir -k --no-save kmer.R kmer.out 
#ProDeGe Copyright (c) 2014, The Regents of the University of California,
#through Lawrence Berkeley National Laboratory (subject to receipt of any
#required approvals from the U.S. Dept. of Energy).  All rights reserved.

args=commandArgs(trailingOnly=F)
cutoff=args[length(args)-1]
cutoff=sub("-","",cutoff)
jobname=args[length(args)-2]
jobname=sub("-","",jobname)
dir=args[length(args)-4]
dir=sub("-","",dir)
k=args[length(args)-3]
k=sub("-","",k)
bin=args[length(args)-5]
bin=sub("-","",bin)
out_cutoff=paste(dir,"/",jobname,"_Intermediate/",jobname,"_cutoff",sep="")
out_kmerclean=paste(dir,"/",jobname,"_Intermediate/",jobname,"_kmer_clean_contigs",sep="")
out_kmercontam=paste(dir,"/",jobname,"_Intermediate/",jobname,"_kmer_contam_contigs",sep="")
out_log=paste(dir,"/",jobname,"_log",sep="")
out_dist_pre=paste(dir,"/",jobname,"_Intermediate/",jobname,"_dist_pre",sep="")
out_dist_post=paste(dir,"/",jobname,"_Intermediate/",jobname,"_dist_post",sep="")
print(out_cutoff)
print(dir)
print(k)
library("BH",lib.loc=bin)
library("bigmemory.sri",lib.loc=bin)
library("bigmemory",lib.loc=bin)
library("biganalytics",lib.loc=bin)
n=read.table(paste(dir,"/",jobname,"_Intermediate/",jobname,"_contigs_kmervecs_",k,"_names",sep=""),header=F)
x=read.big.matrix(paste(dir,"/",jobname,"_Intermediate/",jobname,"_contigs_kmervecs_",k,sep=""),header=F,sep=" ",type="double")
w=which(colsum(x)==0)
if(length(w)>0){
	x=x[,-w]
}
pca=prcomp(as.matrix(x))
out_pca=paste(dir,"/",jobname,"_Intermediate/",jobname,"_contigs_",k,"mer.pca",sep="")
write.table(pca$x[,1:3],out_pca,quote=F,append=F,row.names=F,col.names=F,sep="\t")
sc=read.table(paste(dir,"/",jobname,"_Intermediate/",jobname,"_blast_clean_contigs",sep=""),header=F,sep="\t")
sd=read.table(paste(dir,"/",jobname,"_Intermediate/",jobname,"_blast_contam_contigs",sep=""),header=F,sep="\t")
s=rbind(as.matrix(cbind(sc,"clean")),as.matrix(cbind(sd,"contam")))
m=merge(cbind(n,1:dim(n)[1]),s,by.x=1,by.y=1,all.x=T,all.y=F)
m=m[order(m[,2]),]
print(head(m))
print(dim(m))
print(dim(x))
w=which(!is.na(m[,3]))
if(length(w)>0){
	y=x[w,]
}else{
	y=x
}
pca=prcomp(y)
d=sapply(1:nrow(y),function(j) dist(rbind(pca$x[j,],rep(0,(ncol(pca$x))))))
mm=merge(m,cbind(as.character(m[w,1]),d))
write.table(mm,out_dist_pre,sep='\t',row.names=F,col.names=F,quote=F)
w=which(mm[,3]=="contam")
print(cutoff)
if(cutoff=="DEFAULT" && length(w)==0){
	cutoff=0.0136
	write.table(paste("prodege_classify_cleanandcontam.R: The precalibrated cutoff is ",round(cutoff,4),".",sep=""),out_log,append=T,row.names=F,col.names=F,quote=F)
}else if(cutoff=="DEFAULT"){
	cutoff=min(as.numeric(as.character(mm[w,4])))
	write.table(paste("prodege_classify_cleanandcontam.R: The calibrated cutoff is ",round(cutoff,4),".",sep=""),out_log,append=T,row.names=F,col.names=F,quote=F)
}else{
	cutoff=as.numeric(cutoff)	
	write.table(paste("prodege_classify_cleanandcontam.R: Your cutoff is ",round(cutoff,4),".",sep=""),out_log,append=T,row.names=F,col.names=F,quote=F)
}	
print(cutoff)
write.table(cutoff,out_cutoff,append=F,row.names=F,col.names=F,quote=F)
#no to pca of only clean and unknown with new cutoff
w=which(m[,3]=="clean"|is.na(m[,3]))
if(length(w)>0){
        y=x[w,]
}else{
        y=x
}
pca=prcomp(y)
d=sapply(1:nrow(y),function(j) dist(rbind(pca$x[j,],rep(0,(ncol(pca$x))))))
mm=merge(m,cbind(as.character(m[w,1]),d),all=T)
w=which(as.numeric(as.character(mm[,4]))<cutoff)
mm=cbind(mm,mm[,3])
if(length(w)>0){
	mm[w,5]="clean"
}	
w=which(mm[,5]=="clean")
write.table(mm,out_dist_post,sep='\t',row.names=F,col.names=F,quote=F)
write.table(mm[w,1],out_kmerclean,quote=F,append=F,row.names=F,col.names=F,sep="\t")
write.table(mm[-w,1],out_kmercontam,quote=F,append=F,row.names=F,col.names=F,sep="\t")

