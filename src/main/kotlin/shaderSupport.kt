package wgslsmith.wgslrunner

internal val tempOutputs = mapOf(
    Pair("dot", "temp_output.dot"),
    Pair("glsl", "temp_output.comp"),
    Pair("glsl-comp", "temp_output.comp"),
    Pair("hlsl", "temp_output.hlsl"),
    Pair("metal", "temp_output.metal"),
    Pair("spirv", "temp_output.spv"),
    Pair("spirv-asm", "temp_output.spvasm"),
    Pair("wgsl", "temp_output.wgsl")
)

internal val glslSupportedProfiles = listOf("es310", "es320", "core420", "core430")
internal val glslSupportedInputProfiles = listOf("core440", "core450")