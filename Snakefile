SAMPLES = ["A", "B", "C"]

rule all:
	input:
		"out.html"

rule bwa_map:
	input:
		"data/genome.fa",
		"data/samples/{sample}.fastq"
	output:
		"mapped_reads/{sample}.bam"
	message:
		"executing bwa mem for {input}, generating {output}"
	shell:
		"bwa mem {input} | samtools view -Sb - > {output}"

rule samtools_sort:
	input:
		"mapped_reads/{sample}.bam"
	output:
		"sorted_reads/{sample}.bam"
	message:
		"sorting reads in {input}, sorted reads written to {output}"
	shell:
		"samtools sort -T sorted_reads/{wildcards.sample} "
		"-O bam {input} > {output}"

rule samtools_index:
	input:
		"sorted_reads/{sample}.bam"
	output:
		"sorted_reads/{sample}.bam.bai"
	message:
		"indexing reads in {input}, indexed reads will be written to {output}"
	shell:
		"samtools index {input}"

rule bcftools_call:
	input:
		fa = "data/genome.fa",
		bam = expand("sorted_reads/{sample}.bam", sample = SAMPLES),
		bai = expand("sorted_reads/{sample}.bam.bai", sample = SAMPLES)
	output:
		"calls/all.vcf"
	message:
		"creating pileup of {input.fa} and {input.bam} to create bcftools output: {output}"
	shell:
		"samtools mpileup -g -f {input.fa} {input.bam} | "
		"bcftools call -mv - > {output}"

rule report:
	input:
		"calls/all.vcf"
	output:
		"out.html"
	message:
		"creating a report ({output})"
	run:
		from snakemake.utils import report

		with open(input[0]) as file:
			n_calls = sum(1 for line in file if not line.startswith("#"))

		report('''
		An example workflow
		===================================

		Reads were mapped to the Yeast reference genome 
		and variants were called jointly with
		SAMtools/BCFtools.

		This resulted in {n_calls} variants (see Table T1_).
		''', output[0], metadata="Author: David", T1=input[0])