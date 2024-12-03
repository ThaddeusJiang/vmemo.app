# surface init log

```sh
mix surface.init
==> sourceror
Compiling 11 files (.ex)
Generated sourceror app
==> surface
Compiling 108 files (.ex)
Generated surface app
==> vmemo
Generated vmemo app

Note: This task will change existing files in your project.

Make sure you commit your work before running it, especially if this is not a fresh phoenix project.

Do you want to continue? [Yn]
* patching .formatter.exs
* patching .gitignore
* patching Dockerfile (skipped)
* patching assets/css/app.css
* patching assets/js/app.js (skipped)
* patching assets/tailwind.config.js
* patching config/dev.exs
* patching lib/vmemo_web.ex
* patching mix.exs

Finished running 14 patches for 9 files.
2 messages emitted.
12 changes applied, 2 skipped.

                                        Message #1

Patch "Configure components' JS hooks" was not applied to assets/js/app.js.

Reason: unexpected file content.

Either the original file has changed or it has been modified by the user and it's no
longer safe to automatically patch it.

If you believe you still need to apply this patch, you must do it manually with the
following instructions:

Import Surface components' hooks and pass them to new LiveSocket(...).

# Example

    import Hooks from "./_hooks"

    let liveSocket = new LiveSocket("/live", Socket, { hooks: Hooks, ... })



```
