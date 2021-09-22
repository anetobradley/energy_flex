FROM rocker/verse

RUN mkdir /code/
RUN mkdir /data/
RUN mkdir /data/outputs/
COPY . /code/
WORKDIR /code/

RUN apt-get update \
    && apt-get install r-base-core libssl-dev libcurl4-openssl-dev -y 

# Install clang to use as compiler
# clang seems to be more memory efficient with the templates than g++
# with g++ rstan cannot compile on docker hub due to memory issues
RUN apt-get update \ 
	&& apt-get install -y --no-install-recommends \
                   clang

# Global site-wide config
RUN mkdir -p $HOME/.R/ \
    && echo "\nCXX=clang++ -ftemplate-depth-256\n" >> $HOME/.R/Makevars \
    && echo "CC=clang\n" >> $HOME/.R/Makevars

RUN install2.r --error --deps TRUE \
   rstan \
   && rm -rf /tmp/downloaded_packages/ /tmp/*.rds


RUN Rscript /code/install_packages.R

# ARG CHAINS
# ARG SAMPLES
# ARG AUTHORITY

# ENV LOCAL_AUTHORITY ${AUTHORITY}
# ENV MCMC_SAMPLES ${SAMPLES}
# ENV MCMC_CHAINS ${CHAINS}

CMD Rscript /code/Stan_Energy_Intensity_Base.R 
#CMD sleep 24h


