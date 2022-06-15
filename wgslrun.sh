#!/bin/bash
set -e

# default config values
INPUT_SHADER_FILE=
INPUT_BINDINGS_FILE=
INPUT_CONFIG_FILE=
LOG_ON_ERROR=1
LOG_ON_OK=0
PRINT_ERROR_DETAIL=0
TERMINATE_AFTER_ERROR=1
USE_GEN_JAR=0

WGSLRUNNER_PATH="$(dirname "$(realpath "${0}")")"
cd "${WGSLRUNNER_PATH}"

# allow for non-default locations
if [ "${WGSLGENERATOR_PATH}" ]; then
  WGSLGENERATOR_PATH="$(realpath "${WGSLGENERATOR_PATH}")"
  if [ ! -d "${WGSLGENERATOR_PATH}" ]; then
    echo "Error: env path to wgslgenerator WGSLGENERATOR_PATH is not a valid directory."
    exit 1
  fi
else
  WGSLGENERATOR_PATH="${WGSLRUNNER_PATH}/wgslgenerator"
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
if [ "${DAWN_PATH}" ]; then
  DAWN_PATH="$(realpath "${DAWN_PATH}")"
  if [ ! -d "${DAWN_PATH}" ]; then
    echo "Error: env path to Dawn DAWN_PATH is not a valid directory."
    exit 1
  fi
else
  DAWN_PATH="${WGSLRUNNER_PATH}/dawn-build/dawn"
fi
if [ "${TINT_PATH}" ]; then
  TINT_PATH="$(realpath "${TINT_PATH}")"
  if [ ! -d "${TINT_PATH}" ]; then
    echo "Error: env path to Tint TINT_PATH is not a valid directory."
    exit 1
  fi
else
  TINT_PATH="${WGSLRUNNER_PATH}/external_tools/tint"
fi
if [ "${SPIRV_VAL_PATH}" ]; then
  SPIRV_VAL_PATH="$(realpath "${SPIRV_VAL_PATH}")"
  if [ ! -d "${SPIRV_VAL_PATH}" ]; then
    echo "Error: env path to spirv-val SPIRV_VAL_PATH is not a valid directory."
    exit 1
  fi
else
  SPIRV_VAL_PATH="${DAWN_PATH}/third_party/vulkan-deps/spirv-tools/src/build/tools"
fi
if [ "${GLSLANG_PATH}" ]; then
  GLSLANG_PATH="$(realpath "${GLSLANG_PATH}")"
  if [ ! -d "${GLSLANG_PATH}" ]; then
    echo "Error: env path to glslang GLSLANG_PATH is not a valid directory."
    exit 1
  fi
else
  GLSLANG_PATH="${DAWN_PATH}/third_party/vulkan-deps/glslang/src/build/install/bin"
fi

while [ $# -gt 0 ]; do
  case "${1}" in
    -s|--input-shader)
    if [ ! "${2}" ]; then
      echo "Error: no input shader file was provided."
      exit 1
    else
      INPUT_SHADER_FILE="${2}"
    fi
    if [ ! -f "${INPUT_SHADER_FILE}" ]; then
      echo "Error: provided input shader file does not exist."
      exit 1
    # validate that the provided input shader file ends in .wgsl
    elif [ "${INPUT_SHADER_FILE##*.}" != wgsl ]; then
      echo "Error: provided input shader file is not a WGSL file."
      exit 1
    fi
    shift
    shift
    ;;
    -b|--input-bindings)
    if [ ! "${2}" ]; then
      echo "Error: no input bindings file was provided."
      exit 1
    else
      INPUT_BINDINGS_FILE="$2"
    fi
    if [ ! -f "${INPUT_BINDINGS_FILE}" ]; then
      echo "Error: provided input bindings file does not exist."
      exit 1
    # validate that the provided input bindings file ends in .json
    elif [ "${INPUT_BINDINGS_FILE##*.}" != json ]; then
      echo "Error: provided input bindings file is not a JSON file."
      exit 1
    fi
    shift
    shift
    ;;
    -c|--input-config)
    if [ ! "${2}" ]; then
      echo "Error: no input config file was provided."
      exit 1
    else
      INPUT_CONFIG_FILE="$2"
    fi
    if [ ! -f "${INPUT_CONFIG_FILE}" ]; then
      echo "Error: provided input config file does not exist."
      exit 1
    # validate that the provided input bindings file ends in .json
    elif [ "${INPUT_CONFIG_FILE##*.}" != json ]; then
      echo "Error: provided input config file is not a JSON file."
      exit 1
    fi
    shift
    shift
    ;;
    -e|--enable-log-on-error)
    LOG_ON_ERROR=1
    shift
    ;;
    -o|--enable-log-on-ok)
    LOG_ON_OK=1
    shift
    ;;
    -p|--enable-print-error-detail)
    PRINT_ERROR_DETAIL=1
    shift
    ;;
    -t|--enable-terminate-after-error)
    TERMINATE_AFTER_ERROR=1
    shift
    ;;
    -E|--disable-log-on-error)
    LOG_ON_ERROR=0
    shift
    ;;
    -O|--disable-log-on-ok)
    LOG_ON_OK=0
    shift
    ;;
    -P|--disable-print-error-detail)
    PRINT_ERROR_DETAIL=0
    shift
    ;;
    -T|--disable-terminate-after-error)
    TERMINATE_AFTER_ERROR=0
    shift
    ;;
    -j|--use-generator-jar)
    USE_GEN_JAR=1
    shift
    ;;
    *)
    echo "Error: unrecognised argument provided."
    exit 1
    ;;
  esac
done

if [ "${INPUT_SHADER_FILE}" ] && [ ! "${INPUT_BINDINGS_FILE}" ]; then
  echo "Error: if an input shader file is provided, an input bindings file must also be provided."
  exit 1
elif [ ! "${INPUT_SHADER_FILE}" ] && [ "${INPUT_BINDINGS_FILE}" ]; then
  echo "Error: if an input bindings file is provided, an input shader file must also be provided."
  exit 1
fi

WGSLSMITH_HARNESS_PATH="${WGSLSMITH_PATH}/harness/target/release"
if [ ! -d "${WGSLSMITH_HARNESS_PATH}" ]; then
  echo "Error: could not find harness under wgslsmith path. Has the harness been built?"
  exit 1
fi

./gradlew run --args="${WGSLGENERATOR_PATH} ${WGSLSMITH_PATH} ${TINT_PATH} ${SPIRV_VAL_PATH} ${GLSLANG_PATH} \
${LOG_ON_ERROR} ${LOG_ON_OK} ${PRINT_ERROR_DETAIL} ${TERMINATE_AFTER_ERROR} ${USE_GEN_JAR} \
shad:${INPUT_SHADER_FILE} bind:${INPUT_BINDINGS_FILE} conf:${INPUT_CONFIG_FILE}" -quiet