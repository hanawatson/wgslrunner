# wgslrunner

This tool combines the [wgslgenerator](https://github.com/hanawatson/wgslgenerator)
WGSL code generator with the testing harness from the
[wgslsmith](https://github.com/wgslsmith/wgslsmith) project, as well as
external validation tools like [spirv-val](https://github.com/KhronosGroup/SPIRV-Tools)
and [glslang](https://github.com/KhronosGroup/glslang). It is used to
test
the [Dawn](https://dawn.googlesource.com/dawn/) and [wgpu](https://github.com/gfx-rs/wgpu) WebGPU APIs, and their
respective WGSL compilers [Tint](https://dawn.googlesource.com/tint) and [naga](https://github.com/gfx-rs/naga).
An external script, [dawn-build](https://github.com/wgslsmith/dawn-build), is also used to build Dawn.

## Prerequisites

wgslrunner can be cloned using:

```
$ git clone --recurse-submodules https://github.com/hanawatson/wgslrunner wgslrunner
```

wgslrunner makes use of several tools and submodules. These will be cloned with the `recurse-submodules` flag in the above command. The various tools can then be built by running the `build_external_tools.sh` script included in wgslrunner. Use of the script is recommended to save space on the user's machine, rather than re-download large projects like Tint.

If any tool or repository is already located in a different directory on a user's machine, they can indicate this by setting the relevant environment variable (see the Enviroment variables section below). If the variables corresponding to dawn-build and/or wgslsmith are set when running the external tool-building script, the tools will be built as normal in these specified locations.

Note: due to compatibility issues, wgslrunner uses a previous version of wgslsmith. If the user provides a non-default path for wgslsmith, it must be at [commit 3db5017509](https://github.com/wgslsmith/wgslsmith/tree/3db5017509d7773dfa7b32e0e61801ad13827466) or earlier. If a later version is used, the harness tests run by wgslrunner will always fail, but other tests will function as normal.

## Usage instructions

wgslrunner can be used by running its associated shell script, `wgslrun.sh`. Several flags may be specified.

| Flag | Meaning | Default value |
| ---- | ------- | ------------- |
| `-h`, `--help` | Print help message | None |
| `-s <argument>`, `--input-shader <argument>` | The path of the WGSL shader that should be inputted into the various tools tested by wgslrunner | None - if unspecified, wgslgenerator will be used to generate a random shader |
| `-b <argument>`, `--input-bindings <argument>` | The path of the bindings JSON file that should be provided to the harness (more details about which can be found in the wgslsmith documentation) | None - if unspecified, default bindings compatible with wgslgenerator's output will be used |
| `-c <argument>`, `--input-config <argument>` | The path of the configuration JSON file that should be provided to wgslgenerator during shader generation (more details about which can be found in wgslgenerator documentation) | None - if unspecified, wgslgenerator will use its default configuration |
| `-j`, `--use-generator-jar` | Enables usage of the standalone `wgslgenerator.jar` jar (see the [relevant wgslgenerator README section](https://github.com/hanawatson/wgslgenerator#standalone-jar)), which must be located in the top-level wgslrunner directory | Disabled |
| `-(e/E)`, `--(enable/disable)-log-on-error` | Enable/disable logging of the relevant shader, bindings and output of wgslrunner if any test fails | Enabled |
| `-(o/O)`, `--(enable/disable)-log-on-ok` | Enable/disable logging of the relevant shader, bindings and output of wgslrunner if all tests pass | Disabled |
| `-(p/P)`, `--(enable/disable)-print-error-detail` | Enable/disable printing error output to the console if any tests fail | Disabled |
| `-(t/T)`, `--(enable/disable)-terminate-after-error` | Enable/disable termination if any test fails, rather than continuing with the rest | Enabled |

Note: both `input-shader` and `input-bindings` must be provided, or neither.

## Environment variables

The following environment variables are used by wgslrunner to locate various external tools, and should be set if different. The variable corresponding to dawn-build is relevant to the external tool-building script, but not to wgslrun itself.

| Variable | Tool | Default path (relative to wgslrunner directory) |
| -------- | ---- | ----------------------------------------------- |
| `$WGSLGENERATOR_PATH` | [wgslgenerator](https://github.com/hanawatson/wgslgenerator) | `wgslgenerator` |
| `$WGSLSMITH_PATH` | [wgslsmith](https://github.com/wgslsmith/wgslsmith) | `wgslsmith` |
| `$DAWN_BUILD_PATH` | [dawn-build](https://github.com/wgslsmith/dawn-build) | `dawn-build` |
| `$DAWN_PATH` | [Dawn](https://dawn.googlesource.com/dawn) | `$DAWN_BUILD_PATH/dawn` |
| `$TINT_PATH` | [Tint](https://dawn.googlesource.com/tint) | `external_tools/tint` |
| `$SPIRV_VAL_PATH` | [SPIRV-Tools](https://github.com/KhronosGroup/SPIRV-Tools) | `$DAWN_PATH/third_party/vulkan-deps/spirv-tools/src/build/tools` |
| `$GLSLANG_PATH` | [glslang](https://github.com/KhronosGroup/glslang) | `$DAWN_PATH/third_party/vulkan-deps/glslang/src/build/install/bin` |

## Requirements

- JDK with Java version >= 1.8
- Bash
- Make
- Cmake and Ninja for building Dawn
- depot_tools in PATH (instructions for the installation of which can be found [here](https://commondatastorage.googleapis.com/chrome-infra-docs/flat/depot_tools/docs/html/depot_tools_tutorial.html#_setting_up) for building Dawn
