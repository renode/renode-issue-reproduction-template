# Renode issue reproduction template

This repository is meant to help report issues in (and provide contributions to) the open source [Renode framework](https://renode.io).

It has CI set up for you so that you only need to provide the minimum amount of data which reproduces the issue (= makes the CI fail).

Use it as a template to create your own test case which shows the failure, and if you have an idea how to provide a fix, the desired outcome.

## Usage to report bugs

Adapt the `.resc` and `.robot` files until you get the CI to fail in a way that you know should not happen, e.g. the simulated binary should be printing something to UART but apparently doesn't.

Report an issue in https://github.com/renode/renode and link to your clone, with any additional explanations needed.

Files in the `artifacts/` directory will automatically be saved as build artifacts so if you want to share e.g. logs, make sure they end up there after the CI executes.

## Providing fixes

If you know what the fix should be, you can e.g. provide standalone `.cs` files with the fixed model code and load them in runtime over the original implementations, and make the CI green again, then report this as an issue - we can then verify and help you prepare a PR.

TODO: describe how to do this

## Tips re: software

If you can reproduce your problem with one of our demo binaries hosted at dl.antmicro.com or in the [Zephyr Dashboard](https://zephyr-dashboard.renode.io/), feel free to use that.

If you need your specific software to replicate the issue, please try to create the minimum failing binary (preferably in ELF form; for formats without debug symbols, remember to set the Program Counter after loading them).

You can just commit your binary into the repository and use it in the `.resc` script, especially in situations when due to confidentiality you can only share the binary.

If you can share the sources, please include them e.g. in a `src/` directory - and if you have the time to do so, also adapt `build.sh` to build it.
Otherwise you can just commit a binary you compiled yourself corresponding to the sources.

If you can't share your binary or a minimal test case based on it, you can always adapt the CI to pull it from some secret storage with authentification, but that of course may need more work.
