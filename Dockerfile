FROM rust:1-bookworm as builder-arm64

RUN apt update && apt upgrade -y
RUN apt install -yq --no-install-recommends g++-arm-linux-gnueabihf libc6-dev-armhf-cross

ENV RUST_TARGET=armv7-unknown-linux-gnueabihf

RUN rustup target add armv7-unknown-linux-gnueabihf
RUN rustup toolchain install stable-armv7-unknown-linux-gnueabihf

ENV CARGO_TARGET_ARMV7_UNKNOWN_LINUX_GNUEABIHF_LINKER=arm-linux-gnueabihf-gcc \
    CC_armv7_unknown_linux_gnueabihf=arm-linux-gnueabihf-gcc \
    CXX_armv7_unknown_linux_gnueabihf=arm-linux-gnueabihf-g++

FROM rust:1-bookworm as builder-amd64

ENV RUST_TARGET=x86_64-unknown-linux-gnu
RUN apt-get update && apt-get dist-upgrade -yq

FROM builder-${TARGETARCH:-"amd64"} as builder

WORKDIR /code

COPY . .

ARG FEATURES=${FEATURES:-"--all-features"}
RUN cargo build --release --target ${RUST_TARGET} ${FEATURES}

RUN cp /code/target/${RUST_TARGET}/release/oura /oura

FROM debian:bookworm-slim as release

RUN apt-get update && \
    apt-get upgrade -yq && \
    apt-get install -yq --no-install-recommends ca-certificates && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /oura /usr/local/bin/oura

ENTRYPOINT [ "oura" ]
