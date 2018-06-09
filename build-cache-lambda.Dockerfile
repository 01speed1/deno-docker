FROM lambci/lambda:build-go1.x

RUN yum -y install vim wget
RUN wget http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/c/ccache-3.3.4-1.el7.x86_64.rpm && rpm -Uvh ccache-3.3.4-1.el7.x86_64.rpm
RUN yum -y install glib2-devel

# RUN yum update
# RUN yum -y install \
#     # unzip \
#     # ca-certificates \
#     # Deps for v8worker2 build
#     ccache \
#     xz-utils \
#     lbzip2 \
#     libglib2.0 
#     # && apt-get clean -y \
#     # && rm -rf /var/lib/apt/lists/* 

RUN curl --silent --location https://rpm.nodesource.com/setup_10.x | bash - \
    && yum -y install nodejs \
    && npm install -g yarn

# RUN yum update -d 6

# RUN yum -y install wget

RUN wget https://github.com/google/protobuf/releases/download/v3.1.0/protoc-3.1.0-linux-x86_64.zip \
    && unzip protoc-3.1.0-linux-x86_64.zip \
    && mv bin/protoc /usr/local/bin \
    && rm -rf include \
    && rm readme.txt \
    && rm protoc-3.1.0-linux-x86_64.zip

RUN go get -u github.com/golang/protobuf/protoc-gen-go
RUN go get -u github.com/jteeuwen/go-bindata/...

# v8worker2 build wants a valid git config
RUN git config --global user.email "you@example.com"
RUN git config --global user.name "Your Name"

RUN wget http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/l/libcxx-3.8.0-3.el7.x86_64.rpm \
    && rpm -Uvh libcxx-3.8.0-3.el7.x86_64.rpm
RUN wget http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/l/libcxx-devel-3.8.0-3.el7.x86_64.rpm \
    && rpm -Uvh libcxx-devel-3.8.0-3.el7.x86_64.rpm

ENV V8_REPO=github.com/ry/v8worker2
ENV V8_PATH=$GOPATH/src/$V8_REPO

# Pulling submodules manually, errors abound with go get
# See: https://github.com/ry/deno/issues/92
RUN mkdir -p $V8_PATH

RUN cd $V8_PATH \
    && git clone https://${V8_REPO}.git . \
    && rm -rf v8 \
    && git clone --depth 1 https://chromium.googlesource.com/v8/v8.git \
    && rm -rf depot_tools \
    && git clone --depth 1 https://chromium.googlesource.com/chromium/tools/depot_tools.git \
    && git submodule update --init --recursive

RUN wget http://mirror.centos.org/centos/7/os/x86_64/Packages/libgcc-4.8.5-28.el7.x86_64.rpm \
    && rpm -Uvh libgcc-4.8.5-28.el7.x86_64.rpm

COPY build.py $V8_PATH

# # RUN yum install -y clang
# # RUN clang --version
# # RUN g++ --version
# # RUN go get -u github.com/ry/deno/... || true

# # WORKDIR $GOPATH/src/github.com/ry/deno
# # RUN make


RUN cd $V8_PATH \
    && python -u ./build.py \
    && rm -rf $V8_PATH/v8/build \
    && rm -rf $V8_PATH/v8/.git \
    && rm -rf $V8_PATH/v8/third_party \
    && rm -rf $V8_PATH/v8/test \
    && rm -rf $V8_PATH/depot_tools 
