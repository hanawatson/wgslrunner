package wgslsmith

import java.io.File
import java.nio.charset.Charset
import java.time.LocalTime

fun main(args: Array<String>) {
    var inputShader: File? = null
    var inputBindings: File? = null
    var inputConfig: File? = null

    val mandatoryArguments = 8
    for (arg in args.drop(mandatoryArguments)) {
        when {
            arg.startsWith("shad:") -> {
                inputShader = if (arg.removePrefix("shad:").isBlank()) null else {
                    File(arg.removePrefix("shad:"))
                }
            }
            arg.startsWith("bind:") -> {
                inputBindings = if (arg.removePrefix("bind:").isBlank()) null else {
                    File(arg.removePrefix("bind:"))
                }
            }
            arg.startsWith("conf:") -> {
                inputConfig = if (arg.removePrefix("conf:").isBlank()) null else {
                    File(arg.removePrefix("conf:"))
                }
            }
        }
    }

    val generatorDir = File(args[0]).absoluteFile
    val nagaDir = File("${args[1]}/harness/external/naga").absoluteFile
    val harnessDir = File("${args[1]}/harness/target/release").absoluteFile
    val tintDir = File(args[2]).absoluteFile
    val spirvValDir = File(args[3]).absoluteFile
    val logOnError = args[4] == "1"
    val logOnOK = args[5] == "1"
    val printErrorDetail = args[6] == "1"
    val terminateAfterError = args[7] == "1"

    val (shader, bindings) = if (inputShader != null) {
        try {
            Pair(inputShader.readText(), inputBindings!!.readText())
        } catch (e: Exception) {
            System.err.println(
                "Error: failed to read input files. Internal error follows." +
                        "\n\n\t${e.message?.replace("\n", "\n\t")}"
            )
            return
        }
    } else {
        val genCommand = if (inputConfig != null) {
            listOf("./wgslgen.sh", "-c", inputConfig.absolutePath)
        } else {
            listOf("./wgslgen.sh")
        }
        val genProcess = ProcessBuilder(genCommand).directory(generatorDir).start()
        val genShader = genProcess.inputStream.reader(Charset.defaultCharset()).use { it.readText() }
        val genShaderError = genProcess.errorStream.reader(Charset.defaultCharset()).use { it.readText() }
        if (genShaderError.isNotEmpty()) {
            System.err.println(
                "Error: failed to generate WGSL shader. wgslgenerator error follows." +
                        "\n\n\t${genShaderError.replace("\n", "\n\t")}"
            )
            return
        }

        val usesOutputBuffer = genShader.contains("outputBuffer")
        val bindingsToUse = if (usesOutputBuffer) "bindingsWithBuffer.json" else "bindingsWithoutBuffer.json"
        val defaultBindings = File("src/main/resources/$bindingsToUse")
        if (!defaultBindings.isFile) {
            System.err.println("Error: default bindings file could not be found in expected location.")
            return
        }

        try {
            Pair(genShader, defaultBindings.readText())
        } catch (e: Exception) {
            System.err.println(
                "Error: failed to read default bindings file. Internal error follows." +
                        "\n\n\t${e.message?.replace("\n", "\n\t")}"
            )
            return
        }
    }

    val tempTintShader = File("$tintDir/temp_shader_tint.wgsl").absoluteFile
    val tempNagaShader = File("$nagaDir/temp_shader_naga.wgsl").absoluteFile
    val tempHarnessShader = File("$harnessDir/temp_shader.wgsl").absoluteFile
    val tempHarnessBindings = File("$harnessDir/temp_bindings.json").absoluteFile

    val tempInputs = listOf(tempTintShader, tempNagaShader, tempHarnessShader, tempHarnessBindings)

    try {
        for (tempInput in tempInputs) {
            val input = when (tempInput) {
                // allow for the current difference in compute stage annotation between Tint and naga
                tempNagaShader      -> shader.replaceFirst("@stage(compute)", "@compute")
                tempHarnessBindings -> bindings
                else                -> shader
            }

            tempInput.createNewFile()
            tempInput.writeText(input)
            tempInput.deleteOnExit()
        }
    } catch (e: Exception) {
        System.err.println(
            "Error: failed to write to temporary input files. Internal error follows." +
                    "\n\n\t${e.message?.replace("\n", "\n\t")}"
        )
        return
    }

    // ensure cleanup is done of any output files that may be generated
    try {
        for (tempOutput in tempOutputs.values) {
            val tempTintOutputFile = File("$tintDir/$tempOutput")
            tempTintOutputFile.createNewFile()
            tempTintOutputFile.deleteOnExit()

            val tempNagaOutputFile = File("$nagaDir/$tempOutput")
            tempNagaOutputFile.createNewFile()
            tempNagaOutputFile.deleteOnExit()
        }
    } catch (e: Exception) {
        System.err.println(
            "Error: failed to create temporary output files. Internal error follows." +
                    "\n\n\t${e.message?.replace("\n", "\n\t")}"
        )
        return
    }

    val processesToRun = ArrayList<ShaderProcess>()

    val tintInputOutputLangs = listOf("spirv", "spirv-asm", "wgsl")
    val tintOutputLangs = listOf("hlsl", "metal")
    val nagaInputOutputLangs = listOf("glsl", "spirv", "wgsl")
    val nagaOutputLangs = listOf("dot", "hlsl", "metal")

    val glslInputOutputProfiles = glslSupportedInputProfiles
    val glslOutputProfiles = glslSupportedProfiles

    try {
        processesToRun.add(ShaderProcess("tint", tintDir, inputShader = tempTintShader.path))
        for (lang in tintInputOutputLangs) {
            processesToRun.add(ShaderProcess("tint", tintDir, inputShader = tempTintShader.path, outputLang = lang))
            processesToRun.add(ShaderProcess("tint", tintDir, outputLang = lang))
            if (lang == "spirv") {
                val inputSpirv = "$tintDir/${tempOutputs[lang]}"
                processesToRun.add(ShaderProcess("tint", spirvValDir, outputLang = lang, inputSpirv = inputSpirv))
            }
        }
        for (lang in tintOutputLangs) {
            processesToRun.add(ShaderProcess("tint", tintDir, inputShader = tempTintShader.path, outputLang = lang))
        }

        processesToRun.add(ShaderProcess("naga", nagaDir, inputShader = tempNagaShader.path))
        for (lang in nagaInputOutputLangs) {
            if (lang == "glsl") {
                for (profile in glslInputOutputProfiles) {
                    processesToRun.add(
                        ShaderProcess(
                            "naga", nagaDir, inputShader = tempNagaShader.path, outputLang = lang, glslProfile = profile
                        )
                    )
                    processesToRun.add(ShaderProcess("naga", nagaDir, outputLang = lang, glslProfile = profile))
                }
                for (profile in glslOutputProfiles) {
                    processesToRun.add(
                        ShaderProcess(
                            "naga", nagaDir, inputShader = tempNagaShader.path, outputLang = lang, glslProfile = profile
                        )
                    )
                }
            } else {
                processesToRun.add(
                    ShaderProcess("naga", nagaDir, inputShader = tempNagaShader.path, outputLang = lang)
                )
                processesToRun.add(ShaderProcess("naga", nagaDir, outputLang = lang))
            }

            if (lang == "spirv") {
                val inputSpirv = "$nagaDir/${tempOutputs[lang]}"
                processesToRun.add(ShaderProcess("naga", spirvValDir, outputLang = lang, inputSpirv = inputSpirv))
            }
        }
        for (lang in nagaOutputLangs) {
            processesToRun.add(ShaderProcess("naga", nagaDir, inputShader = tempNagaShader.path, outputLang = lang))
        }

        processesToRun.add(
            ShaderProcess(
                "harness", harnessDir, inputBindings = tempHarnessBindings.path, inputShader = tempHarnessShader.path
            )
        )
    } catch (e: Exception) {
        System.err.println(
            "Error: failed to prepare to run shader processes. Internal error follows." +
                    "\n\n\t${e.message?.replace("\n", "\n\t")}"
        )
    }

    var output = "wgslsmith output:\n"
    var allPassed = true
    var lastGenCode = 0

    for (process in processesToRun) {
        val (processCode, processStatus, processOutput) = process.run(lastGenCode) ?: return
        if (processStatus.contains("output") && !processStatus.contains("validate")) {
            lastGenCode = processCode
        }
        output += "\n\t$processStatus"
        if (processCode != 0 && !processStatus.contains("Skipped")) {
            allPassed = false
            output += "\n\n$processOutput"
            if (printErrorDetail) println("\n$processOutput")
            if (terminateAfterError) break
        }
    }

    if ((allPassed && logOnOK) || (!allPassed && logOnError)) {
        val outputLogDir = File("./output_logs")

        val shaderSeedRegex = "// Random seed: (-?\\d+)".toRegex()
        val shaderSeed = try {
            shaderSeedRegex.find(shader)!!.groups[1]!!.value
        } catch (e: Exception) {
            "no_seed"
        }
        val timestamp = LocalTime.now()

        val prefix = "${outputLogDir.name}/${shaderSeed}_${timestamp}"

        try {
            if (!outputLogDir.isDirectory) {
                outputLogDir.mkdir()
            }

            val shaderFile = File("${prefix}_shader.wgsl")
            shaderFile.createNewFile()
            shaderFile.writeText(shader)

            val bindingsFile = File("${prefix}_bindings.json")
            bindingsFile.createNewFile()
            bindingsFile.writeText(bindings)

            val outputFile = File("${prefix}_output.txt")
            outputFile.createNewFile()

            // strip ANSI colour/movement characters from harness output
            val writeableRegex = "\\x1b\\[[\\d;]*[mGKHF]".toRegex()
            outputFile.writeText(writeableRegex.replace(output, ""))
        } catch (e: Exception) {
            System.err.println(
                "Error: failed to write to output log files. Internal error follows." +
                        "\n\n\t${e.message?.replace("\n", "\n\t")}"
            )
            return
        }
    }
}