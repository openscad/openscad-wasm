ENV=Release
TAG_SUFFIX=
ifeq ($(strip $(ENV)),Debug)
TAG_SUFFIX=-debug
endif

DOCKER_TAG_BASE ?= openscad-base$(TAG_SUFFIX)
DOCKER_TAG_OPENSCAD ?= openscad$(TAG_SUFFIX)

# Use the arm64 version of the emscripten sdk if running on an arm64 machine, as the amd64 image would crash QEMU in a couple of places.
# See latest version in https://hub.docker.com/r/emscripten/emsdk/tags
EMSCRIPTEN_VERSION ?= 3.1.74
UNAME_MACHINE := $(shell uname -m)
ifeq ($(UNAME_MACHINE),arm64)
    EMSCRIPTEN_SDK_TAG=emscripten/emsdk:$(EMSCRIPTEN_VERSION)-arm64
else
    EMSCRIPTEN_SDK_TAG=emscripten/emsdk:$(EMSCRIPTEN_VERSION)
endif

all: build

clean:
	rm -rf libs
	rm -rf build

test:
	cd tests; deno test --allow-read --allow-write

.PHONY: example
example:
	cd example; deno run --allow-net --allow-read server.ts

.PHONY: build
build: build/openscad.wasm.js build/openscad.fonts.js

build/openscad.fonts.js: runtime/node_modules runtime/**/* res
	mkdir -p build
	cd runtime; npm run build
	cp runtime/dist/* build

runtime/node_modules:
	cd runtime; npm install

build/openscad.wasm.js: .image-$(ENV).make
	mkdir -p build
	docker run --name tmpcpy openscad
	docker cp tmpcpy:/build/openscad.js build/openscad.wasm.js
	docker cp tmpcpy:/build/openscad.wasm build/
	docker cp tmpcpy:/build/openscad.wasm.map build/ || true
	docker rm tmpcpy

.image-$(ENV).make: .base-image-$(ENV).make Dockerfile
	docker build libs/openscad -f Dockerfile -t $(DOCKER_TAG_OPENSCAD) --build-arg CMAKE_BUILD_TYPE=$(ENV) --build-arg DOCKER_TAG_BASE=$(DOCKER_TAG_BASE)
	touch $@

.base-image-$(ENV).make: libs Dockerfile.base
	docker build libs -f Dockerfile.base -t $(DOCKER_TAG_BASE) --build-arg CMAKE_BUILD_TYPE=$(ENV) --build-arg EMSCRIPTEN_SDK_TAG=$(EMSCRIPTEN_SDK_TAG)
	touch $@

libs: \
	libs/cairo \
	libs/cgal \
	libs/eigen \
	libs/fontconfig \
	libs/freetype \
	libs/libffi \
	libs/glib \
	libs/harfbuzz \
	libs/lib3mf \
	libs/libexpat \
	libs/liblzma \
	libs/libzip \
	libs/openscad \
	libs/boost \
	libs/gmp \
	libs/mpfr \
	libs/zlib \
	libs/libxml2 \
	libs/doubleconversion \
	libs/emscripten-crossfile.meson

SINGLE_BRANCH_MAIN=--branch main --single-branch
SINGLE_BRANCH=--branch master --single-branch
SHALLOW=--depth 1

libs/emscripten-crossfile.meson:
	mkdir -p libs
	cp emscripten-crossfile.meson $@

libs/cairo:
	git clone --recurse https://gitlab.freedesktop.org/cairo/cairo.git ${SHALLOW} ${SINGLE_BRANCH} $@

libs/libffi:
	git clone https://github.com/libffi/libffi.git ${SHALLOW} ${SINGLE_BRANCH} $@

libs/cgal:
	git clone https://github.com/CGAL/cgal.git ${SHALLOW} --branch v6.0.1 --single-branch $@

libs/eigen:
	git clone https://gitlab.com/libeigen/eigen.git ${SHALLOW} ${SINGLE_BRANCH} $@

libs/fontconfig:
	git clone https://gitlab.freedesktop.org/fontconfig/fontconfig ${SHALLOW} ${SINGLE_BRANCH_MAIN} $@
	git -C $@ apply ../../patches/fontconfig.patch

libs/freetype:
	git clone https://github.com/freetype/freetype.git ${SHALLOW} ${SINGLE_BRANCH} $@
# git clone https://gitlab.freedesktop.org/freetype/freetype.git ${SHALLOW} ${SINGLE_BRANCH} $@

libs/glib:
	test -d $@ || git clone https://github.com/kleisauke/glib.git ${SHALLOW} --branch wasm-vips-2.83.2 --single-branch $@

libs/harfbuzz:
	git clone https://github.com/harfbuzz/harfbuzz.git ${SHALLOW} ${SINGLE_BRANCH_MAIN} $@

libs/lib3mf:
	git clone --recurse https://github.com/3MFConsortium/lib3mf.git ${SHALLOW} ${SINGLE_BRANCH} $@

libs/libexpat:
	git clone  https://github.com/libexpat/libexpat ${SHALLOW} ${SINGLE_BRANCH} $@

libs/liblzma:
	git clone https://github.com/kobolabs/liblzma.git ${SHALLOW} ${SINGLE_BRANCH} $@

libs/libzip:
	git clone https://github.com/nih-at/libzip.git ${SHALLOW} ${SINGLE_BRANCH_MAIN} $@

libs/zlib:
	git clone https://github.com/madler/zlib.git ${SHALLOW} ${SINGLE_BRANCH} $@

libs/libxml2:
	git clone https://gitlab.gnome.org/GNOME/libxml2.git ${SHALLOW} ${SINGLE_BRANCH} $@

libs/doubleconversion:
	git clone https://github.com/google/double-conversion ${SHALLOW} ${SINGLE_BRANCH} $@

libs/openscad:
	git clone --recurse https://github.com/openscad/openscad.git ${SHALLOW} ${SINGLE_BRANCH} $@

libs/boost:
	wget https://boostorg.jfrog.io/artifactory/main/release/1.87.0/source/boost_1_87_0.tar.bz2
	tar xjf boost_1_87_0.tar.bz2 -C libs
	mv libs/boost_1_87_0 libs/boost
	rm boost_1_87_0.tar.bz2
	sed -i -E 's/-fwasm-exceptions/-fexceptions/g' libs/boost/tools/build/src/tools/emscripten.jam

libs/gmp:
	wget https://gmplib.org/download/gmp/gmp-6.3.0.tar.lz 
	tar --lzma -xf gmp-6.3.0.tar.lz -C libs
	mv libs/gmp-6.3.0 $@
	rm gmp-6.3.0.tar.lz

libs/mpfr:
	wget https://www.mpfr.org/mpfr-4.2.1/mpfr-4.2.1.tar.xz
	tar xJf mpfr-4.2.1.tar.xz -C libs
	mv libs/mpfr-4.2.1 $@
	rm mpfr-4.2.1.tar.xz

res: \
	res/noto \
	res/liberation \
	res/MCAD

res/liberation:
	git clone --recurse https://github.com/shantigilbert/liberation-fonts-ttf.git ${SHALLOW} ${SINGLE_BRANCH} $@

res/noto:
	mkdir -p res/noto
	wget https://github.com/openmaptiles/fonts/raw/master/noto-sans/NotoSans-Regular.ttf -O res/noto/NotoSans-Regular.ttf
	wget https://github.com/openmaptiles/fonts/raw/master/noto-sans/NotoNaskhArabic-Regular.ttf -O res/noto/NotoNaskhArabic-Regular.ttf

res/MCAD:
	git clone https://github.com/openscad/MCAD.git ${SHALLOW} ${SINGLE_BRANCH} $@
