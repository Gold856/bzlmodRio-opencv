workspace(name = "bzlmodrio-opencv")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

YEAR = "2025"
MAVEN_VERSION = "4.10.0-3"

########################
# Download Dependencies
########################

http_archive(
    name = "bazel_features",
    sha256 = "a015f3f2ebf4f1ac3f4ca8ea371610acb63e1903514fa8725272d381948d2747",
    strip_prefix = "bazel_features-1.31.0",
    url = "https://github.com/bazel-contrib/bazel_features/releases/download/v1.31.0/bazel_features-v1.31.0.tar.gz",
)

http_archive(
    name = "rules_java",
    sha256 = "1558508fc6c348d7f99477bd21681e5746936f15f0436b5f4233e30832a590f9",
    urls = [
        "https://github.com/bazelbuild/rules_java/releases/download/8.12.0/rules_java-8.12.0.tar.gz",
    ],
)

http_archive(
    name = "rules_jvm_external",
    sha256 = "704a0197e4e966f96993260418f2542568198490456c21814f647ae7091f56f2",
    strip_prefix = "rules_jvm_external-6.8",
    url = "https://github.com/bazelbuild/rules_jvm_external/releases/download/6.8/rules_jvm_external-6.8.tar.gz",
)

http_archive(
    name = "rules_python",
    sha256 = "690e0141724abb568267e003c7b6d9a54925df40c275a870a4d934161dc9dd53",
    strip_prefix = "rules_python-0.40.0",
    url = "https://github.com/bazelbuild/rules_python/releases/download/0.40.0/rules_python-0.40.0.tar.gz",
)

http_archive(
    name = "com_google_protobuf",
    sha256 = "10a0d58f39a1a909e95e00e8ba0b5b1dc64d02997f741151953a2b3659f6e78c",
    strip_prefix = "protobuf-29.0",
    urls = ["https://github.com/protocolbuffers/protobuf/archive/v29.0.tar.gz"],
)

http_archive(
    name = "rules_bazelrio",
    sha256 = "0c5a98476ac5b606689863b7b9ef3f7d685c47ce2681e448ca977e8e95de31c1",
    url = "https://github.com/bzlmodRio/rules_bazelrio/releases/download/0.0.14/rules_bazelrio-0.0.14.tar.gz",
)

http_archive(
    name = "rules_bzlmodrio_toolchains",
    sha256 = "b86f16f282a767bf73a341efcbd955613e4a20aa6f1fe7f229583af68e51acf8",
    urls = ["https://github.com/wpilibsuite/rules_bzlmodrio_toolchains/releases/download/2025-1.bcr5/rules_bzlmodrio_toolchains-2025-1.bcr5.tar.gz"],
)

########################

########################
# Setup Dependencies
########################

load("@bazel_features//:deps.bzl", "bazel_features_deps")

bazel_features_deps()

load("@com_google_protobuf//:protobuf_deps.bzl", "protobuf_deps")

protobuf_deps()

load("@rules_java//java:rules_java_deps.bzl", "rules_java_dependencies")

rules_java_dependencies()

load("@rules_java//java:repositories.bzl", "rules_java_toolchains")

rules_java_toolchains()

load("@bzlmodrio-opencv//private/non_bzlmod_dependencies:setup_dependencies.bzl", "setup_dependencies")

setup_dependencies()
########################

load("@rules_jvm_external//:repositories.bzl", "rules_jvm_external_deps")

rules_jvm_external_deps()

load("@rules_jvm_external//:setup.bzl", "rules_jvm_external_setup")

rules_jvm_external_setup()

load("@rules_jvm_external//:defs.bzl", "maven_install")

maven_artifacts, maven_repositories = [
    "edu.wpi.first.thirdparty.frc" + YEAR + ".opencv:opencv-java:" + MAVEN_VERSION,
], [
    "https://repo1.maven.org/maven2",
    "https://frcmaven.wpi.edu/release",
]

maven_install(
    name = "maven",
    artifacts = maven_artifacts,
    repositories = maven_repositories,
)

load("@maven//:defs.bzl", "pinned_maven_install")

pinned_maven_install()

http_archive(
    name = "rules_bzlmodrio_jdk",
    sha256 = "623b8bcdba1c3140f56e940365f011d2e5d90d74c7a30ace6a8817c037c1dd61",
    url = "https://github.com/wpilibsuite/rules_bzlmodRio_jdk/releases/download/17.0.12-7.bcr1/rules_bzlmodrio_jdk-17.0.12-7.bcr1.tar.gz",
)

load("@rules_bzlmodrio_jdk//:maven_deps.bzl", "setup_legacy_setup_jdk_dependencies")

setup_legacy_setup_jdk_dependencies()
