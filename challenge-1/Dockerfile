FROM ubuntu:24.04

RUN useradd -ms /bin/bash appuser

WORKDIR /bin

ADD ./challenge-1 /usr/local/bin

USER appuser

EXPOSE 8000

ENTRYPOINT ["challenge-1"]