# ---------------------------------------------------------------------------------------------------------------
#
# builder stage
#
# ---------------------------------------------------------------------------------------------------------------
FROM rust:1.60-alpine3.14 AS builder

WORKDIR /home/root/src
USER root

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories
RUN apk add musl-dev linux-headers libressl-dev
RUN rustup target add x86_64-unknown-linux-musl

# download and cache cargo crate
COPY ./crates/relayer-cli/src/bin/hermes/main.rs ./crates/relayer-cli/src/bin/hermes/main.rs
COPY ./crates/relayer/src/lib.rs ./crates/relayer/src/lib.rs
COPY ./crates/chain-registry/src/lib.rs ./crates/chain-registry/src/lib.rs
COPY ./crates/chain-registry/Cargo.toml ./crates/chain-registry/Cargo.toml
COPY ./crates/relayer-types/Cargo.toml ./crates/relayer-types/Cargo.toml
COPY ./crates/relayer-types/src/lib.rs ./crates/relayer-types/src/lib.rs
COPY ./crates/relayer/Cargo.toml ./crates/relayer/Cargo.toml
COPY ./crates/relayer-cli/Cargo.toml ./crates/relayer-cli/Cargo.toml
COPY ./crates/relayer-rest/Cargo.toml ./crates/relayer-rest/Cargo.toml
COPY ./crates/relayer-rest/src/lib.rs ./crates/relayer-rest/src/lib.rs
COPY ./crates/telemetry/Cargo.toml ./crates/telemetry/Cargo.toml
COPY ./crates/telemetry/src/lib.rs ./crates/telemetry/src/lib.rs
COPY ./tools ./tools
COPY Cargo.toml .
COPY Cargo.lock .

RUN cargo fetch

# copy source code
COPY . .

# build with cache --features=profiling
RUN --mount=type=cache,target=/home/root/src/target \
		cargo build --release --bin hermes --target x86_64-unknown-linux-musl && \
		cp target/x86_64-unknown-linux-musl/release/hermes /usr/local/bin/

# ---------------------------------------------------------------------------------------------------------------
#
# build final image stage
#
# ---------------------------------------------------------------------------------------------------------------
FROM alpine:edge
WORKDIR root
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories && apk add --update --no-cache ca-certificates libressl-dev

COPY --chown=0:0 --from=builder /usr/local/bin/hermes /usr/local/bin/

RUN ldd /usr/local/bin/hermes

ENTRYPOINT ["/usr/local/bin/hermes"]