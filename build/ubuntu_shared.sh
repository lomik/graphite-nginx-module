#!/bin/sh

UBUNTU_VERSION=17.10
NGINX_PACKAGE=nginx-full

cd `dirname $0`/..
ROOT=`pwd`

# /build/graphite-nginx-module/build/ubuntu_shared_build.sh

docker run -ti --rm \
	-v $ROOT:/build/graphite-nginx-module \
	-e "NGINX_PACKAGE=$NGINX_PACKAGE" \
	ubuntu:$UBUNTU_VERSION bash -c '
# enable source repos
sed -ibak "s/\#\ deb-src/deb-src/" /etc/apt/sources.list

apt-get update

apt-get install -y $NGINX_PACKAGE dpkg-dev

CONFIGURE_ARGUMENTS=$(nginx -V 2>&1 | grep "configure arguments" | sed "s/configure arguments://")
BUILD_ROOT=$(echo $CONFIGURE_ARGUMENTS | egrep -o "/build/nginx-[^/]*/" | head -n 1)

mkdir -p $BUILD_ROOT
cd $BUILD_ROOT

apt-get build-dep -y $NGINX_PACKAGE
apt-get source $NGINX_PACKAGE

# go to nginx directory
cd $(echo */)
# patch modules
make -f debian/rules


# build graphite module
echo $CONFIGURE_ARGUMENTS

# configure with same options
eval ./configure $CONFIGURE_ARGUMENTS --add-dynamic-module=/build/graphite-nginx-module/

# https://github.com/arut/nginx-rtmp-module/issues/1109
sed -ibak "s/-Werror//" objs/Makefile

# build
make

install -m 0755 ./objs/ngx_http_graphite_module.so /build/graphite-nginx-module/ngx_http_graphite_module.so
'