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
int_dir=paste(dir,"/",jobname,"_Intermediate/",sep="")
out_cutoff=paste(int_dir,jobname,"_cutoff",sep="")
out_kmerclean=paste(int_dir,jobname,"_kmer_clean_contigs",sep="")
out_kmercontam=paste(int_dir,jobname,"_kmer_contam_contigs",sep="")
out_log=paste(dir,"/",jobname,"_log",sep="")
out_dist=paste(int_dir,jobname,"_dist",sep="")
print(out_cutoff)
print(dir)
print(k)
library("BH",lib.loc=bin)
library("bigmemory.sri",lib.loc=bin)
library("bigmemory",lib.loc=bin)
library("biganalytics",lib.loc=bin)
n=read.table(paste(int_dir,jobname,"_contigs_kmervecs_",k,"_names",sep=""),header=F)
x=read.big.matrix(paste(int_dir,jobname,"_contigs_kmervecs_",k,sep=""),header=F,sep=" ",type="double")
w=which(colsum(x)==0)
if(length(w)>0){
	x=x[,-w]
}
pca=prcomp(as.matrix(x))
out_pca=paste(int_dir,jobname,"_contigs_",k,"mer.pca",sep="")
write.table(pca$x[,1:3],out_pca,quote=F,append=F,row.names=F,col.names=F,sep="\t")
d=sapply(1:nrow(x),function(j) dist(rbind(pca$x[j,],rep(0,(ncol(pca$x))))))
if(cutoff=="DEFAULT"){
        cutoff=0.01035 
        write.table(paste("prodege_classify_noclean.R: The precalibrated cutoff is ",cutoff,".",sep=""),out_log,append=T,row.names=F,col.names=F,quote=F)
}else{
	cutoff=as.numeric(cutoff)
        write.table(paste("prodege_classify_noclean.R: Your cutoff is ",cutoff,".",sep=""),out_log,append=T,row.names=F,col.names=F,quote=F)
}
if(file.exists(paste(int_dir,jobname,"_blast_clean_contigs",sep=""))){
	sc=read.table(paste(int_dir,jobname,"_blast_clean_contigs",sep=""),header=F,sep="\t")
	s=as.matrix(cbind(sc,"clean"))
	m=merge(cbind(n,1:dim(n)[1]),s,by.x=1,by.y=1,all.x=T,all.y=F)
	m=m[order(m[,2]),]
	print(head(m))
	print(dim(m))
	print(dim(x))
	mm=cbind(m,d)
	ctm=rep("contam",nrow(mm))
	w=which(mm$d<cutoff)
	if(length(w)>0){
 	       ctm[w]="clean"
	}
	mm=cbind(mm,ctm)
	w=which(mm[,5]=="clean")
	write.table(mm[w,1],out_kmerclean,quote=F,append=F,row.names=F,col.names=F,sep="\t")
	write.table(mm[-w,1],out_kmercontam,quote=F,append=F,row.names=F,col.names=F,sep="\t")
	write.table(mm,out_dist,quote=F,append=F,row.names=F,col.names=F,sep="\t")	
	write.table(cutoff,out_cutoff,append=F,row.names=F,col.names=F,quote=F)
}else{
	mm=cbind(n,d)
	ctm=rep("contam",nrow(mm))
	w=which(mm$d<cutoff)
	if(length(w)>0){
        	ctm[w]="clean"
	}
	mm=cbind(mm,ctm)
	w=which(mm[,3]=="clean")
	if(length(w)>0){
        	write.table(mm[w,1],out_kmerclean,quote=F,append=F,row.names=F,col.names=F,sep="\t")
        	write.table(mm[-w,1],out_kmercontam,quote=F,append=F,row.names=F,col.names=F,sep="\t")
	}else{
        	write.table(mm[,1],out_kmercontam,quote=F,append=F,row.names=F,col.names=F,sep="\t")
        	f=file(out_kmerclean, "w")
        	close(f)
	}
	write.table(mm,out_dist,quote=F,append=F,row.names=F,col.names=F,sep="\t")
	write.table(cutoff,out_cutoff,append=F,row.names=F,col.names=F,quote=F)
}

