#!/usr/bin/env nextflow
params.input = "$baseDir/test_input"
params.output = "$baseDir/out"
params.db = "EXP"
params.gzip = false

process BACMET{
    publishDir params.output, mode: 'copy'

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

    ln -s /home/bacmet/*.fasta .
    ln -s /home/bacmet/*.txt .

    BacMet-Scan -i $fasta_name -d $params.db -o ${fasta_name}
    mv ${fasta_name}.table ${fasta_name}.tsv

    #bacmet leaves a trailing tab :(
    sed -i "1s/\t\$//" ${fasta_name}.tsv
    """
}

process CSV{
    publishDir params.output, mode: 'copy'

    input:
    val tables

    output:
    path 'bacmet_results.csv'

    exec:
    gene_list = []
    results = [:]
    tables.each { table ->
        sample_genes = []


        table
            .splitCsv(header:true,sep:"\t")
            .each {row -> sample_genes.push(row["Subject"])}

        sample_genes.unique()
        gene_list += sample_genes

        sample_name = table.name.split("\\.").first()
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
    gene_list = gene_list.collect{ gene ->
        matcher = gene =~ /^([^|]+\|[^|]+)\|/
        if (matcher.find()){
            return matcher.group(1)
        }
    }
    gene_list.push('Isolate')
    headers = gene_list.join(',') + "\n"
    result_table = headers + result_table

    csv_file = task.workDir.resolve('bacmet_results.csv')
    csv_file.text = result_table
}

process ZIP{
    publishDir "$baseDir/out", mode: 'copy'

    input:
    path files
    path csv

    output:
    path '*.tar.gz'

    """
    current_date=\$(date +"%d-%m-%Y")
    outfile="bacmet_${params.db}_\${current_date}.tar.gz"
    tar -chzf \${outfile} ${files.join(' ')} $csv
    """
}

workflow {
    input_seqs = Channel
        .fromPath("$params.input/*{fas,gz,fasta,fsa,fsa.gz,fas.gz}")

    BACMET(input_seqs)
    results = BACMET.out.collect()
    CSV(results)
    if (params.gzip){
        ZIP(results,CSV.out)
    }
}
