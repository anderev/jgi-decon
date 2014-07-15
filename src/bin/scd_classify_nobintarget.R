#R CMD BATCH -dir -k --no-save kmer.R kmer.out 
args=commandArgs(trailingOnly=F)
jobname=args[length(args)-1]
jobname=sub("-","",jobname)
dir=args[length(args)-3]
dir=sub("-","",dir)
k=args[length(args)-2]
k=sub("-","",k)
bin=args[length(args)-4]
bin=sub("-","",bin)
out_cutoff=paste(dir,"/",jobname,"_Intermediate/",jobname,"_cutoff",sep="")
out_kmerclean=paste(dir,"/",jobname,"_Intermediate/",jobname,"_kmer_clean_contigs",sep="")
out_kmercontam=paste(dir,"/",jobname,"_Intermediate/",jobname,"_kmer_contam_contigs",sep="")
#out_kmerundecided=paste(dir,"/kmer_undecided_contigs",sep="")
print(out_cutoff)
print(dir)
print(k)
library("BH",lib.loc=bin)
library("bigmemory.sri",lib.loc=bin)
library("bigmemory",lib.loc=bin)
library("biganalytics",lib.loc=bin)
n=read.table(paste(dir,"/",jobname,"_Intermediate/",jobname,"_contigs_kmervecs_",k,"_names",sep=""),header=F)
x=read.big.matrix(paste(dir,"/",jobname,"_Intermediate/",jobname,"_contigs_kmervecs_",k,sep=""),header=F,sep=" ",type="double")
#x=read.table(paste(dir,"/Intermediate/contigs_kmervecs_",k,sep=""),header=F,sep=" ",colClasses="double")
w=which(colsum(x)==0)
print(dim(x))
if(length(w)>0){
	x=x[,-w]
}
print(dim(x))
gc()
#x=as.matrix(x)
gc()
pca=prcomp(as.matrix(x))
out_pca=paste(dir,"/",jobname,"_Intermediate/",jobname,"_contigs_",k,"mer.pca",sep="")
write.table(pca$x[,1:3],out_pca,quote=F,append=F,row.names=F,col.names=F,sep="\t")
d=sapply(1:nrow(x),function(j) dist(rbind(pca$x[j,],rep(0,(ncol(pca$x))))))
#sc=read.table(paste(dir,"/Intermediate/blast_clean_contigs",sep=""),header=F,sep="\t")
#s=as.matrix(cbind(sc,"clean"))
#m=merge(cbind(n,1:dim(n)[1]),s,by.x=1,by.y=1,all.x=T,all.y=F)
#m=m[order(m[,2]),]
#print(head(m))
#print(dim(m))
#print(dim(x))
#mm=cbind(m,d)
mm=cbind(n,d)
ctm=rep("contam",nrow(mm))
#cutoff=0.00985
#cutoff=0.00997
#cutoff=0.0146 #Using this for fold matrix 0.94 0.83
#cutoff=0.013 #0.81 0.98
#cutoff=0.011 #0.40	0.98
#cutoff=0.01 #0.16 1
#cutoff=0.0105 #0.23 0.98
#cutoff=0.01075 #0.33 0.98
#cutoff=0.01025 #0.16 1.00
#cutoff=0.0103#0.17 1.00
#cutoff=0.0104 #0.19 0.98 too high
cutoff=0.01035 #0.19 1.00
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
write.table(cutoff,out_cutoff,append=F,row.names=F,col.names=F,quote=F)
