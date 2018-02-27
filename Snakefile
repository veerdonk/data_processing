configfile: "config.yaml"
workdir: config["workingdir"]

rule all:
	input:
		config["orthomcl"] + "barchart.jpg"

rule adjustFasta:
	input:
		config["fastaDir"] + "{sample}.pep"
	output:
		config["adjustedDir"] + "{sample}.fasta"
	shell:
		"INSTRING='{input}'&&"
		"SUBSTRING=$(echo $INSTRING | cut -d '/' -f 3 |cut -d '.' -f 1)&&"
		"cd "+ config["adjustedDir"] +" && orthomclAdjustFasta $SUBSTRING ../../{input} 1"

rule filterFasta:
	input:
		expand(config["adjustedDir"] + "{sample}.fasta", sample=config["samples"])
	output:
		config["filterDir"] + "goodProteins.fasta"
	shell:
		"orthomclFilterFasta "+ config["adjustedDir"] +" 10 20&&"
		"mv goodProteins.fasta " + config["filterDir"] +
		"&&mv poorProteins.fasta " + config["filterDir"]

rule createBlastDb:
	input:
		config["filterDir"] + "goodProteins.fasta"
	output:
		config["dbDir"] + "goodProteinsdb.phr",
		config["dbDir"] + "goodProteinsdb.pin",
		config["dbDir"] + "goodProteinsdb.psq"
	shell:
		"makeblastdb -dbtype 'prot' -in {input} -out "+ config["dbDir"] +"goodProteinsdb"

rule runBlast:
	input:
		config["dbDir"] + "goodProteinsdb.phr",
		config["dbDir"] + "goodProteinsdb.pin",
		config["dbDir"] + "goodProteinsdb.psq"
	output:
		config["dbDir"] + "blastout.tsv"
	shell:
		'ZVALUE=$(blastdbcmd -info -db '+ config["dbDir"] +'goodProteinsdb|'
		'grep -E "([0-9,]{{2,8}}) sequences"|'
		'cut -d " " -f 1 | tr -d ,)&&'
		'blastall -z $ZVALUE -i ' + config["filterDir"] + 'goodProteins.fasta -d '+
		config["dbDir"] + '/goodProteinsdb '
		'-m 8 -p blastp -F "m S" -v 100000 -b 100000 -e 1e-5 -o {output}'

rule parseBlast:
	input:
		config["dbDir"] + "blastout.tsv"
	output:
		config["orthomcl"] + "similarSequences.txt"
	shell:
		"orthomclBlastParser {input} " + config["adjustedDir"] +
		" >> {output}"

rule clearDb:
	input:
		config["orthomcl"] + "similarSequences.txt"
	output:
		touch(config["checkpoints"] + "clear.done")
	run:
		import mysql.connector
		# change credentials to match your mySQL login - connect
		cnx = mysql.connector.connect(user='root', password='dv6109', database='orthomcl')
		cursor = cnx.cursor()

		#truncate similar sequences table before next rule
		cursor.execute('TRUNCATE SimilarSequences;')

		#close connections
		cursor.close()
		cnx.close()

rule loadBlast:
	input:
		config["checkpoints"] + "clear.done"
	output:
		touch(config["checkpoints"] + "load.done")
	shell:
		"rm " + config["checkpoints"] + "clear.done&&"
		"orthomclPairs orthomcl.config "+ config["checkpoints"] + "cleanup.log cleanup=only&&"
		"orthomclLoadBlast orthomcl.config " + config["orthomcl"] + "similarSequences.txt"
		
rule findPairs:
	input:
		config["checkpoints"] + "load.done"
	output:
		config["checkpoints"] + "pairs.log"
	shell:
		"rm " + config["checkpoints"] + "load.done&& "
		"orthomclPairs orthomcl.config {output} cleanup=yes"
		

rule getPairsFiles:
	input:
		config["checkpoints"] + "pairs.log"
	output:
		touch(config["checkpoints"] + "dump.done")
	shell:
		"if [ -d 'pairs' ]; then rm -r pairs; fi&&"
		"orthomclDumpPairsFiles orthomcl.config&&"
		"mv pairs/ " + config["orthomcl"] + "&&"
		"mv mclInput" + config["orthomcl"] + "pairs/"

rule plotResults:
	input:
		config["checkpoints"] + "dump.done"
	output:
		config["orthomcl"] + "barchart.jpg"
	shell:
		"Rscript barchart.R " + config["orthomcl"] + "pairs/ {output}"

rule clean:
	shell:
		"if [ -d '" + config["adjustedDir"] + "' ]; then rm -r "+ config["adjustedDir"] +"; fi&&"
		"if [ -d '" + config["filterDir"] + "' ]; then rm -r "+ config["filterDir"] + "; fi&&"
		"if [ -d '" + config["dbDir"] + "' ]; rm -r "+ config["dbDir"] + "; fi&&"
		"if [ -d '" + config["checkpoints"] + "' ]; rm -r "+ config["checkpoints"] + "; fi"


rule cleanAfterBlast:
	shell:
		"if [ -d 'pairs' ]; then rm -r pairs; fi&&"
		"rm orthomcl/*"

