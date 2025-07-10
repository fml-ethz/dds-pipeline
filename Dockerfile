FROM python:3.10-slim

# Install OpenJDK-11 and build tools
RUN apt-get update && apt-get install -y default-jre wget g++ make cmake git libboost-all-dev && apt-get clean;


# 
# DT4DDS
# 
RUN pip install dt4dds


# 
# BBMap
# 
RUN mkdir /bbmap && cd /bbmap && wget https://sourceforge.net/projects/bbmap/files/BBMap_38.99.tar.gz/download && tar -zxvf download --strip-components=1 -C .
RUN mkdir -p ~/.local/bin/ && ln -s /bbmap ~/.local/bin/bbmap


# 
# DNA RS Coding
# 
RUN mkdir /dnars && git clone https://github.com/agimpel/dna_rs_coding.git /dnars
RUN cd /dnars/simulate && make texttodna


# 
# NGmerge
# 
RUN mkdir /ngmerge && git clone https://github.com/jsh58/NGmerge.git /ngmerge
RUN cd /ngmerge && make


# 
# CD-HIT
# 
RUN mkdir /cdhit && git clone https://github.com/weizhongli/cdhit.git /cdhit
RUN cd /cdhit && make


# 
# kalign
# 
RUN mkdir /kalign && git clone https://github.com/TimoLassmann/kalign.git /kalign
RUN cd /kalign && mkdir build && cd build && cmake .. && make


# 
# Setup
# 
RUN mkdir /scripts && mkdir /data && mkdir /demo
COPY scripts/ /scripts/
RUN chmod -R 700 /scripts
COPY demo/raw/ /demo/
RUN chmod -R 700 /demo
WORKDIR /data