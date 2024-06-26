FROM golang:1.21.5-alpine3.19 as builder
RUN apk add --no-cache make gcc musl-dev linux-headers git jq bash wget clang
COPY ./go.mod /app/go.mod
COPY ./go.sum /app/go.sum

WORKDIR /app

RUN echo "go mod cache: $(go env GOMODCACHE)"
RUN echo "go build cache: $(go env GOCACHE)"

RUN --mount=type=cache,target=/go/pkg/mod --mount=type=cache,target=/root/.cache/go-build go mod download

# install mips-linux-musl-gcc
RUN wget https://musl.cc/mips-linux-musl-cross.tgz
RUN tar zxf mips-linux-musl-cross.tgz
ENV PATH=$PATH:/app/mips-linux-musl-cross/bin/
RUN echo $PATH


COPY . /app
RUN env GO111MODULE=on go build -o ./main ./main.go
RUN env CC=mips-linux-musl-gcc CGO_ENABLED=1 GO111MODULE=on GOOS=linux GOARCH=mips GOMIPS=softfloat go build -o ./main.elf ./main.go

FROM scratch AS export-stage
COPY --from=builder /app/main .
COPY --from=builder /app/main.elf .
