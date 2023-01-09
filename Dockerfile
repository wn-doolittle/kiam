FROM --platform=${BUILDPLATFORM:-linux/amd64} golang:1.15.15 as build
ENV GO111MODULE=on

ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH

WORKDIR /workspace
# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum
# cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer
RUN go mod download

COPY cmd/ cmd/
COPY pkg/ pkg/
COPY proto/ proto/
COPY Makefile Makefile

# As (generated) proto/service.pb.go is _also_ committed, void the need to install protoc / protoc-gen-go plugin
RUN touch proto/service.pb.go
RUN ARCH=$TARGETARCH make bin/kiam-linux-$TARGETARCH

FROM alpine:3.11

ARG TARGETARCH

RUN apk --no-cache add iptables
COPY --from=build /workspace/bin/kiam-linux-$TARGETARCH /kiam
CMD []
