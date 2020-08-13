ARG ALPINE_VER="3.12"
FROM alpine:${ALPINE_VER} as fetch-stage

############## fetch stage ##############

# install fetch packages
RUN \
	set -ex \
	&& apk add --no-cache \
		bash \
		curl

# set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# fetch version file
RUN \
	set -ex \
	&& curl -o \
	/tmp/version.txt -L \
	"https://raw.githubusercontent.com/sparklyballs/versioning/master/version.txt"

# fetch source code
# hadolint ignore=SC1091
RUN \
	. /tmp/version.txt \
	&& set -ex \
	&& mkdir -p \ 
		/source/w_scan2 \
	&& curl -o \
	/tmp/wcan_2.tar.gz -L \
	"https://github.com/stefantalpalaru/w_scan2/archive/${W_SCAN2_COMMIT}.tar.gz" \
	&& tar xf \
	/tmp/wcan_2.tar.gz -C \
	/source/w_scan2 --strip-components=1

FROM alpine:${ALPINE_VER} as packages-stage

############## packages stage ##############

# install build packages
RUN \
	apk add --no-cache \
		autoconf \
		automake \
		g++ \
		gcc \
		libtool \
		linux-headers \
		make

FROM packages-stage as build-stage

############## build stage ##############

# add artifacts from source stage
COPY --from=fetch-stage /source /source

# set workdir
WORKDIR /source/w_scan2

# build app
RUN \
	set -ex \
	&& ./autogen.sh \
	&& ./configure \
		--prefix=/usr \
	&& make \
	&& make DESTDIR=/output/w_scan2 install

FROM sparklyballs/alpine-test:${ALPINE_VER}

############## runtine stage ##############

# add artifacts from build stage
COPY --from=build-stage /output/w_scan2/usr /usr
