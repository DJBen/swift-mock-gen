# Example Integration

This example illustrates integrating into a third party codebase to perform auto mock generation upon build via Bazel.

## Guide

For details, please refer to `BUILD.bazel`s for an example to generate mocks and use it in the tests.

To get started, one can declare mock module using the `generate_swift_mock_module` macro like below.

```python
generate_swift_mock_module(
    api_module = ":Example",
    srcs = glob(["Sources/**/*.swift"]),
    exclude_protocols = [],
)

```

Multiple `generate_swift_mock_module` for the same `api_module` can coexist, as long as they are disambiguated by different `mock_module_name`, or lack thereof, like the below example.

```python
generate_swift_mock_module(
    api_module = ":Example",
    srcs = glob(["Sources/**/*.swift"]),
    mock_module_name = "ExampleForAlphaMock",
    exclude_protocols = [],
)
```