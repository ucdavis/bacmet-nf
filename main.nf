#!/usr/bin/env nextflow
params.reads = "$baseDir/test_input/*"
params.gene_result_column = 1
params.db = "PRE"

process BACMET{
    publishDir "$baseDir/out", mode: 'copy'

    input:
    path fasta

    output:
    path "${fasta.getName().replace(".gz", "")}.tsv"

    script:
    def prefix = fasta.getSimpleName()
    def is_compressed = fasta.getName().endsWith(".gz") ? true : false
    def fasta_name = fasta.getName().replace(".gz", "")
    """
    if [ "$is_compressed" == "true" ]; then
        gzip -c -d $fasta > $fasta_name
    fi

    cp /home/bacmet/* .

    BacMet-Scan -i $fasta_name -d $params.db -o ${fasta_name}
    mv ${fasta_name}.table ${fasta_name}.tsv
    """
}

process CSV{
    publishDir "$baseDir/out", mode: 'copy'

    input:
    val tables

    output:
    path 'bacmet_results.csv'

    exec:
    gene_list = []
    results = [:]
    tables.each { table ->
        sample_genes = []
        sample = file(table)
        allLines = sample.readLines()
        allLines.remove(0)//strip table header
        for( line : allLines ) {
            result = line.split()[params.gene_result_column]
            sample_genes.push(result)
        }
        sample_genes.unique()
        gene_list += sample_genes
        sample_name = sample.name.split("\\.").first()
        results[sample_name] = sample_genes
    }
    result_table = ""
    gene_list.unique().sort()
    results = results.sort()
    results.each{ sample_name, genes ->
        result_row = []
        gene_list.each { gene ->
            if (genes.contains(gene)){
                result_row += 1
            } else{
                result_row += 0
            }
        }
        result_row.push(sample_name)
        result_table += result_row.join(',') + "\n"
    }

    //clean gene names to only show first two identifiers
    gene_list = gene_list.collect{ "${it.split('\\|')[0]}|${it.split('\\|')[1]}" }

    gene_list.push('Isolate')
    headers = gene_list.join(',') + "\n"
    result_table = headers + result_table

    csv_file = task.workDir.resolve('bacmet_results.csv')
    csv_file.text = result_table
}

workflow {
    input_seqs = Channel
        .fromPath(params.reads)

    BACMET(input_seqs)
    CSV(BACMET.out.collect())
}
