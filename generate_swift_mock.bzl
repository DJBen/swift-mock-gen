"""
Bazel rule to generate mock impls of the protocols from provided source swift files.
"""

def _generate_swift_mock_impl(ctx):
    # Executable
    generate_swift_mock_executable = ctx.executable.generate_swift_mock_tool

    args = ["gen"]

    for src_file in ctx.files.srcs:
        args.append(src_file.path)

    if ctx.attr.exclude_protocols:
        args += ["--exclude-protocols"] + ctx.attr.exclude_protocols
    if ctx.attr.copy_imports:
        args.append("--copy-imports")

    outputs = []

    output_dir = ctx.label.name + "/Mocks/"
    for src_file in ctx.files.srcs:
        # Output file for each source file
        base_name = src_file.basename
        if base_name.endswith(".swift"):
            base_name = base_name[:-6]  # Remove '.swift' extension

        output_file_path = output_dir + src_file.dirname + "/" + base_name + "Mock.swift"
        outputs.append(ctx.actions.declare_file(output_file_path))

    args += ["-o", ctx.genfiles_dir.path + "/" + output_dir]

    ctx.actions.run(
        outputs=outputs,
        inputs=ctx.files.srcs,
        executable=generate_swift_mock_executable,
        arguments=args,
        mnemonic="SwiftMockGen",
        progress_message="Generating swift mock impl for protocols {}".format(ctx.files.srcs),
    )

    return DefaultInfo(
        files=depset(outputs),
    )

generate_swift_mock = rule(
    implementation=_generate_swift_mock_impl,
    attrs={
        "copy_imports": attr.bool(doc="Whether to copy imports"),
        "exclude_protocols": attr.string_list(doc="List of protocols to exclude from protocol generation"),
        "srcs": attr.label_list(allow_files=True, doc="Source files"),
        "generate_swift_mock_tool": attr.label(
            executable=True,
            cfg="exec",
            allow_files=True,
            default="@swift_mock_gen//:swift-mock-gen"
        ),
    },
)