FROM alpine:3.9 as protoc_builder
RUN apk add --no-cache build-base curl automake autoconf libtool git zlib-dev unzip

ENV PROTOBUF_VERSION=3.7.1
ENV GRPC_VERSION=v1.20.1
ENV GRPC_GEN_GO_VERSION=v1.3.1
ENV GRPC_GATEWAY_VERSION=v1.9.0
ENV OUTDIR=/out

# Install protoc
RUN mkdir -p /protobuf && \
    curl -L https://github.com/google/protobuf/archive/v${PROTOBUF_VERSION}.tar.gz | tar xvz --strip-components=1 -C /protobuf
RUN cd /protobuf && \
    autoreconf -f -i -Wall,no-obsolete && \
    ./configure --prefix=/usr --enable-static=no && \
    make -j2 && make install
RUN cd /protobuf && \
    make install DESTDIR=${OUTDIR} && \
    mv ${OUTDIR}/usr/* ${OUTDIR}/

# Install gRPC plugins: PHP
RUN git clone -b ${GRPC_VERSION} https://github.com/grpc/grpc.git /grpc && \
    cd /grpc && git submodule update --init && make grpc_php_plugin && \
    mv bins/opt/grpc_php_plugin ${OUTDIR}/bin/

# Install Go, gRPC gateway and swagger plugins
RUN apk add --no-cache go
ENV GOPATH=/go GO111MODULE=on PATH=/go/bin/:$PATH
RUN git clone -b ${GRPC_GATEWAY_VERSION} https://github.com/grpc-ecosystem/grpc-gateway.git ${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway && \
    mkdir -p ${GOPATH}/src/u && cd ${GOPATH}/src/u && go mod init && go get -u -v -ldflags '-w -s' \
    github.com/golang/protobuf/protoc-gen-go@${GRPC_GEN_GO_VERSION} \
    github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway@${GRPC_GATEWAY_VERSION} \
    github.com/grpc-ecosystem/grpc-gateway/protoc-gen-swagger@${GRPC_GATEWAY_VERSION} && \
    install -c ${GOPATH}/bin/protoc-gen* ${OUTDIR}/bin/ && \
    cp -R ${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway/third_party/googleapis/* ${OUTDIR}/include/ && \
    mkdir -p ${OUTDIR}/include/protoc-gen-swagger/options && \
    cp ${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway/protoc-gen-swagger/options/*.proto ${OUTDIR}/include/protoc-gen-swagger/options/

FROM alpine:3.9
COPY --from=protoc_builder /out/ /usr/local/
# Needed shared libraries and tools by protobuf and their plugins
RUN apk --update add libstdc++

ENTRYPOINT ["/usr/local/bin/protoc", "-I/usr/local/include"]
