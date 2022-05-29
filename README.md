# wgslsmith

## Usage instructions

This tool combines the [wgslgenerator](https://github.com/hanawatson/wgslgenerator)
WGSL code generator with the testing harness from the
[wgslsmith](https://github.com/wgslsmith/wgslsmith) project by [hasali19](https://github.com/hasali19).

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

Both wgslgenerator and hasali19's wgslsmith should be located in the top level of the wgslsmith directory.
If either project has already been cloned somewhere else, the `$WGSLGENERATOR_PATH` and
`$WGSLSMITH_HARNESS_PATH` environment variables should be set accordingly. If these variables are empty or unset, the
default locations will be
assumed.

## Requirements

- JDK with Java version >= 1.8
- Bash
- Child requirements (found on Git pages for hasali19's wgslsmith, dawn-build etc.)