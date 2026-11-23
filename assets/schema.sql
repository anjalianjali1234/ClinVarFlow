CREATE TABLE IF NOT EXISTS samples(sample_id text PRIMARY KEY,patient text NOT NULL,type text NOT NULL);
CREATE TABLE IF NOT EXISTS runs(run_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, run_key text UNIQUE NOT NULL,pipeline_version text NOT NULL,started_at timestamptz DEFAULT now());
CREATE TABLE IF NOT EXISTS variants(variant_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,run_id bigint REFERENCES runs,sample_id text REFERENCES samples,chrom text,pos bigint,ref text,alt text,kind text,filter text,vaf real,depth integer,UNIQUE(run_id,sample_id,chrom,pos,ref,alt,kind));
CREATE TABLE IF NOT EXISTS annotations(variant_id bigint PRIMARY KEY REFERENCES variants ON DELETE CASCADE,gene text,consequence text,impact text,hgvsc text,hgvsp text,clinvar text,gnomad_af real,tier smallint);
CREATE INDEX IF NOT EXISTS annotations_gene ON annotations(gene);
CREATE INDEX IF NOT EXISTS variants_locus ON variants(chrom,pos);
CREATE TABLE IF NOT EXISTS fusions(run_id bigint REFERENCES runs,sample_id text REFERENCES samples,gene1 text,gene2 text,breakpoint1 text,breakpoint2 text,callers text,confidence text);
CREATE TABLE IF NOT EXISTS cnv_segments(run_id bigint REFERENCES runs,sample_id text REFERENCES samples,chrom text,start_pos bigint,end_pos bigint,log2 real,cn integer,genes text[]);
CREATE TABLE IF NOT EXISTS sv_calls(run_id bigint REFERENCES runs,sample_id text REFERENCES samples,chrom text,pos bigint,end_pos bigint,svtype text,svlen bigint,callers text);
