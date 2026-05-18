# syntax=docker/dockerfile:1

FROM python:3.12-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
      git \
      make \
      zip \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /build
RUN git clone --depth=1 https://github.com/yt-dlp/yt-dlp.git .
RUN make yt-dlp


FROM python:3.12-slim AS release

RUN apt-get update && apt-get install -y --no-install-recommends \
      ffmpeg \
 && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir \
      brotli \
      certifi \
      mutagen \
      pycryptodomex \
      "requests>=2.32.2,<3" \
      "urllib3>=1.26.17,<3" \
      "websockets>=13.0"

COPY --from=builder /build/yt-dlp /usr/local/bin/yt-dlp
RUN chmod +x /usr/local/bin/yt-dlp

WORKDIR /downloads

ENTRYPOINT ["yt-dlp"]
