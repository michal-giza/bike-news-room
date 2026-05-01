FROM rust:1.82-slim AS builder
WORKDIR /app
RUN apt-get update && apt-get install -y pkg-config libssl-dev && rm -rf /var/lib/apt/lists/*
COPY Cargo.toml Cargo.lock ./
COPY src/ src/
RUN cargo build --release

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/target/release/bike-news-room /usr/local/bin/
COPY feeds.toml /etc/bike-news-room/
EXPOSE 7860
ENV DATABASE_URL="sqlite:///data/bike_news.db"
ENV FEEDS_PATH="/etc/bike-news-room/feeds.toml"
CMD ["bike-news-room"]
