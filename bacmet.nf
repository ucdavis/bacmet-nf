#!/usr/bin/env nextflow
params.reads = "$baseDir/../data/*.{fasta,fsa}"
params.bacmet_exe = "$baseDir/BacMet-Scan"
params.db_name = "BacMet_EXP_database.fasta"
params.db_fasta = "$baseDir/${params.db_name}"
params.mapping_file = "$baseDir/BacMet_EXP.753.mapping.txt"
params.gene_result_column = 1

process run_bacmet{
    publishDir "$baseDir/out", mode: 'copy'
    
    input:
    path bacmet
    path sequence_file
    path db_fasta
    path db_map
 
    output:
    path "${sequence_file}.tsv"

    """
    perl BacMet-Scan -i ${sequence_file} -d EXP -o ${sequence_file}
    mv '$sequence_file'.table '$sequence_file'.tsv
    """
}

process create_csv{
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
    reads_ch = Channel.fromPath(params.reads)
    run_bacmet(params.bacmet_exe,reads_ch,params.db_fasta,params.mapping_file)
    create_csv(run_bacmet.out.collect())
}