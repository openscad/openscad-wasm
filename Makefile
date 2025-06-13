ENV ::= release
PTHREAD ::= 0
BUILDKIT ::= 0
EMSCRIPTEN_FLAGS := -fexceptions

ifeq ($(strip $(ENV)),debug)
		CMAKE_BUILD_TYPE := Debug
		MESON_BUILD_TYPE := debug
		EMSCRIPTEN_FLAGS += -g -O0
else ifeq ($(strip $(ENV)),release)
		CMAKE_BUILD_TYPE := Release
		MESON_BUILD_TYPE := release
		EMSCRIPTEN_FLAGS += -O3
else ifeq ($(strip $(ENV)),minsize)
		CMAKE_BUILD_TYPE := MinSizeRel
		MESON_BUILD_TYPE := minsize
		EMSCRIPTEN_FLAGS += -Os
else
		$(error Bad ENV, must be release, minsize or debug)
endif

ifeq ($(PTHREAD),1)
    VARIANT = -pthread
    EMSCRIPTEN_FLAGS += -pthread 
# -sSHARED_MEMORY=1 -sPROXY_TO_PTHREAD=1 -sPTHREAD_POOL_SIZE=4
else
    VARIANT =
endif

DOCKER_TAG_BASE ?= openscad/wasm-base$(VARIANT)-$(ENV)
DOCKER_TAG_OPENSCAD ?= openscad/wasm$(VARIANT)-$(ENV)
DOCKER_OCI_BASE ?= .oci.wasm-base$(VARIANT)-$(ENV)

# Use the arm64 version of the emscripten sdk if running on an arm64 machine, as the amd64 image would crash QEMU in a couple of places.
# See latest version in https://hub.docker.com/r/emscripten/emsdk/tags
EMSCRIPTEN_VERSION ?= 4.0.10
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
	rm -rf .oci.*
	rm -rf runtime/dist runtime/node_modules

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

build/openscad.wasm.js: .image$(VARIANT)-$(ENV).make
	mkdir -p build
	docker rm -f tmpcpy
	docker run --name tmpcpy $(DOCKER_TAG_OPENSCAD)
	docker cp tmpcpy:/home/build/openscad.js build/openscad.wasm.js
	docker cp tmpcpy:/home/build/openscad.wasm build/
	docker cp tmpcpy:/home/build/openscad.wasm.map build/ || true
	docker rm tmpcpy

.image$(VARIANT)-$(ENV).make: .base-image$(VARIANT)-$(ENV).make Dockerfile
ifeq ($(BUILDKIT),0)
	docker build libs/openscad \
		-f Dockerfile \
		-t $(DOCKER_TAG_OPENSCAD) \
		--build-arg "CMAKE_BUILD_TYPE=$(CMAKE_BUILD_TYPE)" \
		--build-arg "DOCKER_TAG_BASE=$(DOCKER_TAG_BASE)" \
		--build-arg "EMSCRIPTEN_FLAGS=$(EMSCRIPTEN_FLAGS)"
else
	docker buildx build libs/openscad \
		-f Dockerfile \
		-t $(DOCKER_TAG_OPENSCAD) \
		--pull=false \
		--load \
		--build-context $(DOCKER_TAG_BASE)="oci-layout://$(PWD)/$(DOCKER_OCI_BASE)" \
		--build-arg "CMAKE_BUILD_TYPE=$(CMAKE_BUILD_TYPE)" \
		--build-arg "DOCKER_TAG_BASE=$(DOCKER_TAG_BASE)" \
		--build-arg "EMSCRIPTEN_FLAGS=$(EMSCRIPTEN_FLAGS)"
endif
	touch $@

.base-image$(VARIANT)-$(ENV).make: libs Dockerfile.base
ifeq ($(BUILDKIT),0)
	docker build libs \
		-f Dockerfile.base \
		-t $(DOCKER_TAG_BASE) \
		--build-arg "CMAKE_BUILD_TYPE=$(CMAKE_BUILD_TYPE)" \
		--build-arg "MESON_BUILD_TYPE=$(MESON_BUILD_TYPE)" \
		--build-arg "EMSCRIPTEN_FLAGS=$(EMSCRIPTEN_FLAGS)" \
		--build-arg "EMSCRIPTEN_SDK_TAG=$(EMSCRIPTEN_SDK_TAG)"
else
	docker buildx build libs \
		-f Dockerfile.base \
		-t $(DOCKER_TAG_BASE) \
		--build-arg "CMAKE_BUILD_TYPE=$(CMAKE_BUILD_TYPE)" \
		--build-arg "MESON_BUILD_TYPE=$(MESON_BUILD_TYPE)" \
		--build-arg "EMSCRIPTEN_FLAGS=$(EMSCRIPTEN_FLAGS)" \
		--build-arg "EMSCRIPTEN_SDK_TAG=$(EMSCRIPTEN_SDK_TAG)" \
		--output=type=oci,tar=false,dest="$(DOCKER_OCI_BASE)"
endif
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
	git clone --recurse https://github.com/3MFConsortium/lib3mf.git ${SHALLOW} --branch v2.3.2 $@
	git -C $@ apply ../../patches/lib3mf.patch

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
	wget https://github.com/boostorg/boost/releases/download/boost-1.87.0/boost-1.87.0-b2-nodocs.tar.xz
	tar xf boost-1.87.0-b2-nodocs.tar.xz -C libs
	mv libs/boost-1.87.0 $@
	rm boost-1.87.0-b2-nodocs.tar.xz
	sed -i -E 's/-fwasm-exceptions/-fexceptions/g' libs/boost/tools/build/src/tools/emscripten.jam

libs/gmp:
	wget https://gmplib.org/download/gmp/gmp-6.3.0.tar.xz
	tar xf gmp-6.3.0.tar.xz -C libs
	mv libs/gmp-6.3.0 $@
	rm gmp-6.3.0.tar.xz

libs/mpfr:
	wget https://www.mpfr.org/mpfr-4.2.1/mpfr-4.2.1.tar.xz
	tar xf mpfr-4.2.1.tar.xz -C libs
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
