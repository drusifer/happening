FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/*
COPY bin/happening-proxy /usr/local/bin/happening-proxy
RUN chmod +x /usr/local/bin/happening-proxy
CMD ["/usr/local/bin/happening-proxy"]
