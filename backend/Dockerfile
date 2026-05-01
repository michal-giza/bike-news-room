# Rust 1.86 is the minimum that supports `edition2024` — required by indexmap
# 2.14+ and other transitive deps in the workspace.
FROM rust:1.86-slim-bookworm AS builder
WORKDIR /app
RUN apt-get update \
 && apt-get install -y --no-install-recommends pkg-config libssl-dev ca-certificates \
 && rm -rf /var/lib/apt/lists/*
# Copy the manifest first so cargo's layer cache can be reused when source
# changes but deps don't.
COPY Cargo.toml Cargo.lock ./
COPY src/ src/
COPY tests/ tests/
RUN cargo build --release --bin bike-news-room

FROM debian:bookworm-slim
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# /data is the conventional persistent path on Hugging Face Spaces with
# persistent storage enabled. Without it, SQLite still works but is wiped on
# container restart.
RUN mkdir -p /data /etc/bike-news-room
COPY --from=builder /app/target/release/bike-news-room /usr/local/bin/
COPY feeds.toml /etc/bike-news-room/

EXPOSE 7860
ENV DATABASE_URL="sqlite:///data/bike_news.db?mode=rwc"
ENV FEEDS_PATH="/etc/bike-news-room/feeds.toml"
CMD ["bike-news-room"]
