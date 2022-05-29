# wgslsmith

This tool combines the [wgslgenerator](https://github.com/hanawatson/wgslgenerator)
WGSL code generator with the testing harness from the
[wgslsmith](https://github.com/wgslsmith/wgslsmith) project by [hasali19](https://github.com/hasali19), as well as external validation tools like [spirv-val](https://github.com/KhronosGroup/SPIRV-Tools). It is used to test the [Dawn](https://dawn.googlesource.com/dawn/) and [wgpu](https://github.com/gfx-rs/wgpu) WebGPU APIs, as well as their respective WGSL compilers [Tint](https://dawn.googlesource.com/tint) and [naga](https://github.com/gfx-rs/naga).

## Prerequisites

wgslsmith and wgslgenerator can be cloned using:

```
$ git clone https://github.com/hanawatson/wgslsmith
$ cd wgslsmith
$ git clone https://github.com/hanawatson/wgslgenerator
```

hasali19's wgslsmith can be obtained by following the directions in the Harness section
of its [documentation](https://wgslsmith.github.io/harness/building.html). These instructions
should be followed instead of those immediately on its main GitHub page. Additionally, the
recommendations made during the instructions should be treated as mandatory, including the
usage of Ninja and the [dawn-build](https://github.com/wgslsmith/dawn-build) script.

wgslgenerator, hasali19's wgslsmith and dawn-build should be located in the top level of the wgslsmith directory.
If any repository has already been cloned somewhere else, the `$WGSLGENERATOR_PATH`,
`$WGSLSMITH_HARNESS_PATH` and `$DAWN_BUILD_SRC` (pointing to the dawn submodule within dawn-build) environment variables should be set accordingly. If these variables are empty or unset, the
default locations will be assumed.

In addition, wgslsmith makes use of the Tint compiler and spirv-val (a tool included in the [SPIRV-Tools](https://github.com/KhronosGroup/SPIRV-Tools) project) as standalone executables. These can be downloaded and built from source manually, in which case the `$TINT_PATH` and `$SPIRV_VAL_PATH` environment variables should be set, or can be assembled from existing files in the Dawn source code by using the `build_external_tools.sh` script included in wgslsmith. Use of this script is recommended to save space on the user's machine, as Tint in particular is a large repository.

## Usage instructions

wgslsmith can be used by running its associated shell script, `wgslsmith.sh`. Several flags may be specified.

| Flag | Meaning | Default value |
| ---- | ------- | ------------- |
| `-s <argument>`, `--input-shader <argument>` | The path of the WGSL shader that should be inputted into the various tools tested by wgslsmith | None - if unspecified, wgslgenerator will be used to generate a random shader |
| `-b <argument>`, `--input-bindings <argument>` | The path of the bindings JSON file that should be provided to the harness (more details about which can be found in hasali19's wgslsmith documentation) | None - if unspecified, default bindings compatible with wgslgenerator's output will be used |
| `-c <argument>`, `--input-config <argument>` | The path of the configuration JSON file that should be provided to wgslgenerator during shader generation (more details about which can be found in wgslgenerator documentation) | None - if unspecified, wgslgenerator will use its default configuration |
| `-(e/E)`, `--(enable/disable)-log-on-error` | Enable/disable logging of the relevant shader, bindings and output of wgslsmith if any of its tests fail | Enabled |
| `-(o/O)`, `--(enable/disable)-log-on-ok` | Enable/disable logging of the relevant shader, bindings and output of wgslsmith even if all tests succeed | Disabled |
| `-(p/P)`, `--(enable/disable)-print-error-detail` | Enable/disable printing error output to the console if any tests fail | Disabled |
| `-(t/T)`, `--(enable/disable)-terminate-after-error` | Enable/disable termination if any tests fail, rather than carrying on with remaining tests | Enabled |

Note: both `input-shader` and `input-bindings` must be provided, or neither.

The following environment variables are also used by wgslsmith, and should be set if different.

| Variable | Default path (relative to wgslsmith directory) |
| -------- | ------------- |
| `$WGSLGENERATOR_PATH` | `wgslgenerator` |
| `$DAWN_SRC_DIR` | `dawn-build/dawn` |
| `$WGSLSMITH_HARNESS_PATH` | `wgslsmith` |
| `$TINT_DIR` | `external_tools/tint` |
| `$SPIRV_VAL_DIR` | `$DAWN_SRC_DIR/third_party/vulkan-deps/spirv-tools/src/build/tools` |

## Requirements

- JDK with Java version >= 1.8
- Bash
- Make (for external tool building script)
- Child requirements (found on Git pages for hasali19's wgslsmith, dawn-build etc.)
