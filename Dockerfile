FROM debian:stretch-slim

ARG go_version=1.15.6
ARG protoc_gen_grpc_java_version=1.28.0
ARG ts_protoc_gen_version=0.12.0
ARG nanopb_version=0.4.4
ARG buf_version=0.33.0
ARG protodist_version="0.1.0-alpha.3"

RUN apt update
RUN apt install -y curl

# Install Golang
RUN curl -LO https://golang.org/dl/go${go_version}.linux-amd64.tar.gz
RUN tar -C /usr/local -xzf go${go_version}.linux-amd64.tar.gz
ENV PATH=$PATH:/usr/local/go/bin
ENV GOPATH=/root/go
ENV GOROOT=/usr/local/go
ENV GOBIN=$GOPATH/bin
ENV PATH=$PATH:$GOBIN

# Intall NodeJS
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash
RUN apt install -y nodejs git
RUN nodejs -v

#Install python
RUN apt install -y build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev wget
RUN curl -O https://www.python.org/ftp/python/3.5.0/Python-3.5.0.tar.xz
RUN tar -xf Python-3.5.0.tar.xz
RUN cd Python-3.5.0 && ./configure --enable-optimizations && make && make altinstall

WORKDIR /tmp

# Install protoc-gen-grpc-java plugin (protoc --grpc-java_out)
RUN curl -L  https://repo1.maven.org/maven2/io/grpc/protoc-gen-grpc-java/${protoc_gen_grpc_java_version}/protoc-gen-grpc-java-${protoc_gen_grpc_java_version}-linux-x86_64.exe -o protoc-gen-grpc-java
RUN chmod a+x protoc-gen-grpc-java && mv protoc-gen-grpc-java /bin/protoc-gen-grpc-java


# Install protoc-gen-ts plugin required (protoc --ts_out)
RUN npm i -g ts-protoc-gen@$ts_protoc_gen_version typescript@3.8.3

RUN apt install unzip
# Install protoc
ENV PB_REL="https://github.com/protocolbuffers/protobuf/releases"
RUN curl -LO $PB_REL/download/v3.13.0/protoc-3.13.0-linux-x86_64.zip
RUN unzip protoc-3.13.0-linux-x86_64.zip -d /usr/local

# Install protoc-gen-go
RUN go get -u google.golang.org/protobuf/cmd/protoc-gen-go
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go

# Install protoc-gen-go-grpc
RUN go get -u google.golang.org/grpc/cmd/protoc-gen-go-grpc
RUN go install google.golang.org/grpc/cmd/protoc-gen-go-grpc

# Install protoc-gen-validate
RUN go get -d github.com/envoyproxy/protoc-gen-validate
RUN cd $GOPATH/src/github.com/envoyproxy/protoc-gen-validate && make build

# Install Nanopb
RUN curl -L https://jpa.kapsi.fi/nanopb/download/nanopb-${nanopb_version}-linux-x86.tar.gz | tar -xz
RUN mv nanopb-${nanopb_version}-linux-x86/generator-bin/protoc-gen-nanopb /bin/protoc-gen-nanopb && chmod +x /bin/protoc-gen-nanopb
# Move all files from the generator-bin dir to /bin/ (nanopb protoc plugin requires them to be in /bin)
# We will omit protoc, because we want to use our own protoc binary
RUN cd nanopb-${nanopb_version}-linux-x86/generator-bin/ && rm protoc && cp -R * /bin/

# Install Buf
RUN curl -L https://github.com/bufbuild/buf/releases/download/v${buf_version}/buf-Linux-x86_64.tar.gz | tar -xz
RUN chmod +x buf/bin/* && mv buf/bin/* /bin/

# Install protodist
RUN curl -L https://github.com/4nte/protodist/releases/download/${protodist_version}/protodist_${protodist_version}_Linux_amd64.tar.gz | tar -xz
RUN chmod +x protodist
RUN mv protodist /bin/protodist

ENTRYPOINT /bin/sh