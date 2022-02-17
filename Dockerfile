FROM emscripten/emsdk as boost
COPY boost . 
RUN ./bootstrap.sh
RUN ./b2 toolset=emscripten cxxflags="-std=c++11 -stdlib=libc++" linkflags="-stdlib=libc++" cxxflags=-DPTHREADS cxxflags=-DBOOST_THREAD_POSIX cxxflags=-pthread cxxflags=-DTHREAD release --disable-icu --with-regex --with-filesystem --with-system --with-thread --with-program_options install link=static runtime-link=static --prefix=/emsdk/upstream/emscripten/cache/sysroot


FROM emscripten/emsdk as zlib
COPY zlib . 
RUN emcmake cmake -B ../build . -DCMAKE_BUILD_TYPE=Release
RUN cd ../build && make && make install


FROM emscripten/emsdk as libzip
COPY --from=zlib /emsdk/upstream/emscripten/cache/sysroot /emsdk/upstream/emscripten/cache/sysroot
COPY libzip . 
RUN emcmake cmake -B ../build . -DCMAKE_BUILD_TYPE=Release
RUN cd ../build && make && make install


FROM emscripten/emsdk as glib
COPY glib .
RUN apt-get update \
  && apt-get install -qqy \
    build-essential \
    prelink \
    autoconf \
    libtool \
    texinfo \
    pkgconf \
    # needed for Meson
    ninja-build \
    python3-pip \
  && pip3 install meson
ARG MESON_PATCH=https://github.com/kleisauke/wasm-vips/raw/master/build/patches/meson-emscripten.patch
RUN cd $(dirname `python3 -c "import mesonbuild as _; print(_.__path__[0])"`) \
  && curl -Ls $MESON_PATCH | patch -p1
RUN chmod +x build.sh; ./build.sh


FROM emscripten/emsdk as freetype
COPY --from=zlib /emsdk/upstream/emscripten/cache/sysroot /emsdk/upstream/emscripten/cache/sysroot
COPY freetype . 
RUN emcmake cmake -B ../build . -DFT_REQUIRE_ZLIB=TRUE -DCMAKE_BUILD_TYPE=Release
RUN cd ../build && make && make install


FROM emscripten/emsdk as libxml2
COPY libxml2 . 
RUN emcmake cmake -B ../build . -DLIBXML2_WITH_PYTHON=OFF -DLIBXML2_WITH_LZMA=OFF -DLIBXML2_WITH_ZLIB=OFF -DCMAKE_BUILD_TYPE=Release
RUN cd ../build && make && make install


FROM emscripten/emsdk as fontconfig
RUN apt-get update && apt-get install pkg-config gperf automake libtool gettext autopoint -y
COPY --from=zlib /emsdk/upstream/emscripten/cache/sysroot /emsdk/upstream/emscripten/cache/sysroot
COPY --from=freetype /emsdk/upstream/emscripten/cache/sysroot /emsdk/upstream/emscripten/cache/sysroot
COPY --from=libxml2 /emsdk/upstream/emscripten/cache/sysroot /emsdk/upstream/emscripten/cache/sysroot
COPY fontconfig . 
RUN FREETYPE_CFLAGS="-I/emsdk/upstream/emscripten/cache/sysroot/include/freetype2" FREETYPE_LIBS="-lfreetype -lz" emconfigure ./autogen.sh CFLAGS="-s USE_PTHREADS=1" --host none --disable-docs --disable-shared --enable-static --sysconfdir=/ --localstatedir=/ --with-default-fonts=/fonts --enable-libxml2 --prefix=/emsdk/upstream/emscripten/cache/sysroot
RUN echo "all install:" > test/Makefile.in
RUN emmake make
RUN emmake make install || true


FROM emscripten/emsdk as harfbuzz
COPY --from=freetype /emsdk/upstream/emscripten/cache/sysroot /emsdk/upstream/emscripten/cache/sysroot
COPY harfbuzz . 
RUN emcmake cmake -E env CXXFLAGS="-s USE_PTHREADS=1" cmake -B ../build . -DCMAKE_BUILD_TYPE=Release -DHB_HAVE_FREETYPE=ON
RUN cd ../build && make && make install


FROM emscripten/emsdk as eigen
COPY eigen . 
RUN emcmake cmake -B ../build . -DCMAKE_BUILD_TYPE=Release
RUN cd ../build && make && make install


FROM emscripten/emsdk as cgal
COPY cgal . 
RUN emcmake cmake -B ../build . -DCMAKE_BUILD_TYPE=Release
RUN cd ../build && make && make install


FROM emscripten/emsdk as gmp
COPY gmp-6.1.2 . 
RUN emconfigure ./configure --disable-assembly --host none --enable-cxx --prefix=/emsdk/upstream/emscripten/cache/sysroot
RUN make && make install


FROM emscripten/emsdk as mpfr
COPY --from=gmp /emsdk/upstream/emscripten/cache/sysroot /emsdk/upstream/emscripten/cache/sysroot
COPY mpfr-4.1.0 . 
RUN emconfigure ./configure CFLAGS="-s USE_PTHREADS=1" --host none --with-gmp=/emsdk/upstream/emscripten/cache/sysroot --prefix=/emsdk/upstream/emscripten/cache/sysroot
RUN make && make install


FROM emscripten/emsdk as openscad
RUN apt-get update && apt-get install pkg-config flex bison -y
# Dependencies
COPY --from=boost /emsdk/upstream/emscripten/cache/sysroot /emsdk/upstream/emscripten/cache/sysroot
COPY --from=gmp /emsdk/upstream/emscripten/cache/sysroot /emsdk/upstream/emscripten/cache/sysroot
COPY --from=mpfr /emsdk/upstream/emscripten/cache/sysroot /emsdk/upstream/emscripten/cache/sysroot
COPY --from=cgal /emsdk/upstream/emscripten/cache/sysroot /emsdk/upstream/emscripten/cache/sysroot
COPY --from=eigen /emsdk/upstream/emscripten/cache/sysroot /emsdk/upstream/emscripten/cache/sysroot
COPY --from=harfbuzz /emsdk/upstream/emscripten/cache/sysroot /emsdk/upstream/emscripten/cache/sysroot
COPY --from=fontconfig /emsdk/upstream/emscripten/cache/sysroot /emsdk/upstream/emscripten/cache/sysroot
COPY --from=glib /emsdk/upstream/emscripten/cache/sysroot /emsdk/upstream/emscripten/cache/sysroot
COPY --from=libzip /emsdk/upstream/emscripten/cache/sysroot /emsdk/upstream/emscripten/cache/sysroot
# End Dependencies

COPY openscad . 
RUN export PKG_CONFIG_PATH="/emsdk/upstream/emscripten/cache/sysroot/lib/pkgconfig"
RUN emcmake cmake -B ../build . -DNULLGL=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DHARFBUZZ_INCLUDE_DIRS=/emsdk/upstream/emscripten/cache/sysroot/include/harfbuzz \
    -DFONTCONFIG_INCLUDE_DIR=/emsdk/upstream/emscripten/cache/sysroot/include/fontconfig \
    -DFONTCONFIG_LIBRARIES=libfontconfig.a

# Hack to fix build includes
RUN sed -e "s|-isystem /emsdk/upstream/emscripten/cache/sysroot/include||g" -i ../build/CMakeFiles/OpenSCAD.dir/includes_C.rsp
RUN sed -e "s|-isystem /emsdk/upstream/emscripten/cache/sysroot/include||g" -i ../build/CMakeFiles/OpenSCAD.dir/includes_CXX.rsp
RUN sed -e "s|-lfontconfig|/emsdk/upstream/emscripten/cache/sysroot/lib/libglib-2.0.a /emsdk/upstream/emscripten/cache/sysroot/lib/libzip.a /emsdk/upstream/emscripten/cache/sysroot/lib/libz.a /emsdk/upstream/emscripten/cache/sysroot/lib/libfontconfig.a|g" -i ../build/CMakeFiles/OpenSCAD.dir/linklibs.rsp

# Add emscripten flags here
RUN sed -e "s|em++|em++ -s USE_PTHREADS=1 -s NO_DISABLE_EXCEPTION_CATCHING -s FORCE_FILESYSTEM=1 -s ALLOW_MEMORY_GROWTH=1 -s EXTRA_EXPORTED_RUNTIME_METHODS=['FS'] -s EXPORTED_RUNTIME_METHODS=callMain -s EXPORT_ES6=1 -s ENVIRONMENT=web,worker -s MODULARIZE=1 -s EXPORT_NAME=OpenSCAD -s EXIT_RUNTIME=1|g" -i ../build/CMakeFiles/OpenSCAD.dir/link.txt

RUN cd ../build && make -j12
