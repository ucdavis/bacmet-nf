FROM debian:bullseye-slim

RUN apt-get update -qq; \
    apt-get install --no-install-recommends -y -qq ncbi-blast+;


ADD http://bacmet.biomedicine.gu.se/download/BacMet-Scan /usr/local/bin/
RUN chmod +x /usr/local/bin/BacMet-Scan
RUN mkdir /home/bacmet;
WORKDIR /home/bacmet

ADD http://bacmet.biomedicine.gu.se/download/BacMet2_EXP_database.fasta /home/bacmet/BacMet_EXP_database.fasta
ADD http://bacmet.biomedicine.gu.se/download/BacMet2_predicted_database.fasta.gz /home/bacmet/BacMet_PRE_database.fasta.gz
ADD http://bacmet.biomedicine.gu.se/download/BacMet2_EXP.753.mapping.txt /home/bacmet/BacMet_EXP.753.mapping.txt
ADD http://bacmet.biomedicine.gu.se/download/BacMet2_PRE.155512.mapping.txt /home/bacmet/BacMet_PRE.155512.mapping.txt

RUN gunzip BacMet_PRE_database.fasta.gz;
