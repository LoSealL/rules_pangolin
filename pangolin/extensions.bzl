"""Entry point for the bzlmod extension exposed by rules_pangolin.

Usage in a consuming MODULE.bazel:

    bazel_dep(name = "rules_pangolin", version = "0.1.0")

    pangolin = use_extension("@rules_pangolin//pangolin:extensions.bzl", "pangolin_extension")
    pangolin.install()
    use_repo(pangolin, "pangolin")

Then depend on "@pangolin//:pangolin" (umbrella) or the individual
component targets such as "@pangolin//:pango_core".
"""

load("//pangolin:repositories.bzl", "pangolin_repositories")

_pangolin_install_tag = tag_class(attrs = {
    "commit": attr.string(doc = "Pangolin commit to fetch (defaults to the pinned v0.9.3 release)"),
    "remote": attr.string(doc = "Pangolin git remote to fetch from"),
})

# Overlay BUILD files, read at extension-evaluation time and passed as
# build_file_content so that editing an overlay invalidates the repository
# cache key automatically (a build_file *label* would not).
_OVERLAY_REPOS = {
    "eigen3": "build_eigen.bazel",
    "glew": "build_glew.bazel",
    "libx11": "build_libx11.bazel",
    "xorgproto": "build_xorgproto.bazel",
    "glvnd": "build_glvnd.bazel",
    "egl_registry": "build_eglregistry.bazel",
    "pangolin": "build_pangolin.bazel",
}

def _read_overlays(module_ctx):
    overlays = {}
    for repo, file in _OVERLAY_REPOS.items():
        overlays[repo] = module_ctx.read(Label("//pangolin:" + file))
    return overlays

def _find_modules(module_ctx):
    root = None
    our_module = None
    for mod in module_ctx.modules:
        if mod.is_root:
            root = mod
        if mod.name == "rules_pangolin":
            our_module = mod
    if root == None:
        root = our_module
    if root == None:
        fail("Unable to find rules_pangolin module")
    return root, our_module

def _impl(module_ctx):
    # Repository configuration is only allowed in the root module, or in
    # rules_pangolin itself (same policy as rules_tensorrt / rules_sycl).
    root, rules_pangolin = _find_modules(module_ctx)
    installs = root.tags.install if root.tags.install else rules_pangolin.tags.install

    overrides = {}
    for install in installs:
        for key in ("remote", "commit"):
            value = getattr(install, key)
            if value:
                overrides[key] = value

    pangolin_repositories(overlays = _read_overlays(module_ctx), **overrides)

pangolin_extension = module_extension(
    implementation = _impl,
    tag_classes = {
        "install": _pangolin_install_tag,
    },
)
