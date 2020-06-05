using BinaryBuilder
using Pkg

# Collection of sources required to build Darknet
name = "Darknet_CUDA"
version = v"2020.6.5"
sources = [
    ArchiveSource("https://github.com/AlexeyAB/darknet/archive/3708b2e47d355ba0a206fd7a06bbc5a6e38af4ff.zip", "e18a6374822fe3c9b95f2b6a4086decbdfbd1c589f2481ce5704a4384044ea6f")
]

script = raw"""
cd $WORKSPACE/srcdir/darknet-*


## CUDA setup

mv cudnn $prefix

if [[ "${target}" == *-apple-* ]]; then
    mkdir -p /usr/local/cuda/lib
    cd /usr/local/cuda/lib
    ln -s ${prefix}/cuda/lib/libcudart.so libcudart.so
    ln -s ${prefix}/cuda/lib/libnvToolsExt.so libnvToolsExt.so
else
    mkdir -p /usr/local/cuda/lib64
    cd /usr/local/cuda/lib64
    ln -s ${prefix}/cuda/lib64/libcudart.so libcudart.so
    ln -s ${prefix}/cuda/lib64/libnvToolsExt.so libnvToolsExt.so
fi

## Required for OPENMP=1
if [[ "${target}" == *-freebsd* ]] || [[ "${target}" == *-apple-* ]]; then
    CC=gcc
    CXX=g++
fi

## Note for the future: Supporting AVX will make more sense with microarchitecture support
# if [[ "${target}" = powerpc64le-* ]] || [[ "${target}" = arm* ]] || [[ "${target}" == aarch* ]] || [[ "${target}" == *-mingw* ]] then
#     # Disable AVX on powerpc, arm, aarch, windows, apple
#     export AVXENABLE=0
# else
#     # Enable everywhere else (linux)
#     export AVXENABLE=1
# fi
export AVXENABLE=0

# Make sure to have the directories, before building
# make obj backup results setchmod
make OPTS="" -j${nproc} libdarknet.${dlext} \
    LIBNAMESO="libdarknet.${dlext}" \
    LIBSO=1 \
    GPU=1 \
    CUDNN=1 \
    CUDNN_HALF=1 \
    OPENCV=0 \
    DEBUG=0 \
    OPENMP=1 \
    ZED_CAMERA=0 \
    AVX=${AVXENABLE}

mkdir -p "${libdir}"
cp libdarknet.${dlext} "${libdir}"
rm -rf $prefix/cuda
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libdarknet", :libdarknet),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="CUDA_full_jll", version=v"10.1.243")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
