FROM node:22-bookworm-slim AS build

RUN apt-get update && apt-get install -y curl xz-utils

WORKDIR /build

# Download Zig 0.16.0 (stable)
ARG ZIG_VERSION=0.15.2
RUN curl -L -o zig.tar.xz "https://ziglang.org/download/${ZIG_VERSION}/zig-x86_64-linux-${ZIG_VERSION}.tar.xz" && \
    tar xf zig.tar.xz && \
    mv zig-x86_64-linux-${ZIG_VERSION} /usr/local/zig && \
    ln -s /usr/local/zig/zig /usr/local/bin/zig && \
    rm zig.tar.xz

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
