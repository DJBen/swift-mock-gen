"""Definitions for handling dependencies used by swift-mock-gen."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def _maybe(repo_rule, name, **kwargs):
    """Executes the given repository rule if it hasn't been executed already.
    Args:
      repo_rule: The repository rule to be executed (e.g., `git_repository`.)
      name: The name of the repository to be defined by the rule.
      **kwargs: Additional arguments passed directly to the repository rule.
    """
    if not native.existing_rule(name):
        repo_rule(name = name, **kwargs)

def swift_mock_gen_dependencies():
    _maybe(
        http_archive,
        name = "bazel_skylib",
        urls = [
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.3.0/bazel-skylib-1.3.0.tar.gz",
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.3.0/bazel-skylib-1.3.0.tar.gz",
        ],
        sha256 = "74d544d96f4a5bb630d465ca8bbcfe231e3594e5aae57e1edbf17a6eb3ca2506",
    )

    _maybe(
        http_archive,
        name = "swift_argument_parser",
        build_file = "@//:third_party/swift_argument_parser/BUILD.bazel.in",
        sha256 = "e5010ff37b542807346927ba68b7f06365a53cf49d36a6df13cef50d86018204",
        strip_prefix = "swift-argument-parser-1.3.0",
        urls = [
            "https://github.com/apple/swift-argument-parser/archive/refs/tags/1.3.0.tar.gz",
        ],
    )

    _maybe(
        http_archive,
        name = "swift_syntax",
        sha256 = "1a516cf344e4910329e3ba28e04f53f457bba23e71e7a4a980515ccc29685dbc",
        strip_prefix = "swift-syntax-509.0.2",
        urls = [
            "https://github.com/apple/swift-syntax/archive/refs/tags/509.0.2.tar.gz",
        ],
    )
