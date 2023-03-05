FROM techmadot/opi5-base:1.1.2-bullseye as builder

RUN apt update
RUN apt install -y cmake build-essential python3-pip flex bison pkg-config libxml2-dev
RUN pip3 install meson ninja
RUN mkdir -p /repos && mkdir -p /opt

WORKDIR /tmp
ADD setup-gstreamer.sh /tmp
RUN chmod +x /tmp/setup-gstreamer.sh && /tmp/setup-gstreamer.sh
RUN tar -cJvf gstreamer-binaries.tar.xz -C /opt gstreamer


FROM techmadot/opi5-base:1.1.2-bullseye
RUN apt update && apt install ffmpeg --no-install-recommends
COPY --from=builder /tmp/gstreamer-binaries.tar.xz /tmp/
RUN tar -xJf /tmp/gstreamer-binaries.tar.xz -C /opt/
