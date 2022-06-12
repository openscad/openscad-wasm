FROM openscad-base

ARG CMAKE_BUILD_TYPE=Release
ARG EMXX_FLAGS

COPY . . 
RUN export PKG_CONFIG_PATH="/emsdk/upstream/emscripten/cache/sysroot/lib/pkgconfig" && \
    emcmake cmake -B ../build . \
    -DWASM=ON \
    -DSNAPSHOT=ON \
    -DEXPERIMENTAL=ON \
    -DENABLE_CAIRO=OFF \
    -DUSE_MIMALLOC=OFF \
    -DBoost_USE_STATIC_RUNTIME=ON \
    -DBoost_USE_STATIC_LIBS=ON \
    -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} \
    -DHARFBUZZ_INCLUDE_DIRS=/emsdk/upstream/emscripten/cache/sysroot/include/harfbuzz \
    -DFONTCONFIG_INCLUDE_DIR=/emsdk/upstream/emscripten/cache/sysroot/include/fontconfig \
    -DFONTCONFIG_LIBRARIES=libfontconfig.a

# Hack to fix build includes
RUN sed -e "s|-isystem /emsdk/upstream/emscripten/cache/sysroot/include[^/]||g" -i ../build/CMakeFiles/OpenSCAD.dir/includes_C.rsp
RUN sed -e "s|-isystem /emsdk/upstream/emscripten/cache/sysroot/include[^/]||g" -i ../build/CMakeFiles/OpenSCAD.dir/includes_CXX.rsp
RUN sed -e "s|-lfontconfig|/emsdk/upstream/emscripten/cache/sysroot/lib/libglib-2.0.a /emsdk/upstream/emscripten/cache/sysroot/lib/libzip.a /emsdk/upstream/emscripten/cache/sysroot/lib/libz.a /emsdk/upstream/emscripten/cache/sysroot/lib/libfontconfig.a|g" -i ../build/CMakeFiles/OpenSCAD.dir/linklibs.rsp

# Add emscripten flags here
RUN sed -e "s|em++|em++ ${EMXX_FLAGS} -s USE_PTHREADS=0 -s NO_DISABLE_EXCEPTION_CATCHING -s FORCE_FILESYSTEM=1 -s ALLOW_MEMORY_GROWTH=1 -s EXPORTED_RUNTIME_METHODS=['FS','callMain'] -s ENVIRONMENT=web,worker -s EXPORT_NAME=OpenSCAD -s EXIT_RUNTIME=1|g" -i ../build/CMakeFiles/OpenSCAD.dir/link.txt

RUN cd ../build && make -j12 VERBOSE=1
