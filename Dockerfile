FROM ubuntu:latest AS build_stage

WORKDIR /
RUN apt update -qq \
    && apt install -yy \
        git \
        python \
        python-pip \
        build-essential \
        automake \
        libtool \
        m4 \
        autoconf \
        libevent-dev \
        libssl-dev \
        libc-ares-dev \
        pkg-config \
        pandoc \
    && pip install docutils

ADD . src

WORKDIR /bin
RUN ln -s ../usr/bin/rst2man.py rst2man

WORKDIR /src
RUN mkdir /pgbouncer
# RUN git submodule init
# RUN git submodule update
RUN ./autogen.sh
RUN ./configure --prefix=/pgbouncer --with-libevent=/usr/lib
RUN make
RUN make install
RUN ls -R /pgbouncer

FROM ubuntu:latest
RUN apt update -qq \
    && apt install -yy \
        libevent-dev \
        libssl-dev \
        libc-ares-dev \
        valgrind

WORKDIR /
COPY --from=build_stage /pgbouncer /pgbouncer

# Use a constant GID 2111 for pgsockets so we can explicitly match it in postgres
RUN adduser pgb \
    && groupadd -g 2111 pgsockets \
    && usermod -aG pgsockets pgb

USER pgb

WORKDIR /home/pgb

CMD ["/pgbouncer/bin/pgbouncer", "pgbouncer.ini"]

# CMD ["valgrind", "--leak-check=full", "/pgbouncer/bin/pgbouncer", "/etc/postgres.ini"]

# ADD entrypoint.sh ./
# ENTRYPOINT ["./entrypoint.sh"]
