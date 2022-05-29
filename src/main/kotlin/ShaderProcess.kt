package wgslsmith

import java.io.File
import java.util.concurrent.TimeUnit

internal class ShaderProcess(
    tool: String,
    private val dir: File,
    inputBindings: String = "",
    inputShader: String = "",
    outputLang: String = "",
    inputGLSL: String = "",
    inputSpirv: String = "",
    glslProfile: String = "",
) {
    private val name: String
    private val command: List<String>
    private val output: String

    init {
        output = if (outputLang != "") {
            if (glslProfile != "" && glslProfile in glslSupportedInputProfiles) {
                tempOutputs["glsl-comp"]!!
            } else {
                tempOutputs[outputLang]!!
            }
        } else ""

        if (inputShader != "" && inputBindings != "") {
            // (WebGPU) execution
            name = "$tool-execute"
            command = when (tool) {
                "harness" -> listOf("./harness", "run", inputShader, inputBindings)
                else      -> throw Exception("Unrecognised execution tool $tool requested!")
            }
        } else if (inputShader != "" && outputLang != "") {
            // shader translation
            if (tool == "naga" && glslProfile != "") {
                name = "$tool-output-$outputLang-$glslProfile"
                command = listOf("cargo", "run", inputShader, output, "--profile", glslProfile)
            } else {
                name = "$tool-output-$outputLang"
                command = when (tool) {
                    "tint" -> listOf("./tint", inputShader, "-o", output)
                    "naga" -> listOf("cargo", "run", inputShader, output)
                    else   -> throw Exception("Unrecognised translation tool $tool requested!")
                }
            }
        } else if (inputShader != "") {
            // initial input validation
            name = "$tool-input-validate"
            command = when (tool) {
                "tint" -> listOf("./tint", inputShader, "--validate")
                "naga" -> listOf("cargo", "run", inputShader)
                else   -> throw Exception("Unrecognised input validation tool $tool requested!")
            }
        } else if (inputGLSL != "") {
            // glslang validation
            name = "$tool-output-$outputLang-$glslProfile-validate-glslang"
            command = listOf("./glslangValidator", inputGLSL)
        } else if (inputSpirv != "") {
            // spirv-val validation
            name = "$tool-output-$outputLang-validate-spirv-val"
            command = listOf("./spirv-val", inputSpirv)
        } else if (outputLang != "") {
            // translation validation
            name = if (tool == "naga" && glslProfile != "") {
                "$tool-output-$outputLang-$glslProfile-validate"
            } else {
                "$tool-output-$outputLang-validate"
            }
            command = when (tool) {
                "tint" -> listOf("./tint", output, "--validate")
                "naga" -> listOf("cargo", "run", output)
                else   -> throw Exception("Unrecognised translation validation tool $tool requested!")
            }
        } else {
            throw Exception("Unrecognised tool $tool requested!")
        }
    }

    fun run(prevCode: Int): Triple<Int, String, String>? {
        val processOK: String
        val processError: String
        val processCode: Int

        val processNameWide = String.format("%-50s", name)

        print(processNameWide)

        if (prevCode != 0 && name.contains("output") && name.contains("validate")) {
            val processStatus = "[[ Skipped ]]"
            println(processStatus)
            return Triple(1, "$processNameWide$processStatus", "")
        }

        try {
            val process = ProcessBuilder(command).directory(dir).start()
            processOK = process.inputStream.reader().use { it.readText() }
            processError = process.errorStream.reader().use { it.readText() }
            val processTerminated = process.waitFor(60, TimeUnit.SECONDS)
            if (!processTerminated) {
                process.destroy()
            }
            processCode = process.exitValue()
        } catch (e: Exception) {
            System.err.println(
                "Error: failed to run $name. Internal error follows." +
                        "\n\n\t${e.message?.replace("\n", "\n\t")}"
            )
            return null
        }

        val processStatusBase = if (processCode == 0) "OK!" else "Error"
        val processStatus = "[[ $processStatusBase ]]"

        val processOutputBase = if (processCode == 0 || name.contains("glslang")) processOK else processError
        val processOutput = "$name output:\n\n\t${(processOutputBase).replace("\n", "\n\t")}"

        println(processStatus)

        return Triple(processCode, "$processNameWide$processStatus", processOutput)
    }
}