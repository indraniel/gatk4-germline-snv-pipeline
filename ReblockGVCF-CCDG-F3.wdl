version 1.0

workflow ReblockGVCF {

  input {
    Array[File]+ gvcfs
    Array[File]+ gvcf_indexes

    Int? disk_size
    String docker_image = "us.gcr.io/broad-dsde-methods/reblock_sharded_gvcfs@sha256:4649567000feae7dd028fb87d6e1ae150a8354ebdf62ca0b7135864f4e656ca6"
  }

  String sub_strip_path = "gs://.*/"
  String sub_strip_gvcf = ".g.vcf.gz" + "$"
  String sub_sub = sub(sub(gvcfs[0], sub_strip_path, ""), sub_strip_gvcf, "")
  

  call Reblock {
      input:
        gvcfs = gvcfs,
        gvcf_indexes = gvcf_indexes,
        output_vcf_filename = sub_sub + ".vcf.gz",
        disk_size = disk_size,
        docker_image = docker_image
    }
  output {
    File output_vcf = Reblock.output_vcf
    File output_vcf_index = Reblock.output_vcf_index
  }
}

task Reblock {

  input {
    Array[File]+ gvcfs
    Array[File]+ gvcf_indexes
    String output_vcf_filename
    Int? disk_size
    String docker_image
  }

  Int final_disk_size = select_first([disk_size, ceil(size(gvcfs, "GiB")) * 2])

  command {
    gatk --java-options "-Xms3g -Xmx3g" \
      ReblockGVCF \
      -V ~{sep=' -V ' gvcfs} \
      -drop-low-quals \
      -do-qual-approx \
      --floor-blocks -GQB 10 -GQB 20 -GQB 30 -GQB 40 -GQB 50 -GQB 60 \
      -O ~{output_vcf_filename}
  }

  runtime {
    memory: "3.75 GB"
    disks: "local-disk " + final_disk_size + " HDD"
    preemptible: 3
    docker: docker_image
  }

  output {
    File output_vcf = output_vcf_filename
    File output_vcf_index = output_vcf_filename + ".tbi"
  }
} 
