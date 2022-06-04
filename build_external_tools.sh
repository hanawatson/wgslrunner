set -e

WGSLRUNNER_DIR="$(pwd)"

if [ ! -d external_tools ]; then
  mkdir external_tools
fi

# builds Dawn using the wgslsmith build script
cd wgslsmith
./build.py dawn
DAWN_DIR="${WGSLRUNNER_DIR}/wgslsmith/external/dawn"

# builds the wgslsmith harness using the wgslsmith build script
cd harness
cargo build --release

# builds a standalone version of Tint from existing Dawn files
cd "${WGSLRUNNER_DIR}/external_tools"
if [ ! -d tint ]; then
  mkdir tint
fi
cd tint
cmake "${DAWN_DIR}"
make tint

# builds a standalone version of SPIRV-Tools from existing Dawn files
cd "${DAWN_DIR}/third_party/vulkan-deps/spirv-tools/src"
if [ ! -d build ]; then
  mkdir build
fi
cd build
cmake -DSPIRV_SKIP_TESTS=ON \
-DSPIRV-Headers_SOURCE_DIR="${DAWN_DIR}/third_party/vulkan-deps/spirv-headers/src" ..
make spirv-val

# builds a standalone version of glslang from existing Dawn files
cd "${DAWN_DIR}/third_party/vulkan-deps/glslang/src"
if [ ! -d build ]; then
  mkdir build
fi
cd build
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$(pwd)/install" ..
make -j4 install