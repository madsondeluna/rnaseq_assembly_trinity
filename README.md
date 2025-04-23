# Workshop: Trinity and Trinotate for RNA-Seq Analysis

## Sobre o Workshop

Este workshop fornece um guia completo para:

- Montagem *de novo* de transcriptoma com Trinity
- Quantificação de expressão com Salmon
- Análise de expressão diferencial com DESeq2
- Anotação funcional com Trinotate
- Exploração interativa com TrinotateWeb

---

## Ambiente

```bash
source ~/CourseData/RNA_data/trinity_trinotate_tutorial_2018/environment.txt
mkdir -p ~/workspace/trinity_and_trinotate
cd ~/workspace/trinity_and_trinotate
```

## Dados Utilizados

Os dados utilizados são provenientes do estudo de Linde et al. (2015), com amostras de *Candida glabrata* nas condições WT e GSNO, com 3 repetições biológicas cada.

```bash
cp -r ~/CourseData/RNA_data/trinity_trinotate_tutorial_2018/C_glabrata data
ls -1 data/* | grep fastq
```

---

## Etapas Principais

### 1. Montagem *de novo* com Trinity

```bash
$TRINITY_HOME/Trinity --seqType fq --samples_file data/samples.txt \
--CPU 2 --max_memory 2G --min_contig_length 150
```

### 2. Quantificação com Salmon

```bash
$TRINITY_HOME/util/align_and_estimate_abundance.pl --seqType fq \
--samples_file data/samples.txt --transcripts trinity_out_dir/Trinity.fasta \
--est_method salmon --trinity_mode --prep_reference
```

### 3. Geração de Matrizes

```bash
find wt_* GSNO_* -name "quant.sf" | tee quant_files.list

$TRINITY_HOME/util/abundance_estimates_to_matrix.pl --est_method salmon \
--out_prefix Trinity --name_sample_by_basedir \
--quant_files quant_files.list \
--gene_trans_map trinity_out_dir/Trinity.fasta.gene_trans_map
```

### 4. Análise de Expressão Diferencial com DESeq2

```bash
$TRINITY_HOME/Analysis/DifferentialExpression/run_DE_analysis.pl \
--matrix Trinity.isoform.counts.matrix \
--samples_file data/samples.txt \
--method DESeq2 \
--output DESeq2_trans
```

### 5. Anotação Funcional com Trinotate

```bash
mkdir Trinotate && cd Trinotate

$TRANSDECODER_HOME/TransDecoder.LongOrfs -t ../trinity_out_dir/Trinity.fasta
$TRANSDECODER_HOME/TransDecoder.Predict -t ../trinity_out_dir/Trinity.fasta
```

### 6. Relatório e Web Interface (TrinotateWeb)

```bash
$TRINOTATE_HOME/run_TrinotateWebserver.pl 8080
```

Acesse: [http://localhost:8080/cgi-bin/index.cgi](http://localhost:8080/cgi-bin/index.cgi)

---

## Programas Auxiliares Necessários

### Ferramentas obrigatórias

- **samtools**
- **bam-readcount**
- **HISAT2**
- **StringTie**
- **gffcompare**
- **htseq-count**
- **flexbar**
- **R** e bibliotecas CRAN/Bioconductor
- **ballgown**, **edgeR**, **genefilter**, **biomaRt**, **rhdf5**, **GenomicRanges**
- **fastqc** e **multiqc**
- **picard-tools**
- **kallisto**
- **regtools**
- **RSeQC**
- **bedtools** (exercício prático)

### Exemplo de instalação local

```bash
cd $RNA_HOME
mkdir -p student_tools && cd student_tools

# SAMtools
wget https://github.com/samtools/samtools/releases/download/1.9/samtools-1.9.tar.bz2
bunzip2 samtools-1.9.tar.bz2 && tar -xvf samtools-1.9.tar
cd samtools-1.9 && make
```

*(Repita a lógica para os demais softwares acima conforme instruções do tutorial oficial)*

### Exemplo de adicionar ao PATH:

```bash
export PATH=$RNA_HOME/student_tools/samtools-1.9:$RNA_HOME/student_tools/hisat2-2.1.0:$PATH
export LD_LIBRARY_PATH=$RNA_HOME/student_tools/flexbar-3.4.0-linux:$LD_LIBRARY_PATH
```

Para tornar essas mudanças permanentes:

```bash
vi ~/.bashrc
# Adicione as variáveis acima e salve com :wq
source ~/.bashrc
```

---

## Recursos

- Documentação oficial Trinity: [http://trinityrnaseq.github.io](http://trinityrnaseq.github.io)
- Documentação completa do curso: [https://rnabio.org](https://rnabio.org)
- Material original: [https://bioinformaticsdotca.github.io/rnaseq\_2018#preworkshop ](https://bioinformaticsdotca.github.io/rnaseq_2018#preworkshop )

##
