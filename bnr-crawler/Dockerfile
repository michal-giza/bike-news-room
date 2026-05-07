# Builder — pulls deps, compiles release binary, then we copy just
# the binary into a slim runtime image. Same shape as the main backend's
# Dockerfile so the deploy ergonomics match.
FROM rust:1.83-slim AS builder
WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    pkg-config \
 && rm -rf /var/lib/apt/lists/*

COPY Cargo.toml Cargo.lock* ./
COPY src ./src

# Build with the release profile defined in Cargo.toml (LTO + strip).
RUN cargo build --release

# Runtime — Debian slim with just the dynamic libs reqwest+rustls need.
FROM debian:bookworm-slim AS runtime

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/* \
 && useradd -m -u 1000 crawler

COPY --from=builder /app/target/release/bnr-crawler /usr/local/bin/bnr-crawler
USER crawler
WORKDIR /home/crawler

# HF Spaces routes external HTTPS traffic to port 7860 by convention.
EXPOSE 7860
ENV PORT=7860
ENV RUST_LOG=info

CMD ["/usr/local/bin/bnr-crawler"]
