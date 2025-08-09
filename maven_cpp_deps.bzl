load("@bazel_tools//tools/build_defs/repo:cache.bzl", "get_default_canonical_id")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

cc_library_headers = """cc_library(
    name = "headers",
    hdrs = glob(["**"]),
    includes = ["."],
    visibility = ["//visibility:public"],
)

filegroup(
    name = "header_files",
    srcs = glob(["**"]),
    visibility = ["//visibility:public"],
)
"""

cc_library_sources = """filegroup(
     name = "sources",
     srcs = glob(["**"]),
     visibility = ["//visibility:public"],
 )
 """

shared_build_content = """load("@rules_cc//cc:defs.bzl", "cc_library", "cc_shared_library")
load("@bzlmodrio-opencv//private/cpp/opencv:wrapped_cc_import.bzl", "wrapped_cc_import")
load("@bzlmodrio-opencv//private/cpp/opencv:wrapped_cc_import.bzl", "cc_import_name")

JNI_PATTERN=[
    "**/*jni.dll",
    "**/*jni.so*",
    "**/*jni.dylib",
    "**/*_java*.dll",
    "**/lib*_java*.dylib",
    "**/lib*_java*.so",
]

shared_srcs = glob([
        "**/*.dll",
        "**/*.so*",
        "**/*.dylib",
    ],
    exclude=JNI_PATTERN + ["**/*.so*.debug"],
    allow_empty = True,
)

shared_jni_srcs = glob(JNI_PATTERN, exclude=["**/*.so*.debug"], allow_empty=True)

[ wrapped_cc_import(
    x,
    "%static_name",
    hdrs = ["@edu_wpi_opencv-cpp_headers//:header_files"],
    includes = ["."]
) for x in shared_srcs ]

# Create the static aggregator library.
cc_library(
    name = "static",
    deps = [":" + cc_import_name(x) for x in shared_srcs] + [
        "@edu_wpi_opencv-cpp_headers//:headers",
    ],
    visibility = ["//visibility:public"],
)

filegroup(
    name = "jni",
    srcs = shared_jni_srcs + shared_srcs,
    visibility = ["@bzlmodrio-opencv//:__subpackages__"],
)
"""

static_build_content = """load("@bzlmodrio-opencv//private/cpp/opencv:wrapped_cc_import.bzl", "static_alias")

exports_files(glob(["**"]))

libraries = glob(["**/*.lib", "**/*.a"], allow_empty=True)

static_alias(
    name = "static_library_file",
    libraries = libraries,
    visibility = ["//visibility:public"],
)
"""

def _update_integrity_attr(ctx, attrs, download_info):
    if ctx.attr.sha256:
        return ctx.repo_metadata(reproducible = True)

    fail("sha256 required for", ctx.label)

_download_and_generate_attrs = {
    "integrity": attr.string(),
    "sha256": attr.string(),
    "static_repository_name": attr.string(),
    "url": attr.string(),
}

def _download_and_generate_impl(rctx):
    urls = [rctx.attr.url]

    rctx.download_and_extract(
        url = urls,
        sha256 = rctx.attr.sha256,
        canonical_id = get_default_canonical_id(rctx, urls),
    )

    rctx.file("WORKSPACE", "")

    rctx.file("BUILD.bazel", shared_build_content.replace("%static_name", rctx.attr.static_repository_name))
    rctx.file("libs.bzl", """load("@bzlmodrio-opencv//private/cpp/opencv:wrapped_cc_import.bzl", "cc_import_name")
shared_srcs = glob([
        "**/*.dll",
        "**/*.so*",
        "**/*.dylib",
    ],
    allow_empty = True,
)

# The list of shared libraries to link against for opencv.
# This needs to be a list rather than a target so we don't try to dynamically link the list target.
# CcSharedLibraryInfo only supports 1 link target per dependency.
shared_libraries = [ cc_import_name(x) for x in shared_srcs ]
""")

    if rctx.attr.sha256:
        return rctx.repo_metadata(reproducible = True)

    fail("sha256 required for", rctx.label)

_download_and_generate = repository_rule(
    implementation = _download_and_generate_impl,
    attrs = _download_and_generate_attrs,
)

YEAR = "2025"
MAVEN_VERSION = "4.10.0-3"

def __static_shared_pair(mctx, name, shared_sha256, static_sha256):
    shared_name = name
    if name.endswith("debug"):
        static_name = name[:-5] + "staticdebug"
    else:
        static_name = name + "static"

    shared_url = "https://frcmaven.wpi.edu/release/edu/wpi/first/thirdparty/frc" + YEAR + "/opencv/opencv-cpp/" + MAVEN_VERSION + "/opencv-cpp-" + MAVEN_VERSION + "-" + shared_name + ".zip"
    static_url = "https://frcmaven.wpi.edu/release/edu/wpi/first/thirdparty/frc" + YEAR + "/opencv/opencv-cpp/" + MAVEN_VERSION + "/opencv-cpp-" + MAVEN_VERSION + "-" + static_name + ".zip"
    static_repository_name = "edu_wpi_opencv-cpp_" + static_name
    shared_repository_name = "edu_wpi_opencv-cpp_" + shared_name
    maybe(
        http_archive,
        static_repository_name,
        url = static_url,
        sha256 = static_sha256,
        build_file_content = static_build_content,
    )
    maybe(
        _download_and_generate,
        shared_repository_name,
        url = shared_url,
        sha256 = shared_sha256,
        static_repository_name = static_repository_name,
    )

def __setup_bzlmodrio_opencv_cpp_dependencies(mctx):
    # BEGIN static shared pairs
    maybe(
        http_archive,
        "edu_wpi_opencv-cpp_headers",
        url = "https://frcmaven.wpi.edu/release/edu/wpi/first/thirdparty/frc2025/opencv/opencv-cpp/4.10.0-3/opencv-cpp-4.10.0-3-headers.zip",
        sha256 = "b5b7c4a73300b71b96569a26041bc59702b6d4974e60725a569e2d50b140d65e",
        build_file_content = cc_library_headers,
    )
    maybe(
        http_archive,
        "edu_wpi_opencv-cpp_sources",
        url = "https://frcmaven.wpi.edu/release/edu/wpi/first/thirdparty/frc2025/opencv/opencv-cpp/4.10.0-3/opencv-cpp-4.10.0-3-sources.zip",
        sha256 = "894d273ee8eece2e1f588aad8e7cf61f56a900279c864433984bd5299a31776c",
        build_file_content = cc_library_sources,
    )
    __static_shared_pair(
        mctx,
        name = "linuxathena",
        shared_sha256 = "4fcd469a24bb597e0bc8636b36d45caca4314bed483a3dcae73f76bba7b218b2",
        static_sha256 = "b2822a98e98086513e4b127cbd6e54effa3f3c7f3f86480b64ecdcadaee07e6f",
    )
    __static_shared_pair(
        mctx,
        name = "linuxathenadebug",
        shared_sha256 = "688172bc8d10409b1a1e7cebbffaebc4fc9d52c81dea70d305859a6d9fc6f75a",
        static_sha256 = "84d9df452eb1d77683c8811a50d618e9f07873014a04ab0c523ad12247bf7adc",
    )
    __static_shared_pair(
        mctx,
        name = "linuxsystemcore",
        shared_sha256 = "bd8f19fdd16291ba940cbccc68dee737ecc74c0035adfe75165c6aa2b5734afd",
        static_sha256 = "a97b3e9326a6c7aa6ee97233495540b382a312fa57bd02b8d11b21703937e5e9",
    )
    __static_shared_pair(
        mctx,
        name = "linuxsystemcoredebug",
        shared_sha256 = "b384fcfc4d5b060dd26f4518f5782ab5e21a82b9be26656861eb031fe6df1193",
        static_sha256 = "455880a03db5e5af9bf337526eca065b59d3aa670ff2b1e4d055cec71339db72",
    )
    __static_shared_pair(
        mctx,
        name = "linuxarm32",
        shared_sha256 = "69dcda97294d51b86db60505de61fb99dd905e92dd5995584d1c62a027d6e652",
        static_sha256 = "c9ce67ba109b0cbf5b1c4bbe6aca15b831dc4232b8f71c94895cd0118e08eed9",
    )
    __static_shared_pair(
        mctx,
        name = "linuxarm32debug",
        shared_sha256 = "7833a7ec3acd1e2b9045a3ebd1cbd1d6ab85fe54ef4868c818c0b71b2133fa67",
        static_sha256 = "f5185acc7b863c80f6dc9eeeb1fee02200211f8d0e68823b28569d01b509dd8a",
    )
    __static_shared_pair(
        mctx,
        name = "linuxarm64",
        shared_sha256 = "be814284499e70c94c11934f2ab6ce2f90714f76031d3384957f071cec7f30bc",
        static_sha256 = "f4fe718c0a8f378440ddc7e51dc9353d303c2298985ba7c77f6a838f91b9bd63",
    )
    __static_shared_pair(
        mctx,
        name = "linuxarm64debug",
        shared_sha256 = "60138eb357fc269277c80156853bcd9db08bac7915a0b7051a4a3277c8391f29",
        static_sha256 = "83dc4aeeb4953ad4adab82ab23b94d4beb69f6ddfc93f0e38cb171fffe28ae9e",
    )
    __static_shared_pair(
        mctx,
        name = "linuxx86-64",
        shared_sha256 = "f2d9b51c752bbef26cf613d999054fca2f38e622fa503d32d42c4a6895092c43",
        static_sha256 = "1338d8a0b610cd5a922dc2384be73755345791bf5e6319210f468369d6d80246",
    )
    __static_shared_pair(
        mctx,
        name = "linuxx86-64debug",
        shared_sha256 = "35c88d5db2c9cc343e44ccaf3524068b328c7d0ea90df5351c39f1f881d8e40b",
        static_sha256 = "6e0d47e3f4735dc2445bb241ff5e05b48b8110338c54169b5126a23b99b570c1",
    )
    __static_shared_pair(
        mctx,
        name = "osxarm64",
        shared_sha256 = "8994e3281f028e21d837a362b1e23f258b68cc9b0ced1fe1410d3431ba87a0a9",
        static_sha256 = "b99fe8e498685ba88310ef32f497d582195018233f18f2f3842e48f5edeec84b",
    )
    __static_shared_pair(
        mctx,
        name = "osxarm64debug",
        shared_sha256 = "07e8d358f857d64f0c9306a24098bb77f1526a18988230d2e8ef9f881a401928",
        static_sha256 = "e8739f77519cddcbca8f25fd6437fb196d9fe1edcd63fa3357e62e1880fd089b",
    )
    __static_shared_pair(
        mctx,
        name = "osxuniversal",
        shared_sha256 = "ef8c557a912e28a048ea5a601b6e2494fb855ce4cc628f5630bf82defbd00a61",
        static_sha256 = "eeca3f28ce3b840c8f91ec7ea9f14d8b8d61e21a94cc1b26f693230c26603d05",
    )
    __static_shared_pair(
        mctx,
        name = "osxuniversaldebug",
        shared_sha256 = "3fa16c3e1ec2e5e2812cb415c92d649d466b065ed5a0f06352bf40ab32389d69",
        static_sha256 = "5f0bc46c5c959f2ea584a96955906f183283d911b9f7532749d4e9cab8ad8b0e",
    )
    __static_shared_pair(
        mctx,
        name = "osxx86-64",
        shared_sha256 = "4aaef18a3074c2db17721844c205df13d27f015e204514216c436adfcd6290dc",
        static_sha256 = "53c01641c2106b802a4cce85ff12f80c4cf4eaecdfeb0b26a3e15b44c61cb34d",
    )
    __static_shared_pair(
        mctx,
        name = "osxx86-64debug",
        shared_sha256 = "9e9a695d428b2ede69faf801b0152c23256384b543ff8768300f97298caa960a",
        static_sha256 = "6ebd2d2fa123085ac261b539df9c6fd01536660ca21fdebfa60f3eedd7d78359",
    )
    __static_shared_pair(
        mctx,
        name = "windowsx86-64",
        shared_sha256 = "c230df0a5c26ce77a02638e2f1902d459830e33c1e0b99c3b505135b2687ddf4",
        static_sha256 = "22cb69efc521b51d71d018e11a71a8f8e560b750710ac45a6764930dc9a008d9",
    )
    __static_shared_pair(
        mctx,
        name = "windowsx86-64debug",
        shared_sha256 = "ef670782658e7d5b9c50235197c7bf4fa650a9c4125b67a92fd4cdb7c6f77c0a",
        static_sha256 = "26d8e9752a4ceffcc75c32f386eb3f5dd1f104edf9424c5a28497c862aacc3d2",
    )
    __static_shared_pair(
        mctx,
        name = "windowsx86",
        shared_sha256 = "fd55ef0eaa59b0b715a18bf48db073131b75f92eaac14840a64d263181949bab",
        static_sha256 = "4133f7e2458c9dc1a7771be8231a348073a8f556ab5475dc091b0566c0be7b6b",
    )
    __static_shared_pair(
        mctx,
        name = "windowsx86debug",
        shared_sha256 = "df7a44756f97417a24fa2a85b0d801a40864b679d26f45fa12b5c6edd2f88c12",
        static_sha256 = "53d760be3957824b452c10b1756ce6ce6718cc5f48bfc96beb869d7750b762f0",
    )
    __static_shared_pair(
        mctx,
        name = "windowsarm64",
        shared_sha256 = "80aa7f94ccddaf0d92190ce3072f411c39d8ceb6555dfb8a1ecaedc65892b2c2",
        static_sha256 = "1112aac5e9cedde35d1e3ee90d1444ee55db0c68542e1e8d748c1b6ac6e26f40",
    )
    __static_shared_pair(
        mctx,
        name = "windowsarm64debug",
        shared_sha256 = "ed86da931fcc66ec21e7d6d4f97a9e3e4dc7264d8929702c68145e984c013791",
        static_sha256 = "e876349009c07649335c81bba178baea63704fb47e3128f0049ca28dc8d6d8ac",
    )
    # END static shared pairs

def setup_legacy_bzlmodrio_opencv_cpp_dependencies():
    __setup_bzlmodrio_opencv_cpp_dependencies(None)

setup_bzlmodrio_opencv_cpp_dependencies = module_extension(
    __setup_bzlmodrio_opencv_cpp_dependencies,
)
