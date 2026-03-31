load("@bzlmodrio-opencv//:maven_cpp_deps.bzl", "setup_legacy_bzlmodrio_opencv_cpp_dependencies")
load("@rules_bazelrio//:nonbzlmod_setup.bzl", "setup_rules_bazelrio")
load("@rules_bzlmodrio_toolchains//:maven_deps.bzl", "setup_legacy_setup_toolchains_dependencies")
load("@rules_bzlmodrio_toolchains//toolchains:load_toolchains.bzl", "load_toolchains")
load("@rules_jvm_external//:repositories.bzl", "rules_jvm_external_deps")

def _setup_toolchains():
    setup_legacy_setup_toolchains_dependencies()

    load_toolchains()

    native.register_toolchains(
        "@local_roborio//:macos",
        "@local_roborio//:linux",
        "@local_roborio//:windows",
        "@local_systemcore//:macos",
        "@local_systemcore//:linux",
        "@local_systemcore//:windows",
        "@local_rp_bookworm32//:macos",
        "@local_rp_bookworm32//:linux",
        "@local_rp_bookworm32//:windows",
        "@local_bookworm32//:macos",
        "@local_bookworm32//:linux",
        "@local_bookworm32//:windows",
        "@local_bookworm64//:macos",
        "@local_bookworm64//:linux",
        "@local_bookworm64//:windows",
    )

def _setup_cpp_dependencies():
    setup_legacy_bzlmodrio_opencv_cpp_dependencies()

def _setup_java_dependencies():
    rules_jvm_external_deps()

def setup_dependencies():
    _setup_toolchains()
    _setup_cpp_dependencies()
    _setup_java_dependencies()

    setup_rules_bazelrio()
