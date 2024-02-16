FROM debian:bullseye-slim

RUN apt-get update -qq; \
    apt-get install --no-install-recommends -y -qq ncbi-blast+;
