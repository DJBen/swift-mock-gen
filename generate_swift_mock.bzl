"""
Bazel rule to generate mock impls of the protocols from provided source swift files.
"""
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
load("@bazel_skylib//lib:paths.bzl", "paths")

def _extract_target_name(label):
    """
    Extract the target name from a Bazel label.
    """
    if label.startswith("@"):
        # For external repositories, split by '//' and then process
        label = label.split("//")[-1]

    if label.startswith("//"):
        parts = label.split(":")
        if len(parts) == 2:
            # Full label with explicit target, split by ':'
            return parts[-1]
        else:
            # Full label with implicit target (same as package name)
            return parts[0].split("/")[-1]
    elif label.startswith(":"):
        # Relative label, remove the leading ':'
        return label[1:]
    else:
        return label

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
    if ctx.attr.additional_imports:
        args.append("-i")
        for additional_import in ctx.attr.additional_imports:
            args.append(additional_import)

    outputs = []

    for src_file in ctx.files.srcs:
        # Output file for each source file
        base_name = src_file.basename
        if base_name.endswith(".swift"):
            base_name = base_name[:-6]  # Remove '.swift' extension

        output_file_path = paths.join(base_name + "Mock.swift")
        outputs.append(ctx.actions.declare_file(output_file_path))

    args += ["-o", paths.join(ctx.genfiles_dir.path, ctx.label.package)]

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
        "additional_imports": attr.string_list(doc="Additional modules to import; useful if you are compiling the generated files into a separate module, and thus needing to import the API module in which the protocols reside."),
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

def generate_swift_mock_module(
    api_module,
    srcs,
    mock_module_name = None,
    deps = [],
    copy_imports = True,
    exclude_protocols = [],
    additional_imports = [],
    generate_swift_mock_tool = "@swift_mock_gen//:swift-mock-gen",
    **kwargs,
):
    """
    Generate the swift mock module from sources.

    Args:
        api_module (str): the label string of the API module.
        srcs (list): The source files.
        mock_module_name (Optional[str]): if preesnt, the generated mock module will take this name; otherwise it's the api_module's name + 'Mock'.
        deps (depset): The dependencies of the mock module aside of the api_module.
        copy_imports (bool): whether to copy the imports declared in the api source files. Defaults to true
        exclude_protocols (list): A str list of protocols that shall be excluded from mock generation. Use this if you encounter a problem in compilation.
        additional_imports (list): Additional imports to add to the mock.
        generate_swift_mock_tool (str): The label of the mock generation tool.
        **kwargs:
    """

    api_module_name = _extract_target_name(api_module)
    mock_module_name = api_module_name + "Mock" if mock_module_name == None else mock_module_name
    gen_mock_rule_name = (api_module_name if mock_module_name == None else api_module_name + "_" + mock_module_name) + "_GenerateSwiftMock"

    generate_swift_mock(
        name = gen_mock_rule_name,
        srcs = srcs,
        copy_imports = copy_imports,
        additional_imports = [api_module_name] + additional_imports,
        exclude_protocols = exclude_protocols,
        generate_swift_mock_tool = generate_swift_mock_tool,
    )

    swift_library(
        name = mock_module_name,
        srcs = [gen_mock_rule_name],
        deps = [
            api_module
        ] + deps,
        copts = [
            # make headermaps available for transitive header preprocessing for
            # imports from swift code
            "-Xcc",
            # headermap values, representing paths to headers, are paths relative to
            # execroot, so we pass '-I.' to correctly resolve hmap header paths.
            "-I.",
        ],
        module_name = mock_module_name,
        visibility = kwargs.get('visibility', ["//visibility:public"]),
    )

def swift_mock_gen_config(
    exclude_protocols = [],
    verbose = False,
):
    """
    A config that controls swift mock gen behavior.

    Args:
        exclude_protocols (list): A list of protocol names to be excluded from the
                                  Swift mock generation process. This parameter allows
                                  selective exclusion of certain protocols from being
                                  mocked. If left empty, no protocols are excluded.
        verbose (bool): A flag to toggle verbose outputs.
    """
    return struct(
        exclude_protocols = exclude_protocols,
        verbose = verbose,
    )