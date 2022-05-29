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

if [ "${WGSLGENERATOR_PATH}" ]; then
  if [ ! -d "${WGSLGENERATOR_PATH}" ]; then
    echo "Error: env path to wgslgenerator WGSLGENERATOR_PATH is not a valid directory."
    exit 1
  fi
else
  WGSLGENERATOR_PATH="wgslgenerator"
fi
if [ "${DAWN_SRC_DIR}" ]; then
  if [ ! -d "${DAWN_SRC_DIR}" ]; then
    echo "Error: env path to dawn DAWN_SRC_DIR is not a valid directory."
    exit 1
  fi
else
  DAWN_SRC_DIR="dawn-build/dawn"
fi
if [ "${WGSLSMITH_HARNESS_PATH}" ]; then
  if [ ! -d "${WGSLSMITH_HARNESS_PATH}" ]; then
    echo "Error: env path to harness-containing wgslsmith WGSLSMITH_HARNESS_PATH is not a valid directory."
    exit 1
  fi
else
  WGSLSMITH_HARNESS_PATH="wgslsmith"
fi
if [ "${TINT_DIR}" ]; then
  if [ ! -d "${TINT_DIR}" ]; then
    echo "Error: env path to Tint TINT_DIR is not a valid directory."
    exit 1
  fi
else
  TINT_DIR="external_tools/tint"
fi
if [ "${SPIRV_VAL_DIR}" ]; then
  if [ ! -d "${SPIRV_VAL_DIR}" ]; then
    echo "Error: env path to spirv-val SPIRV_VAL_DIR is not a valid directory."
    exit 1
  fi
else
  SPIRV_VAL_DIR="${DAWN_SRC_DIR}/third_party/vulkan-deps/spirv-tools/src/build/tools"
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

WGSLSMITH_HARNESS_RELEASE_PATH="${WGSLSMITH_HARNESS_PATH}/harness/target/release"
if [ ! -d "${WGSLSMITH_HARNESS_RELEASE_PATH}" ]; then
  echo "Error: could not find harness under provided wgslsmith harness path. Has the harness been built?"
  exit 1
fi
WGSLSMITH_HARNESS_NAGA_PATH="${WGSLSMITH_HARNESS_PATH}/harness/external/naga"
if [ ! -d "${WGSLSMITH_HARNESS_NAGA_PATH}" ]; then
  echo "Error: could not find naga under provided wgslsmith harness path. Has the harness been built?"
  exit 1
fi

./gradlew run --args="${WGSLGENERATOR_PATH} ${WGSLSMITH_HARNESS_PATH} ${TINT_DIR} ${SPIRV_VAL_DIR} \
${LOG_ON_ERROR} ${LOG_ON_OK} ${PRINT_ERROR_DETAIL} ${TERMINATE_AFTER_ERROR} \
shad:${INPUT_SHADER_FILE} bind:${INPUT_BINDINGS_FILE} conf:${INPUT_CONFIG_FILE}" -quiet