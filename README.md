# rules_pangolin

Bazel (bzlmod) support for [Pangolin](https://github.com/stevenlovegrove/Pangolin),
the lightweight portable rapid development library for OpenGL display,
interaction and abstracting video input.

Pangolin v0.9.3 is fetched with `git_repository` through a module extension
(pinned to a commit), overlaid with a Bazel BUILD file that mirrors the
upstream per-component CMake target graph. Only the C++ libraries are built:
`pango_python` and all language bindings are intentionally excluded.

## Usage

```starlark
# MODULE.bazel
bazel_dep(name = "rules_pangolin", version = "0.1.0")

pangolin = use_extension("@rules_pangolin//pangolin:extensions.bzl", "pangolin_extension")
pangolin.install()
use_repo(pangolin, "pangolin")
```

```starlark
# BUILD.bazel
cc_binary(
    name = "app",
    srcs = ["main.cc"],
    deps = ["@pangolin//:pangolin"],
)
```

The umbrella target `@pangolin//:pangolin` provides everything reachable
from `#include <pangolin/pangolin.h>`. Individual components are available
too: `pango_core`, `pango_vars`, `pango_image`, `pango_packetstream`,
`pango_opengl`, `pango_windowing`, `pango_display`, `pango_geometry`,
`pango_glgeometry`, `pango_scene`, `pango_plot`, `pango_video`,
`pango_tools`, `tinyobj`.

Consumers must compile as C++17 (upstream `CMAKE_CXX_STANDARD 17`).

## Requirements

- Bazel 8.x via [bazelisk](https://github.com/bazelbuild/bazelisk)
  (`.bazelversion` pins 8.8.0).
- Windows: MSVC (Visual Studio 2022; `GL/gl.h` and `opengl32` come from the
  Windows SDK), plus `git.exe` on `PATH` for the source fetch.
- Linux: gcc/clang and the X11/EGL/GL **runtime** libraries only
  (`libX11.so.6`, `libEGL.so.1`, `libGL.so.1` - present out of the box on
  WSL Ubuntu). No `-dev` packages are needed: GL/EGL/X11 headers are fetched
  hermetically (see below) and libraries are linked directly by soname.

## Design notes

- **Source of truth** - `pangolin/repositories.bzl` pins every upstream
  commit. The `install` tag accepts `remote`/`commit` overrides for the
  Pangolin repository itself.
- **Hermetic headers** - Eigen 3.4.0, the X11 headers (libx11 + xorgproto),
  the legacy GL headers (libglvnd) and the EGL headers (EGL-Registry) are
  fetched as git repositories. GLEW 2.2.0 is built from source.
- **GLEW everywhere** - upstream CMake uses libepoxy on Linux, which has no
  Bazel-friendly source distribution; `rules_pangolin` uses GLEW on every
  platform instead (the `HAVE_GLEW` code path is upstream-supported).
- **CMake codegen replaced** - the upstream `EmbedBinaryFiles.cmake`,
  `EmbedShaderFiles.cmake` (fonts.cpp / shaders.cpp) and
  `PangolinFactory.cmake` (`RegisterFactories*.h`) steps are reproduced by
  the `gen_embed` host tool (tools/gen_embed.cc) driven by the Starlark
  rules in tools/embed.bzl. No shell or Python is involved, so it works
  without MSYS on Windows.
- **Optional backends off** - image codecs (png/jpeg/tiff/openexr/lz4/zstd)
  and optional video drivers (ffmpeg, realsense, openni, v4l, ...) are
  disabled, matching a CMake build where none of those packages are found.
  All `HAVE_*` guards in the sources honour this.
- **Overlay edits re-fetched automatically** - overlay BUILD contents are
  read by the extension and passed as `build_file_content` (not
  `build_file` labels), so editing an overlay changes the repository cache
  key; no manual `bazel clean` is needed.

## Test

`test/` is a standalone consumer workspace:

```
cd test
bazelisk test //...
```

- `pangolin_core_test` links only pango_core/pango_vars/pango_image and
  exercises URI parsing, `Var` and `ManagedImage` at runtime.
- `pangolin_smoke_test` includes `<pangolin/pangolin.h>`, links the full
  library (display/opengl/windowing/video/plot/tools) and runs
  graphics-free assertions, so it passes headless (WSL without an X server).

Verified on Windows 11 (MSVC 14.44) and WSL2 Ubuntu 24.04 (gcc 13.3,
sandboxed actions).

## Fetching behind a proxy (e.g. from mainland China)

The Bazel server JVM and the `git` subprocesses it spawns honour different
settings. If direct access to github/gitlab is blocked, pass both:

```
bazelisk --host_jvm_args=-Dhttps.proxyHost=HOST --host_jvm_args=-Dhttps.proxyPort=PORT \
         --host_jvm_args=-Dhttp.proxyHost=HOST  --host_jvm_args=-Dhttp.proxyPort=PORT \
         shutdown  # restart the server with the proxy
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=http.proxy GIT_CONFIG_VALUE_0=http://HOST:PORT
bazelisk test //...
```
