ARG DOCKER_TAG_BASE=openscad/wasm-base

FROM ${DOCKER_TAG_BASE}

ARG EMSCRIPTEN_FLAGS=""
ARG CMAKE_BUILD_TYPE=Release
ARG CMAKE_BUILD_PARALLEL_LEVEL=4

RUN apt-get update && apt-get -y full-upgrade

RUN apt-get install -y --no-install-recommends ninja-build

ENV CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
ENV CMAKE_C_FLAGS="${EMSCRIPTEN_FLAGS}"
ENV CMAKE_CXX_FLAGS="${EMSCRIPTEN_FLAGS}"
ENV CMAKE_EXE_LINKER_FLAGS="${EMSCRIPTEN_FLAGS}"

COPY . . 
RUN emcmake cmake -B ../build . \
        -DBoost_USE_STATIC_RUNTIME=ON \
        -DBoost_USE_STATIC_LIBS=ON \
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} \
        -DCMAKE_BUILD_PARALLEL_LEVEL=${CMAKE_BUILD_PARALLEL_LEVEL} \
        -DEXPERIMENTAL=ON \
        -DSNAPSHOT=ON \
        -G Ninja && \
    cmake --build ../build --parallel
