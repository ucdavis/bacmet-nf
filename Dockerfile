FROM debian:bullseye-slim

RUN apt-get update -qq; \
    apt-get install --no-install-recommends -y -qq ncbi-blast+;


ADD http://bacmet.biomedicine.gu.se/download/BacMet-Scan /usr/local/bin/
RUN chmod +x /usr/local/bin/BacMet-Scan
RUN mkdir /home/bacmet; mkdir /home/bacmet/PRE; mkdir /home/bacmet/EXP
WORKDIR /home/bacmet

# ADD http://bacmet.biomedicine.gu.se/download/BacMet2_EXP_database.fasta /home/bacmet/EXP/BacMet_EXP_database.fasta
# ADD http://bacmet.biomedicine.gu.se/download/BacMet2_predicted_database.fasta.gz /home/bacmet/PRE
# ADD http://bacmet.biomedicine.gu.se/download/BacMet2_EXP.753.mapping.txt /home/bacmet/EXP
# ADD http://bacmet.biomedicine.gu.se/download/BacMet2_PRE.155512.mapping.txt /home/bacmet/PRE

ADD http://bacmet.biomedicine.gu.se/download/BacMet2_EXP_database.fasta /home/bacmet/EXP
ADD http://bacmet.biomedicine.gu.se/download/BacMet2_predicted_database.fasta.gz /home/bacmet/PRE
ADD http://bacmet.biomedicine.gu.se/download/BacMet2_EXP.753.mapping.txt /home/bacmet/EXP
ADD http://bacmet.biomedicine.gu.se/download/BacMet2_PRE.155512.mapping.txt /home/bacmet/PRE

# RUN gunzip PRE/BacMet2_predicted_database.fasta.gz; mv PRE/BacMet2_predicted_database.fasta PRE/BacMet_PRE_database.fasta
RUN gunzip PRE/BacMet2_predicted_database.fasta.gz;
