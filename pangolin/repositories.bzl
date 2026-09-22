"""Git repositories pinned by rules_pangolin.

All third-party source is fetched with git_repository at a pinned commit
(GLEW comes from its release tarball because the git repository does not
carry the generated include/GL headers):

  - pangolin: the library itself (upstream CMake project, overlaid with a
    Bazel BUILD file).
  - eigen3:   header-only linear algebra, required by pango_image /
              pango_opengl / pango_geometry.
  - glew:     OpenGL loader, built from source on every OS (upstream CMake
              uses libepoxy on Linux, which has no Bazel-friendly source
              distribution; the HAVE_GLEW code path is upstream-supported).

  - libx11 / xorgproto: X11 headers (no system X11 development packages
    needed).
  - gl_registry / egl_registry: Khronos GL and EGL headers.
  - pangolin_tools: build-time code generator (font/shader embedding and
    factory registry headers) that replaces Pangolin's CMake macros.

The X11/GL/EGL *runtime* libraries are expected from the system (WSL ships
libX11.so.6 / libEGL.so.1 / libGL.so.1 in the default linker path); they are
linked directly by soname, so no -dev packages are required.
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")
load("//tools:tools_repository.bzl", "pangolin_tools_repository")

# https://github.com/stevenlovegrove/Pangolin/releases/tag/v0.9.3
PANGOLIN_COMMIT = "73967b39ad2cf84245cf877ce0879dc0909d3be4"
PANGOLIN_REMOTE = "https://github.com/stevenlovegrove/Pangolin"
PANGOLIN_SHALLOW_SINCE = "2023-01-01"

# https://gitlab.com/libeigen/eigen/-/tags/3.4.0
EIGEN_COMMIT = "3147391d946bb4b6c68edd901f2add6ac1f31f8c"
EIGEN_REMOTE = "https://gitlab.com/libeigen/eigen.git"
EIGEN_SHALLOW_SINCE = "2021-01-01"

# https://github.com/nigels-com/glew/releases/tag/glew-2.2.0
# The git repository does not carry the generated include/GL headers, so the
# official release tarball is used instead.
GLEW_SHA256 = "d4fc82893cfb00109578d0a1a2337fb8ca335b3ceccf97b97e5cc7f08e4353e1"
GLEW_URL = "https://github.com/nigels-com/glew/releases/download/glew-2.2.0/glew-2.2.0.tgz"

# https://gitlab.freedesktop.org/xorg/lib/libx11 (include/X11: Xlib.h,
# Xutil.h, ...)
LIBX11_COMMIT = "13f9b8de400335f4b86bb0672da02f8166c0e796"
LIBX11_REMOTE = "https://gitlab.freedesktop.org/xorg/lib/libx11.git"

# https://gitlab.freedesktop.org/xorg/proto/xorgproto (include/X11: X.h,
# Xfuncproto.h, Xosdefs.h, keysym.h, extensions/, ...)
XORGPROTO_COMMIT = "ee7bb05bf46cda290a213eeffb407c4b0f1c94cf"  # xorgproto-2025.1
XORGPROTO_REMOTE = "https://gitlab.freedesktop.org/xorg/proto/xorgproto.git"

# https://github.com/NVIDIA/libglvnd (include/GL: gl.h, glx.h, glext.h, ...
# - the "system" GL headers; glplatform.h unconditionally includes GL/gl.h
# on non-GLES platforms, and on Windows this comes from the Windows SDK)
GLVND_COMMIT = "606f6627cf481ee6dcb32387edc010c502cdf38b"
GLVND_REMOTE = "https://github.com/NVIDIA/libglvnd.git"

# https://github.com/KhronosGroup/EGL-Registry (api/EGL: egl.h, ...)
EGL_REGISTRY_COMMIT = "db3425b8246136faccb5e2782b5694960bd6edf1"
EGL_REGISTRY_REMOTE = "https://github.com/KhronosGroup/EGL-Registry.git"

def pangolin_repositories(
        name = "pangolin",
        remote = PANGOLIN_REMOTE,
        commit = PANGOLIN_COMMIT,
        shallow_since = PANGOLIN_SHALLOW_SINCE,
        overlays = None):
    """Creates the @pangolin source repository and its pinned dependencies.

    The generated repositories reference each other by their plain names
    (eigen3, glew, pangolin_tools), so these names are fixed; only the
    pangolin repository itself accepts a source override.

    Overlay BUILD contents (rather than build_file labels) are passed in so
    that editing an overlay file changes the repository cache key and
    triggers an automatic refetch.

    Args:
        name: name for the pangolin repository.
        remote: git remote of Pangolin.
        commit: pinned commit of Pangolin.
        shallow_since: date hint enabling a shallow git fetch.
        overlays: map of repository name -> overlay BUILD file content.
    """
    overlays = overlays or {}
    pangolin_tools_repository(name = "pangolin_tools")

    git_repository(
        name = "eigen3",
        remote = EIGEN_REMOTE,
        commit = EIGEN_COMMIT,
        shallow_since = EIGEN_SHALLOW_SINCE,
        init_submodules = False,
        build_file_content = overlays["eigen3"],
    )

    http_archive(
        name = "glew",
        url = GLEW_URL,
        sha256 = GLEW_SHA256,
        strip_prefix = "glew-2.2.0",
        build_file_content = overlays["glew"],
    )

    git_repository(
        name = "libx11",
        remote = LIBX11_REMOTE,
        commit = LIBX11_COMMIT,
        shallow_since = "2025-01-01",
        init_submodules = False,
        build_file_content = overlays["libx11"],
    )

    git_repository(
        name = "xorgproto",
        remote = XORGPROTO_REMOTE,
        commit = XORGPROTO_COMMIT,
        shallow_since = "2024-01-01",
        init_submodules = False,
        build_file_content = overlays["xorgproto"],
    )

    git_repository(
        name = "glvnd",
        remote = GLVND_REMOTE,
        commit = GLVND_COMMIT,
        shallow_since = "2023-01-01",
        init_submodules = False,
        build_file_content = overlays["glvnd"],
    )

    git_repository(
        name = "egl_registry",
        remote = EGL_REGISTRY_REMOTE,
        commit = EGL_REGISTRY_COMMIT,
        shallow_since = "2022-01-01",
        init_submodules = False,
        build_file_content = overlays["egl_registry"],
    )

    git_repository(
        name = name,
        remote = remote,
        commit = commit,
        shallow_since = shallow_since,
        init_submodules = False,
        build_file_content = overlays["pangolin"],
    )
