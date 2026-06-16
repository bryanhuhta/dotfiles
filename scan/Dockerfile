FROM alpine:3.23

RUN apk add --no-cache ca-certificates curl docker-cli

RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh \
  | sh -s -- -b /usr/local/bin

RUN curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh \
  | sh -s -- -b /usr/local/bin

WORKDIR /workspace
