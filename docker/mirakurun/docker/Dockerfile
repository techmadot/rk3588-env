FROM node:18.14.1-bullseye-slim AS build

WORKDIR /tmp
RUN apt update && apt install -y --no-install-recommends \
    build-essential \
    git curl cmake autoconf automake ca-certificates \
    libpcsclite-dev \
    &&  \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/stz2012/recpt1.git
RUN git clone https://github.com/stz2012/libarib25.git
RUN git clone https://github.com/qpe/recdvb.git

## COMPILE
RUN cd /tmp/libarib25; \
  git checkout -f ab6afa7c7f4022af7dda7976489ec7a0716efb9a && \
  cmake . && make && make install

RUN cd /tmp/recpt1/recpt1 && \
  git checkout -f fd64ce07b285a182b64a92f33a9549c0fa951be5 && \
  ./autogen.sh && \
  ./configure --enable-b25 && \
  make

RUN cd /tmp/recdvb;    \
  git checkout -f 06fb49fdd951a18a0be0ad142101750efcc0db60 && \
  ./autogen.sh && \
  ./configure --enable-b25 && \
  make

FROM chinachu/mirakurun:3.9.0-rc.2
COPY --from=build /tmp/libarib25/libarib25.so* /usr/lib/aarch64-linux-gnu/
COPY --from=build /tmp/recpt1/recpt1/recpt1* /usr/local/bin/
COPY --from=build /tmp/recdvb/recdvb         /usr/local/bin/

