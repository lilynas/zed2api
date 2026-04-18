FROM node:22-bookworm-slim AS build

RUN apt-get update && apt-get install -y curl xz-utils jq

WORKDIR /build

# Download latest Zig master (0.15.x)
RUN ZIG_URL=$(curl -s https://ziglang.org/download/index.json | jq -r '.master."x86_64-linux".tarball') && \
    curl -O $ZIG_URL && \
    tar xf z*.tar.xz && \
    mv zig-linux-x86_64-* /usr/local/zig && \
    ln -s /usr/local/zig/zig /usr/local/bin/zig

COPY . .

# Build webui dependencies and compile the executable
RUN cd webui && npm install
RUN zig build -Doptimize=ReleaseSafe

# --- Final image ---
FROM debian:bookworm-slim

# Install CA certificates for HTTPS requests to upstream APIs
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /app/data
COPY --from=build /build/zig-out/bin/zed2api /app/zed2api

ENV HTTP_PORT=8000
EXPOSE 8000

VOLUME ["/app/data"]

CMD ["/bin/sh", "-c", "/app/zed2api serve ${HTTP_PORT}"]
