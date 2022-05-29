set -e

WGSLSMITH_ABSDIR="$(pwd)"
DAWN_SRC_ABSDIR=

if [ ! -d external_tools ]; then
  mkdir external_tools
fi

if [ "${DAWN_SRC_DIR}" ]; then
 if [ ! -d "${DAWN_SRC_DIR}" ]; then
   echo "Error: env path to dawn DAWN_SRC_DIR is not a valid directory."
   exit 1
 fi
else
 DAWN_SRC_DIR="./dawn-build/dawn"
fi
cd "${DAWN_SRC_DIR}"
DAWN_SRC_ABSDIR="$(pwd)"

# builds a standalone version of Tint from existing source files
cd "${WGSLSMITH_ABSDIR}/external_tools"
if [ ! -d tint ]; then
  mkdir tint
fi
cd tint
cmake "${DAWN_SRC_ABSDIR}"
make tint

# builds a standalone version of SPIRV-Tools from existing source files
cd "${DAWN_SRC_ABSDIR}/third_party/vulkan-deps/spirv-tools/src"
if [ ! -d build ]; then
  mkdir build
fi
cd build
cmake -DSPIRV_SKIP_TESTS=ON \
-DSPIRV-Headers_SOURCE_DIR="${DAWN_SRC_ABSDIR}/third_party/vulkan-deps/spirv-headers/src" ..
make spirv-val