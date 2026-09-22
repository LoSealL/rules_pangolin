"""Starlark rules wrapping the gen_embed code generator (tools/gen_embed.cc).

These replace Pangolin's CMake code generation so the unmodified upstream
sources compile under Bazel:

  embed_binary_files      -> cmake/EmbedBinaryFiles.cmake  (fonts.cpp)
  embed_shader_files      -> cmake/EmbedShaderFiles.cmake  (shaders.cpp)
  factory_registry_header -> cmake/PangolinFactory.cmake   (RegisterFactories*.h)

The generator is passed explicitly (default @pangolin_tools//:gen_embed)
because attr defaults resolve in the instantiating repository.
"""

def _run_gen(ctx, out, arguments, inputs):
    ctx.actions.run(
        executable = ctx.executable.tool,
        arguments = arguments,
        inputs = inputs,
        outputs = [out],
        mnemonic = "GenEmbed",
        progress_message = "GenEmbed %s" % out.short_path,
    )
    return [DefaultInfo(files = depset([out]))]

def _embed_binary_impl(ctx):
    out = ctx.actions.declare_file(ctx.attr.out)
    arguments = [
        "--mode=binary",
        "-o",
        out.path,
    ] + [f.path for f in ctx.files.srcs]
    return _run_gen(ctx, out, arguments, ctx.files.srcs)

def _embed_shader_impl(ctx):
    out = ctx.actions.declare_file(ctx.attr.out)
    arguments = [
        "--mode=shader",
        "-o",
        out.path,
        "--prefix=" + ctx.attr.prefix,
    ] + [f.path for f in ctx.files.srcs]
    return _run_gen(ctx, out, arguments, ctx.files.srcs)

def _factory_registry_impl(ctx):
    out = ctx.actions.declare_file(ctx.attr.out)
    arguments = [
        "--mode=factory",
        "-o",
        out.path,
        "--interface=" + ctx.attr.interface,
    ] + ["--factory=" + f for f in ctx.attr.factories]
    return _run_gen(ctx, out, arguments, [])

embed_binary_files = rule(
    implementation = _embed_binary_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True, mandatory = True),
        "out": attr.string(mandatory = True),
        "tool": attr.label(
            default = "@pangolin_tools//:gen_embed",
            executable = True,
            cfg = "exec",
        ),
    },
)

embed_shader_files = rule(
    implementation = _embed_shader_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True, mandatory = True),
        "out": attr.string(mandatory = True),
        "prefix": attr.string(mandatory = True),
        "tool": attr.label(
            default = "@pangolin_tools//:gen_embed",
            executable = True,
            cfg = "exec",
        ),
    },
)

factory_registry_header = rule(
    implementation = _factory_registry_impl,
    attrs = {
        "interface": attr.string(mandatory = True),
        "factories": attr.string_list(mandatory = True),
        "out": attr.string(mandatory = True),
        "tool": attr.label(
            default = "@pangolin_tools//:gen_embed",
            executable = True,
            cfg = "exec",
        ),
    },
)
