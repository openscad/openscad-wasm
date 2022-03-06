DOCKER_TAG_BASE ?= openscad-base
DOCKER_TAG_OPENSCAD ?= openscad

all: build

clean:
	rm -rf libs
	rm -rf build

test:
	cd tests; deno test --allow-read --allow-write --jobs 4

.PHONY: example
example:
	cd example; deno run --allow-net --allow-read server.ts

ENV=Release
ifeq ($(strip $(ENV)),Debug)
DOCKER_FLAGS= --build-arg CMAKE_BUILD_TYPE=Debug --build-arg EMXX_FLAGS="-gsource-map --source-map-base=/"
endif

.PHONY: build
build: build/openscad.js build/openscad.runtime.js

build/openscad.runtime.js: runtime/node_modules runtime/**/*
	cd runtime; npm run build
	cp runtime/dist/* build

runtime/node_modules:
	cd runtime; npm install

build/openscad.js: build/.image 
	docker run --name tmpcpy openscad
	docker cp tmpcpy:/build .
	docker rm tmpcpy

	 sed -i '1s&^&/// <reference types="./openscad.d.ts" />\n&' build/openscad.js

build/.image: build/.base-image Dockerfile
	docker build libs/openscad -f Dockerfile -t $(DOCKER_TAG_OPENSCAD) ${DOCKER_FLAGS}
	mkdir -p build
	touch $@

build/.base-image: libs Dockerfile.base
	docker build libs -f Dockerfile.base -t $(DOCKER_TAG_BASE)
	mkdir -p build
	touch $@

libs: libs/cgal \
	libs/eigen \
	libs/fontconfig \
	libs/freetype \
	libs/glib \
	libs/harfbuzz \
	libs/lib3mf \
	libs/libexpat \
	libs/liblzma \
	libs/libzip \
	libs/openscad \
	libs/boost \
	libs/gmp-6.1.2 \
	libs/mpfr-4.1.0 \
	libs/zlib \
	libs/libxml2 \
	libs/doubleconversion

SINGLE_BRANCH_MAIN=--branch main --single-branch
SINGLE_BRANCH=--branch master --single-branch
SHALLOW=--depth 1

libs/cgal:
	git clone https://github.com/CGAL/cgal.git ${SHALLOW} ${SINGLE_BRANCH} $@

libs/eigen:
	git clone https://github.com/PX4/eigen.git ${SHALLOW} ${SINGLE_BRANCH} $@

libs/fontconfig:
	git clone https://gitlab.freedesktop.org/fontconfig/fontconfig.git ${SHALLOW} ${SINGLE_BRANCH_MAIN} $@
	git -C $@ apply ../../patches/fontconfig.patch 

libs/freetype:
	git clone https://gitlab.freedesktop.org/freetype/freetype.git ${SHALLOW} ${SINGLE_BRANCH} $@

libs/glib:
	git clone https://gist.github.com/acfa1c09522705efa5eb0541d2d00887.git ${SHALLOW} ${SINGLE_BRANCH} $@
	git -C $@ apply ../../patches/glib.patch 

libs/harfbuzz:
	git clone https://github.com/harfbuzz/harfbuzz.git ${SHALLOW} ${SINGLE_BRANCH_MAIN} $@

libs/lib3mf:
	git clone https://github.com/3MFConsortium/lib3mf.git ${SHALLOW} ${SINGLE_BRANCH} $@

libs/libexpat:
	git clone  https://github.com/libexpat/libexpat ${SHALLOW} ${SINGLE_BRANCH} $@

libs/liblzma:
	git clone https://github.com/kobolabs/liblzma.git ${SHALLOW} ${SINGLE_BRANCH} $@

libs/libzip:
	git clone https://github.com/nih-at/libzip.git ${SHALLOW} ${SINGLE_BRANCH} $@

libs/zlib:
	git clone https://github.com/madler/zlib.git ${SHALLOW} ${SINGLE_BRANCH} $@

libs/libxml2:
	git clone https://gitlab.gnome.org/GNOME/libxml2.git ${SHALLOW} ${SINGLE_BRANCH} $@

libs/doubleconversion:
	git clone https://github.com/google/double-conversion ${SHALLOW} ${SINGLE_BRANCH} $@

libs/openscad:
	git clone --recurse https://github.com/ochafik/openscad.git --branch filtered-number --single-branch $@

libs/boost:
	git clone --recurse https://github.com/boostorg/boost.git ${SHALLOW} ${SINGLE_BRANCH} $@
	git -C $@/libs/filesystem apply ../../../../patches/boost-filesystem.patch

libs/gmp-6.1.2:
	wget https://gmplib.org/download/gmp/gmp-6.1.2.tar.lz
	tar xf gmp-6.1.2.tar.lz -C libs
	rm gmp-6.1.2.tar.lz

libs/mpfr-4.1.0:
	wget  https://www.mpfr.org/mpfr-current/mpfr-4.1.0.tar.xz
	tar xf mpfr-4.1.0.tar.xz -C libs
	rm mpfr-4.1.0.tar.xz
