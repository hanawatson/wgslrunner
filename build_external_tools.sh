set -e

WGSLRUNNER_PATH="$(dirname "$(realpath "${0}")")"
cd "${WGSLRUNNER_PATH}"

if [ ! -d external_tools ]; then
  mkdir external_tools
fi

# allow for non-default locations
if [ "${DAWN_BUILD_PATH}" ]; then
  DAWN_BUILD_PATH="$(realpath "${DAWN_BUILD_PATH}")"
  if [ ! -d "${DAWN_BUILD_PATH}" ]; then
    echo "Error: env path to dawn-build DAWN_BUILD_PATH is not a valid directory."
    exit 1
  fi
else
  DAWN_BUILD_PATH="${WGSLRUNNER_PATH}/dawn-build"
fi
if [ "${WGSLSMITH_PATH}" ]; then
  WGSLSMITH_PATH="$(realpath "${WGSLSMITH_PATH}")"
  if [ ! -d "${WGSLSMITH_PATH}" ]; then
    echo "Error: env path to wgslsmith WGSLSMITH_PATH is not a valid directory."
    exit 1
  fi
else
  WGSLSMITH_PATH="${WGSLRUNNER_PATH}/wgslsmith"
fi

# builds Dawn using the dawn-build tool
cd "${DAWN_BUILD_PATH}"
./scripts/build
export DAWN_SRC_DIR="${DAWN_BUILD_PATH}/dawn"
export DAWN_BUILD_DIR="${DAWN_BUILD_PATH}/build"

# builds the wgslsmith harness using the wgslsmith build script
cd "${WGSLSMITH_PATH}/harness"
cargo build --release

# builds a standalone version of Tint from existing Dawn files
cd "${WGSLRUNNER_PATH}/external_tools"
if [ ! -d tint ]; then
  mkdir tint
fi
cd tint
cmake "${DAWN_SRC_DIR}"
make tint

# builds a standalone version of spirv-val from existing Dawn files
cd "${DAWN_SRC_DIR}/third_party/vulkan-deps/spirv-tools/src"
if [ ! -d build ]; then
  mkdir build
fi
cd build
cmake -DSPIRV_SKIP_TESTS=ON \
-DSPIRV-Headers_SOURCE_DIR="${DAWN_SRC_DIR}/third_party/vulkan-deps/spirv-headers/src" ..
make spirv-val

# builds a standalone version of glslangValidator from existing Dawn files
cd "${DAWN_SRC_DIR}/third_party/vulkan-deps/glslang/src"
if [ ! -d build ]; then
  mkdir build
fi
cd build
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$(pwd)/install" ..
make -j4 install