FROM ${DOCKER_TAG_BASE}
ARG DOCKER_TAG_BASE=openscad-base
ARG CMAKE_BUILD_TYPE=Release

COPY . . 
RUN emcmake cmake -B ../build . \
        -DBoost_USE_STATIC_RUNTIME=ON \
        -DBoost_USE_STATIC_LIBS=ON \
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} \
        -DEXPERIMENTAL=ON \
        -DSNAPSHOT=ON \
        -G Ninja && \
    cmake --build ../build --parallel
