#!/bin/bash

set -e  # Encerra em caso de erro

# Variáveis principais
DATA_DIR=~/CourseData/RNA_data/trinity_trinotate_tutorial_2018
WORK_DIR=~/workspace/trinity_and_trinotate
THREADS=2
MEMORY=2G

echo "[1] Criando ambiente de trabalho..."
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"
cp -r "$DATA_DIR/C_glabrata" data

echo "[2] Executando Trinity para montagem de novo..."
$TRINITY_HOME/Trinity --seqType fq --samples_file data/samples.txt \
  --CPU $THREADS --max_memory $MEMORY --min_contig_length 150

echo "[3] Quantificando expressão com Salmon..."
$TRINITY_HOME/util/align_and_estimate_abundance.pl --seqType fq \
  --samples_file data/samples.txt \
  --transcripts trinity_out_dir/Trinity.fasta \
  --est_method salmon --trinity_mode --prep_reference

echo "[4] Gerando matrizes de contagem e TPM..."
find wt_* GSNO_* -name "quant.sf" | tee quant_files.list
$TRINITY_HOME/util/abundance_estimates_to_matrix.pl --est_method salmon \
  --out_prefix Trinity --name_sample_by_basedir \
  --quant_files quant_files.list \
  --gene_trans_map trinity_out_dir/Trinity.fasta.gene_trans_map

echo "[5] Análise de expressão diferencial com DESeq2..."
$TRINITY_HOME/Analysis/DifferentialExpression/run_DE_analysis.pl \
  --matrix Trinity.isoform.counts.matrix \
  --samples_file data/samples.txt \
  --method DESeq2 --output DESeq2_trans

echo "[6] Extraindo genes diferencialmente expressos + heatmap..."
cd DESeq2_trans
$TRINITY_HOME/Analysis/DifferentialExpression/analyze_diff_expr.pl \
  --matrix ../Trinity.isoform.TMM.EXPR.matrix \
  --samples ../data/samples.txt -P 1e-3 -C 2
$TRINITY_HOME/Analysis/DifferentialExpression/define_clusters_by_cutting_tree.pl \
  --Ptree 60 -R diffExpr.P1e-3_C2.matrix.RData
cd ..

echo "[7] Análise de expressão diferencial a nível de gene..."
$TRINITY_HOME/Analysis/DifferentialExpression/run_DE_analysis.pl \
  --matrix Trinity.gene.counts.matrix \
  --samples_file data/samples.txt \
  --method DESeq2 --output DESeq2_gene

echo "[8] Anotação funcional com Trinotate..."
mkdir -p Trinotate && cd Trinotate
$TRANSDECODER_HOME/TransDecoder.LongOrfs -t ../trinity_out_dir/Trinity.fasta
$TRANSDECODER_HOME/TransDecoder.Predict -t ../trinity_out_dir/Trinity.fasta

blastx -db ../data/mini_sprot.pep -query ../trinity_out_dir/Trinity.fasta \
  -num_threads $THREADS -max_target_seqs 1 -outfmt 6 -evalue 1e-5 \
  > swissprot.blastx.outfmt6

blastp -query Trinity.fasta.transdecoder.pep -db ../data/mini_sprot.pep \
  -num_threads $THREADS -max_target_seqs 1 -outfmt 6 -evalue 1e-5 \
  > swissprot.blastp.outfmt6

hmmscan --cpu $THREADS --domtblout TrinotatePFAM.out \
  ../data/trinotate_data/Pfam-A.hmm Trinity.fasta.transdecoder.pep

signalp -f short -n signalp.out Trinity.fasta.transdecoder.pep

cp ../data/trinotate_data/Trinotate.boilerplate.sqlite Trinotate.sqlite
chmod 644 Trinotate.sqlite

$TRINOTATE_HOME/Trinotate Trinotate.sqlite init \
  --gene_trans_map ../trinity_out_dir/Trinity.fasta.gene_trans_map \
  --transcript_fasta ../trinity_out_dir/Trinity.fasta \
  --transdecoder_pep Trinity.fasta.transdecoder.pep

$TRINOTATE_HOME/Trinotate Trinotate.sqlite LOAD_swissprot_blastx swissprot.blastx.outfmt6
$TRINOTATE_HOME/Trinotate Trinotate.sqlite LOAD_swissprot_blastp swissprot.blastp.outfmt6
$TRINOTATE_HOME/Trinotate Trinotate.sqlite LOAD_pfam TrinotatePFAM.out
$TRINOTATE_HOME/Trinotate Trinotate.sqlite LOAD_signalp signalp.out

$TRINOTATE_HOME/Trinotate Trinotate.sqlite report > Trinotate.xls

echo "[9] Carregando dados no Trinotate para uso com TrinotateWeb..."
$TRINOTATE_HOME/util/transcript_expression/import_expression_and_DE_results.pl \
  --sqlite Trinotate.sqlite --transcript_mode \
  --samples_file ../data/samples.txt \
  --count_matrix ../Trinity.isoform.counts.matrix \
  --fpkm_matrix ../Trinity.isoform.TMM.EXPR.matrix

$TRINOTATE_HOME/util/transcript_expression/import_expression_and_DE_results.pl \
  --sqlite Trinotate.sqlite --transcript_mode \
  --samples_file ../data/samples.txt --DE_dir ../DESeq2_trans

$TRINOTATE_HOME/util/transcript_expression/import_transcript_clusters.pl \
  --sqlite Trinotate.sqlite \
  --group_name DE_all_vs_all \
  --analysis_name diffExpr.P1e-3_C2_clusters_fixed_P_60 \
  ../DESeq2_trans/diffExpr.P1e-3_C2.matrix.RData.clusters_fixed_P_60/*matrix

$TRINOTATE_HOME/util/transcript_expression/import_expression_and_DE_results.pl \
  --sqlite Trinotate.sqlite --gene_mode \
  --samples_file ../data/samples.txt \
  --count_matrix ../Trinity.gene.counts.matrix \
  --fpkm_matrix ../Trinity.gene.TMM.EXPR.matrix

$TRINOTATE_HOME/util/transcript_expression/import_expression_and_DE_results.pl \
  --sqlite Trinotate.sqlite --gene_mode \
  --samples_file ../data/samples.txt --DE_dir ../DESeq2_gene

echo "[10] Pipeline completo! Você pode agora iniciar o servidor do TrinotateWeb com:\n"
echo "$TRINOTATE_HOME/run_TrinotateWebserver.pl 8080"
