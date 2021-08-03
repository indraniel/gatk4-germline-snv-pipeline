workflow UnalignedToBQSRCramAndVCF {

  File InputTSV
  Array[Array[String]] inputFiles = read_tsv(InputTSV)
  File ChrExtFile = "/gscmnt/production_reference/info/production_reference_GRCh38DH/reference/all_sequences.filtered-chromosome.list.ext"
  Array[String] ChrExtList = read_lines(ChrExtFile)
  Array[String] ChromosomeList = ["chr1","chr2","chr3","chr4","chr5","chr6","chr7","chr8","chr9","chr10","chr11","chr12","chr13","chr14","chr15","chr16","chr17","chr18","chr19","chr20","chr21","chr22","chrY"]
  String Reference = "/gscmnt/production_reference/info/production_reference_GRCh38DH/reference/all_sequences.fa"
  String dbSNP = "/gscmnt/production_reference/info/production_reference_GRCh38DH/known_sites/Homo_sapiens_assembly38.dbsnp138.vcf.gz"
  String Mills = "/gscmnt/production_reference/info/production_reference_GRCh38DH/known_sites/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz"
  String Indels = "/gscmnt/production_reference/info/production_reference_GRCh38DH/known_sites/Homo_sapiens_assembly38.known_indels.vcf.gz"
  String Intervals = "/gscmnt/production_reference/info/production_reference_GRCh38DH/intervals/build38_autosome_intervals.list"
  String OmniVCF = "/gscmnt/production_reference/info/production_reference_GRCh38DH/accessory_vcf/omni25-ld-pruned-20000-2000-0.5-annotated.wchr.sites_only.b38.autosomes_only.vcf.gz"
  String Dictionary = "/gscmnt/production_reference/info/production_reference_GRCh38DH/reference/all_sequences.dict"
  String KnownVariants = "/gscmnt/production_reference/info/production_reference_GRCh38DH/accessory_vcf/ALL.phase3_shapeit_mvncall_integrated_v3plus_nounphased.rsID.genotypes.GRCh38_dbSNP_no_SVs.no_sex_chromosomes.sites_only.wchr.vcf.gz"
  String JobGroup
  Int Priority
  String Project
  String Queue
  String TMPDIR
  String OutputDir
  String FinalLabel

  scatter (file in inputFiles) {
    Int revert_align_and_tag_priority_1 = Priority + 1
    String revert_align_and_tag_priority_value_1 = " " + revert_align_and_tag_priority_1
    call revert_align_and_tag {
         input: refFasta=Reference,
                uBam=file[0],
                readGroup=file[1],
                jobGroup=JobGroup,
                priority=revert_align_and_tag_priority_value_1,
                queue=Queue,
                project=Project
    }
  }

  Int merge_priority_2 = Priority + 2
  String merge_priority_value_2 = " " + merge_priority_2
  call merge {
       input: files=revert_align_and_tag.TaggedBam,
              jobGroup=JobGroup,
              priority=merge_priority_value_2,
              queue=Queue,
              project=Project
  }

  scatter (file in revert_align_and_tag.TaggedBam) {
    Int remove_file_priority_3 = Priority + 3
    String remove_file_priority_value_3 = " " + remove_file_priority_3
    call remove_file as rm_aligned {
       input: file=file,
              order_by=merge.MergedBam,
              jobGroup=JobGroup,
              priority=remove_file_priority_value_3,
              queue=Queue,
              project=Project
    }
  }

  Int name_sort_priority_4 = Priority + 4
  String name_sort_priority_value_4 = " " + name_sort_priority_4
  call name_sort {
       input: tmp=TMPDIR,
              alignedBam=merge.MergedBam,
              jobGroup=JobGroup,
              priority=name_sort_priority_value_4,
              queue=Queue,
              project=Project
  }
  Int remove_file_priority_5 = Priority + 5
  String remove_file_priority_value_5 = " " + remove_file_priority_5
  call remove_file as rm_merge {
     input: file=merge.MergedBam,
            order_by=name_sort.SortedBam,
              jobGroup=JobGroup,
              priority=remove_file_priority_value_5,
              queue=Queue,
              project=Project
  }

  Int mark_priority_6 = Priority + 6
  String mark_priority_value_6 = " " + mark_priority_6
  call mark {
       input: tmp=TMPDIR,
              mergedBam=name_sort.SortedBam,
              label=FinalLabel,
              jobGroup=JobGroup,
              priority=mark_priority_value_6,
              queue=Queue,
              project=Project
  }

  Int remove_file_priority_7 = Priority + 7
  String remove_file_priority_value_7 = " " + remove_file_priority_7
  call remove_file as rm_name_sorted {
       input: file=name_sort.SortedBam,
              order_by=mark.SortedBam,
              jobGroup=JobGroup,
              priority=remove_file_priority_value_7,
              queue=Queue,
              project=Project
  }

  Int bqsr_priority_8 = Priority + 8
  String bqsr_priority_value_8 = " " + bqsr_priority_8
  call bqsr {
       input: refFasta=Reference,
              marked=mark.SortedBam,
              sites=[dbSNP,Mills,Indels],
              jobGroup=JobGroup,
              priority=bqsr_priority_value_8,
              queue=Queue,
              project=Project
  }

  Int apply_bqsr_priority_9 = Priority + 9
  String apply_bqsr_priority_value_9 = " " + apply_bqsr_priority_9
  call apply_bqsr {
       input: refFasta=Reference,
              marked=mark.SortedBam,
              bqsrt=bqsr.bqsrTable,
              label=FinalLabel,
              jobGroup=JobGroup,
              priority=apply_bqsr_priority_value_9,
              queue=Queue,
              project=Project
  }

  Int remove_file_priority_10 = Priority + 10
  String remove_file_priority_value_10 = " " + remove_file_priority_10
  call remove_file as rm_mark {
       input: file=mark.SortedBam,
              order_by=apply_bqsr.bqsrBam,
              jobGroup=JobGroup,
              priority=remove_file_priority_value_10,
              queue=Queue,
              project=Project
  }

  Int verifybamid_priority_11 = Priority + 11
  String verifybamid_priority_value_11 = " " + verifybamid_priority_11
  call verifybamid {
       input: bam=apply_bqsr.bqsrBam,
              omni_vcf=OmniVCF,
              jobGroup=JobGroup,
              priority=verifybamid_priority_value_11,
              queue=Queue,
              project=Project
  }

  Int convert_to_cram_priority_12 = Priority + 12
  String convert_to_cram_priority_value_12 = " " + convert_to_cram_priority_12
  call convert_to_cram {
       input: refFasta=Reference,
              bqsrb=apply_bqsr.bqsrBam,
              label=FinalLabel,
              jobGroup=JobGroup,
              priority=convert_to_cram_priority_value_12,
              queue=Queue,
              project=Project
  }
  Int md5_run_priority_13 = Priority + 13
  String md5_run_priority_value_13 = " " + md5_run_priority_13
  call md5_run {
       input: fh=convert_to_cram.bqsrCram,
              jobGroup=JobGroup,
              priority=md5_run_priority_value_13,
              queue=Queue,
              project=Project
  }

  scatter (Chrom in ChromosomeList) {
       Int haplotype_call_priority_14 = Priority + 14
       String haplotype_call_priority_value_14 = " " + haplotype_call_priority_14
       call haplotype_call {
            input: refFasta=Reference,
                   bqsrb=convert_to_cram.bqsrCram,
                   chr=Chrom,
                   label=FinalLabel,
                   jobGroup=JobGroup,
                   priority=haplotype_call_priority_value_14,
                   queue=Queue,
                   project=Project
       }
  }
  Int haplotype_x_call_priority_15 = Priority + 15
  String haplotype_x_call_priority_value_15 = " " + haplotype_x_call_priority_15
  call haplotype_x_call {
       input: refFasta=Reference,
              bqsrb=convert_to_cram.bqsrCram,
              label=FinalLabel,
              jobGroup=JobGroup,
              priority=haplotype_x_call_priority_value_15,
              queue=Queue,
              project=Project
  }
  Int haplotype_ext_call_priority_16 = Priority + 16
  String haplotype_ext_call_priority_value_16 = " " + haplotype_ext_call_priority_16
  call haplotype_ext_call {
       input: refFasta=Reference,
              bqsrb=convert_to_cram.bqsrCram,
              chr=ChrExtList,
              label=FinalLabel,
              jobGroup=JobGroup,
              priority=haplotype_ext_call_priority_value_16,
              queue=Queue,
              project=Project
  }

  Int cat_vcf_priority_17 = Priority + 17
  String cat_vcf_priority_value_17 = " " + cat_vcf_priority_17
  call cat_vcf {
       input: vcfs=haplotype_call.VCF,
              x=haplotype_x_call.VCF,
              ext=haplotype_ext_call.VCF,
              dc=Dictionary,
              jobGroup=JobGroup,
              priority=cat_vcf_priority_value_17,
              queue=Queue,
              project=Project
  }

  Int collect_variant_calling_metrics_priority_18 = Priority + 18
  String collect_variant_calling_metrics_priority_value_18 = " " + collect_variant_calling_metrics_priority_18
  call collect_variant_calling_metrics as all_vc {
       input: vcf=cat_vcf.allVCF,
              dc=Dictionary,
              dbsnp=KnownVariants,
              label="all_chrom",
              jobGroup=JobGroup,
              priority=collect_variant_calling_metrics_priority_value_18,
              queue=Queue,
              project=Project
  }
  Int collect_variant_calling_metrics_priority_19 = Priority + 19
  String collect_variant_calling_metrics_priority_value_19 = " " + collect_variant_calling_metrics_priority_19
  call collect_variant_calling_metrics as x_vc {
       input: vcf=haplotype_x_call.VCF,
              dc=Dictionary,
              dbsnp=KnownVariants,
              label="X_chrom",
              jobGroup=JobGroup,
              priority=collect_variant_calling_metrics_priority_value_19,
              queue=Queue,
              project=Project
  }
  Int collect_alignment_metrics_priority_20 = Priority + 20
  String collect_alignment_metrics_priority_value_20 = " " + collect_alignment_metrics_priority_20
  call collect_alignment_metrics {
       input: in=convert_to_cram.bqsrCram,
              ref=Reference,
              jobGroup=JobGroup,
              priority=collect_alignment_metrics_priority_value_20,
              queue=Queue,
              project=Project
  }
  Int collect_gc_metrics_priority_21 = Priority + 21
  String collect_gc_metrics_priority_value_21 = " " + collect_gc_metrics_priority_21
  call collect_gc_metrics {
       input: in=convert_to_cram.bqsrCram,
              ref=Reference,
              jobGroup=JobGroup,
              priority=collect_gc_metrics_priority_value_21,
              queue=Queue,
              project=Project
  }
  Int collect_insert_metrics_priority_22 = Priority + 22
  String collect_insert_metrics_priority_value_22 = " " + collect_insert_metrics_priority_22
  call collect_insert_metrics {
       input: in=apply_bqsr.bqsrBam,
              ref=Reference,
              jobGroup=JobGroup,
              priority=collect_insert_metrics_priority_value_22,
              queue=Queue,
              project=Project
  }
  Int collect_wgs_metrics_priority_23 = Priority + 23
  String collect_wgs_metrics_priority_value_23 = " " + collect_wgs_metrics_priority_23
  call collect_wgs_metrics {
       input: in=convert_to_cram.bqsrCram,
              ref=Reference,
              int=Intervals,
              jobGroup=JobGroup,
              priority=collect_wgs_metrics_priority_value_23,
              queue=Queue,
              project=Project
  }
  Int flagstat_priority_24 = Priority + 24
  String flagstat_priority_value_24 = " " + flagstat_priority_24
  call flagstat {
       input: in=convert_to_cram.bqsrCram,
              jobGroup=JobGroup,
              priority=flagstat_priority_value_24,
              queue=Queue,
              project=Project
  }
  Int bamutil_priority_25 = Priority + 25
  String bamutil_priority_value_25 = " " + bamutil_priority_25
  call bamutil {
       input: in=apply_bqsr.bqsrBam,
              jobGroup=JobGroup,
              priority=bamutil_priority_value_25,
              queue=Queue,
              project=Project
  }

  Int gather_result_priority_26 = Priority + 26
  String gather_result_priority_value_26 = " " + gather_result_priority_26
  call gather_result as gather_vcf {
       input: files=haplotype_call.VCF,
              dir=OutputDir,
              orderBy=cat_vcf.allVCF,
              jobGroup=JobGroup,
              priority=gather_result_priority_value_26,
              queue=Queue,
              project=Project
  }
  Int gather_result_priority_27 = Priority + 27
  String gather_result_priority_value_27 = " " + gather_result_priority_27
  call gather_result as gather_vcfi {
       input: files=haplotype_call.VCFIndex,
              dir=OutputDir,
              orderBy=cat_vcf.allVCF,
              jobGroup=JobGroup,
              priority=gather_result_priority_value_27,
              queue=Queue,
              project=Project
  }
  Int gather_result_priority_28 = Priority + 28
  String gather_result_priority_value_28 = " " + gather_result_priority_28
  call gather_result as gather_the_rest {
       input: files=[convert_to_cram.bqsrCram,
                     convert_to_cram.bqsrCramIndex,
                     md5_run.out,
                     verifybamid.vidOut,
                     verifybamid.vidDepth,
                     verifybamid.vidOutRG,
                     verifybamid.vidDepthRG,
                     collect_alignment_metrics.alignMetrics,
                     collect_gc_metrics.gcOut,
                     collect_gc_metrics.gcSum,
                     collect_gc_metrics.gcPDF,
                     collect_insert_metrics.isOut,
                     collect_insert_metrics.isPDF,
                     collect_wgs_metrics.wgsMetrics,
                     flagstat.fsOut,
                     bamutil.bamutilOut,
                     mark.MarkMetrics,
                     all_vc.vcDetail,
                     all_vc.vcSummary,
                     x_vc.vcDetail,
                     x_vc.vcSummary,
                     haplotype_x_call.VCF,
                     haplotype_ext_call.VCF,
                     haplotype_x_call.VCFIndex,
                     haplotype_ext_call.VCFIndex
                     ],
              dir=OutputDir,
              orderBy=cat_vcf.allVCF,
              jobGroup=JobGroup,
              priority=gather_result_priority_value_28,
              queue=Queue,
              project=Project
  }
  Int remove_file_priority_29 = Priority + 29
  String remove_file_priority_value_29 = " " + remove_file_priority_29
  call remove_file as rm_bqsrBam {
       input: file=apply_bqsr.bqsrBam,
              order_by=gather_the_rest.out,
              jobGroup=JobGroup,
              priority=remove_file_priority_value_29,
              queue=Queue,
              project=Project
  }
}

task revert_align_and_tag {
     String uBam
     String refFasta
     String readGroup
     String jobGroup
     String priority
     String project
     String queue

     command {
            (set -eo pipefail && /usr/local/bin/samtools fastq ${uBam} | /usr/local/bin/bwa mem -K 100000000 -t 8 -p -Y -R "${readGroup}" ${refFasta} - | /usr/local/bin/samblaster -a --addMateTags | /usr/local/bin/samtools view -b -S /dev/stdin > "refAlign.bam")
     }
     runtime {
             docker_image: "registry.gsc.wustl.edu/genome/tagged-alignment:2"
             cpu: "8"
             memory_gb: "20"
             queue: queue
             resource: "rusage[gtmp=10, mem=20000]"
             job_group: jobGroup
             priority: priority
             project: project
     }
     output {
            File TaggedBam = "refAlign.bam"
     }
}

task merge {
     Array[String] files
     String jobGroup
     String priority
     String project
     String queue

     command {
             /usr/local/bin/samtools merge "AlignedMerged.bam" ${sep=" " files}
     }
     runtime {
             docker_image: "registry.gsc.wustl.edu/genome/samtools-1.3.1-2:2"
             cpu: "1"
             memory_gb: "20"
             queue: queue
             resource: "rusage[gtmp=10, mem=20000]"
             job_group: jobGroup
             priority: priority
             project: project
     }
     output {
            File MergedBam = "AlignedMerged.bam"
    }
}

task name_sort {
     String alignedBam
     String tmp
     String jobGroup
     String priority
     String project
     String queue

     command {
             /usr/local/bin/sambamba sort -t 8 -m 18G -n --tmpdir=${tmp} -o "NameSorted.bam" ${alignedBam}
     }
     runtime {
             docker_image: "registry.gsc.wustl.edu/genome/sambamba-0.6.4:1"
             cpu: "8"
             memory_gb: "20"
             queue: queue
             resource: "rusage[gtmp=10, mem=20000]"
             job_group: jobGroup
             priority: priority
             project: project
     }
     output {
             File SortedBam = "NameSorted.bam"
     }
     
}

task mark {
     String mergedBam
     String jobGroup
     String priority
     String project
     String tmp
     String label
     String queue

     command {
             (set -eo pipefail && /usr/bin/java -Xmx16g -jar /usr/picard/picard.jar MarkDuplicates I=${mergedBam} O=/dev/stdout ASSUME_SORT_ORDER=queryname METRICS_FILE=mark_dups_metrics.txt QUIET=true COMPRESSION_LEVEL=0 VALIDATION_STRINGENCY=LENIENT | /usr/local/bin/sambamba sort -t 8 -m 18G --tmpdir=${tmp} -o "${label}.bam" /dev/stdin)
     }
     runtime {
             docker_image: "registry.gsc.wustl.edu/genome/sort-mark-duplicates:2"
             cpu: "8"
             memory_gb: "50"
             queue: queue
             resource: "rusage[gtmp=10, mem=50000]"
             job_group: jobGroup
             priority: priority
             project: project
     }
     output {
             File SortedBam = "${label}.bam"
             File SortedBamIndex = "${label}.bam.bai"
             File MarkMetrics = "mark_dups_metrics.txt"
     }
     
}

task bqsr {
     String refFasta
     String marked
     Array[String] sites
     String jobGroup
     String priority
     String project
     String queue
     
     command {
             /usr/bin/java -Xmx16g -jar /opt/GenomeAnalysisTK.jar -T BaseRecalibrator -R ${refFasta} -I ${marked} -o "bqsr.table" -knownSites ${sep=" -knownSites " sites} --preserve_qscores_less_than 6 --disable_auto_index_creation_and_locking_when_reading_rods -dfrac .1 -nct 4 -L chr1 -L chr2 -L chr3 -L chr4 -L chr5 -L chr6 -L chr7 -L chr8 -L chr9 -L chr10 -L chr11 -L chr12 -L chr13 -L chr14 -L chr15 -L chr16 -L chr17 -L chr18 -L chr19 -L chr20 -L chr21 -L chr22
     }
     runtime  {
             docker_image: "registry.gsc.wustl.edu/genome/gatk-3.6:1"
             cpu: "4"
             memory_gb: "32"
             queue: queue
             resource: "rusage[gtmp=10, mem=32000]"
             job_group: jobGroup
             priority: priority
             project: project
     }
     output {
            File bqsrTable = "bqsr.table"
     }
}

task apply_bqsr {
     String bqsrt
     String refFasta
     String marked
     String label
     String jobGroup
     String priority
     String project
     String queue

     command {
             /usr/bin/java -Xmx16g -jar /opt/GenomeAnalysisTK.jar -T PrintReads -R ${refFasta} -I ${marked} -o "${label}.bam" -preserveQ 6 -BQSR "${bqsrt}" -SQQ 10 -SQQ 20 -SQQ 30 -nct 8 --disable_indel_quals
     }
     runtime  {
             docker_image: "registry.gsc.wustl.edu/genome/gatk-3.6:1"
             cpu: "8"
             memory_gb: "32"
             queue: queue
             resource: "rusage[gtmp=10, mem=32000]"
             job_group: jobGroup
             priority: priority
             project: project
     }
     output {
            File bqsrBam = "${label}.bam"
     }
}

task verifybamid {
     String bam
     String omni_vcf
     String jobGroup
     String priority
     String project
     String queue

     command {
             /usr/local/bin/verifyBamID --vcf ${omni_vcf} --bam ${bam} --precise --maxDepth 150 --out "verify_bam_id"
     }
     runtime {
             docker_image: "registry.gsc.wustl.edu/genome/lims-verifybamid:1"
             cpu: "1"
             memory_gb: "20"
             queue: queue
             resource: "rusage[gtmp=10, mem=20000]"
             job_group: jobGroup
             priority: priority
             project: project
     }
     output {
            File vidOut = "verify_bam_id.selfSM"
            File vidDepth = "verify_bam_id.depthSM"
            File vidOutRG = "verify_bam_id.selfRG"
            File vidDepthRG = "verify_bam_id.depthRG"
    }
}

task convert_to_cram {
     String refFasta
     String bqsrb
     String label
     String jobGroup
     String priority
     String project
     String queue

     command {
             /usr/local/bin/samtools view -C -T ${refFasta} ${bqsrb} > "${label}.cram"; /usr/local/bin/samtools index "${label}.cram"
     }
     runtime {
             docker_image: "registry.gsc.wustl.edu/genome/samtools-1.3.1-2:2"
             cpu: "1"
             memory_gb: "20"
             queue: queue
             resource: "rusage[gtmp=10, mem=20000]"
             job_group: jobGroup
             priority: priority
             project: project
     }
     output {
            File bqsrCram = "${label}.cram"
            File bqsrCramIndex = "${label}.cram.crai"
    }

}

task haplotype_call {
     String refFasta
     String bqsrb
     String chr
     String label
     String jobGroup
     String priority
     String project
     String queue
     
     command {
             /usr/bin/java -Xmx16g -jar /opt/GenomeAnalysisTK.jar -T HaplotypeCaller -R ${refFasta} -I ${bqsrb} -o "${label}.${chr}.g.vcf.gz" -ERC GVCF -GQB 5 -GQB 20 -GQB 60 -variant_index_type LINEAR -variant_index_parameter 128000 -L ${chr}
     }
     runtime  {
             docker_image: "registry.gsc.wustl.edu/genome/gatk-3.5:1"
             cpu: "2"
             memory_gb: "18"
             queue: queue
             resource: "rusage[gtmp=10, mem=18000]"
             job_group: jobGroup
             priority: priority
             project: project
     }
     output {
            File VCF = "${label}.${chr}.g.vcf.gz"
            File VCFIndex = "${label}.${chr}.g.vcf.gz.tbi"
     }
}
task haplotype_ext_call {
     String refFasta
     String bqsrb
     Array[String] chr
     String label
     String jobGroup
     String priority
     String project
     String queue
     
     command {
             /usr/bin/java -Xmx16g -jar /opt/GenomeAnalysisTK.jar -T HaplotypeCaller -R ${refFasta} -I ${bqsrb} -o "${label}.extChr.g.vcf.gz" -ERC GVCF -GQB 5 -GQB 20 -GQB 60 -variant_index_type LINEAR -variant_index_parameter 128000 -L ${sep=" -L " chr}
     }
     runtime {
             docker_image: "registry.gsc.wustl.edu/genome/gatk-3.5:1"
             cpu: "2"
             memory_gb: "18"
             queue: queue
             resource: "rusage[gtmp=10, mem=18000]"
             job_group: jobGroup
             priority: priority
             project: project
     }
     output {
            File VCF = "${label}.extChr.g.vcf.gz"
            File VCFIndex = "${label}.extChr.g.vcf.gz.tbi"
     }
}
task haplotype_x_call {
     String refFasta
     String bqsrb
     String label
     String jobGroup
     String priority
     String project
     String queue
     
     command {
             /usr/bin/java -Xmx16g -jar /opt/GenomeAnalysisTK.jar -T HaplotypeCaller -R ${refFasta} -I ${bqsrb} -o "${label}.chrX.g.vcf.gz" -ERC GVCF -GQB 5 -GQB 20 -GQB 60 -variant_index_type LINEAR -variant_index_parameter 128000 -L "chrX"
     }
     runtime {
             docker_image: "registry.gsc.wustl.edu/genome/gatk-3.5:1"
             cpu: "2"
             memory_gb: "18"
             queue: queue
             resource: "rusage[gtmp=10, mem=18000]"
             job_group: jobGroup
             priority: priority
             project: project
     }
     output {
            File VCF = "${label}.chrX.g.vcf.gz"
            File VCFIndex = "${label}.chrX.g.vcf.gz.tbi"
     }
}

task cat_vcf {
     Array[String] vcfs
     String x
     String ext
     String dc
     String jobGroup
     String priority
     String project
     String queue

     command {
             /usr/bin/java -Xmx16g -jar /usr/picard/picard.jar MergeVcfs D=${dc} O="all_chrom.g.vcf.gz" I=${sep=" I=" vcfs} I=${x} I=${ext}
     }
     runtime {
             docker_image: "registry.gsc.wustl.edu/genome/picard-2.4.1-r:2"
             cpu: "2"
             memory_gb: "20"
             queue: queue
             resource: "rusage[gtmp=10, mem=20000]"
             job_group: jobGroup
             priority: priority
             project: project
     }
     output {
            File allVCF = "all_chrom.g.vcf.gz"
     }

}

task collect_variant_calling_metrics {
     String vcf
     String dc
     String dbsnp
     String label
     String jobGroup
     String priority
     String project
     String queue

     command {
             /usr/bin/java -Xmx16g -jar /usr/picard/picard.jar CollectVariantCallingMetrics INPUT=${vcf} OUTPUT=${label} DBSNP=${dbsnp} SD=${dc} GVCF_INPUT=true
     }
     runtime {
             docker_image: "registry.gsc.wustl.edu/genome/picard-2.4.1-r:2"
             cpu: "2"
             memory_gb: "18"
             queue: queue
             resource: "rusage[gtmp=10, mem=18000]"
             job_group: jobGroup
             priority: priority
             project: project
     }
     output {
            File vcDetail = "${label}.variant_calling_detail_metrics"
            File vcSummary = "${label}.variant_calling_summary_metrics"
     }
     
}
task collect_alignment_metrics {
     String in
     String ref
     String jobGroup
     String priority
     String project
     String queue

     command {
             /usr/bin/java -Xmx16g -jar /usr/picard/picard.jar CollectAlignmentSummaryMetrics REFERENCE_SEQUENCE=${ref} INPUT=${in} OUTPUT="alignment_summary.txt" ASSUME_SORTED=true
     }
     runtime {
             docker_image: "registry.gsc.wustl.edu/genome/picard-2.4.1-r:2"
             cpu: "2"
             memory_gb: "18"
             queue: queue
             resource: "rusage[gtmp=10, mem=18000]"
             job_group: jobGroup
             priority: priority
             project: project
     }
     output {
            File alignMetrics = "alignment_summary.txt"
     }
}
task collect_gc_metrics {
     String in
     String ref
     String jobGroup
     String priority
     String project
     String queue

     command {
             /usr/bin/java -Xmx16g -jar /usr/picard/picard.jar CollectGcBiasMetrics REFERENCE_SEQUENCE=${ref} INPUT=${in} OUTPUT="GC_bias.txt" SUMMARY_OUTPUT="GC_bias_summary.txt" CHART_OUTPUT="GC_bias_chart.pdf" ASSUME_SORTED=true
     }
     runtime {
             docker_image: "registry.gsc.wustl.edu/genome/picard-2.4.1-r:2"
             cpu: "2"
             memory_gb: "18"
             queue: queue
             resource: "rusage[gtmp=10, mem=18000]"
             job_group: jobGroup
             priority: priority
             project: project
     }
     output {
            File gcOut = "GC_bias.txt"
            File gcSum = "GC_bias_summary.txt"
            File gcPDF = "GC_bias_chart.pdf"
     }
     
}
task collect_insert_metrics {
     String in
     String ref
     String jobGroup
     String priority
     String project
     String queue

     command {
             /usr/bin/java -Xmx16g -jar /usr/picard/picard.jar CollectInsertSizeMetrics INPUT=${in} OUTPUT="insert_size_summary.txt" HISTOGRAM_FILE="insert_size.pdf" ASSUME_SORTED=true
     }
     runtime {
             docker_image: "registry.gsc.wustl.edu/genome/picard-2.4.1-r:2"
             cpu: "2"
             memory_gb: "18"
             queue: queue
             resource: "rusage[gtmp=10, mem=18000]"
             job_group: jobGroup
             priority: priority
             project: project
     }
     output {
            File isOut = "insert_size_summary.txt"
            File isPDF = "insert_size.pdf"
     }
     
}
task collect_wgs_metrics {
     String in
     String ref
     String int
     String jobGroup
     String priority
     String project
     String queue

     command {
             /usr/bin/java -Xmx16g -jar /usr/picard/picard.jar CollectWgsMetrics REFERENCE_SEQUENCE=${ref} INPUT=${in} INTERVALS=${int} OUTPUT="wgs_metric_summary.txt" MINIMUM_MAPPING_QUALITY=0 MINIMUM_BASE_QUALITY=0
     }
     runtime {
             docker_image: "registry.gsc.wustl.edu/genome/picard-2.4.1-r:2"
             cpu: "2"
             memory_gb: "18"
             queue: queue
             resource: "rusage[gtmp=10, mem=18000]"
             job_group: jobGroup
             priority: priority
             project: project
     }
     output {
            File wgsMetrics = "wgs_metric_summary.txt"
     }
     
}
task flagstat {
     String in
     String jobGroup
     String priority
     String project
     String queue

     command {
             /usr/local/bin/samtools flagstat ${in} > "flagstat.out"
     }
     runtime {
             docker_image: "registry.gsc.wustl.edu/genome/tagged-alignment:2"
             cpu: "1"
             memory_gb: "10"
             queue: queue
             resource: "rusage[gtmp=10, mem=10000]"
             job_group: jobGroup
             priority: priority
             project: project
     }
     output {
            File fsOut = "flagstat.out"
    }
}

task bamutil {
     String in
     String jobGroup
     String priority
     String project
     String queue

     command {
             /usr/local/bin/bam stats --noPhoneHome --in ${in} --phred --excludeFlags 3844 2> bamutil_stats.txt
     }
     runtime {
             docker_image: "registry.gsc.wustl.edu/genome/bamutil:2"
             cpu: "1"
             memory_gb: "10"
             queue: queue
             resource: "rusage[gtmp=10, mem=10000]"
             job_group: jobGroup
             priority: priority
             project: project
     }
     output {
            File bamutilOut = "bamutil_stats.txt"
    }
}
task md5_run {
     String fh
     String jobGroup
     String priority
     String project
     String queue

     command {
             /usr/bin/md5sum ${fh} > "${fh}.md5"
     }
     runtime {
             docker_image: "registry.gsc.wustl.edu/genome/lims-compute-xenial:1"
             queue: queue
             job_group: jobGroup
             priority: priority
             project: project
     }
     output {
            File out = "${fh}.md5"
     }
}

task gather_result {
     String dir
     Array[String] files
     String jobGroup
     String priority
     String project
     String orderBy
     String queue

     command {
             /bin/mv -t ${dir} ${sep=" " files}
     }
     runtime {
             docker_image: "registry.gsc.wustl.edu/genome/lims-compute-xenial:1"
             queue: queue
             job_group: jobGroup
             priority: priority
             project: project
     }
     output {
            String out = stdout()
     }
}

task remove_file {
     String file
     String order_by
     String jobGroup
     String priority
     String project
     String queue

     command {
             /bin/rm ${file}
     }
     runtime {
             docker_image: "registry.gsc.wustl.edu/genome/lims-compute-xenial:1"
             queue: queue
             job_group: jobGroup
             priority: priority
             project: project
     }
     output {
            String out = stdout()
     }
}
