# Renode issue reproduction template

This repository is meant to help report issues in (and provide contributions to) the open source [Renode simulation framework](https://renode.io).

It has a GitHub Actions CI set up for you so that you only need to provide the minimum amount of data which reproduces the issue (= makes the CI fail).

Fork this repo and [adapt the template to build a test case which shows the failure](#usage-to-report-bugs), and if you have an idea how to [provide a fix](#providing-fixes), implement it in this repo to showcase the desired solution and outcome, all nicely automated.

## Important files in this repo

* `.github/workflows` - the GH Actions plumbing; touch it only if you want to make some fundamental changes 
* `artifacts` - any files you want the CI to store for demonstration (e.g. logs) should end up here during the CI job
* `build.sh` - a stub of a potential build script for your [test software](providing-test-software)
* `requirements.txt` - add any Python requirements here, if needed
* `test.resc` - Renode script file, you will most likely be changing this one
* `test.robot` - Robot test file, most likely also requiring adaptations

## Usage to report bugs

Adapt the `.resc` and `.robot` files until you get the CI to fail (with the dreaded red cross showing up) in a way that you know should not happen, e.g. the simulated binary should be printing something to UART but apparently doesn't.

Report an issue in https://github.com/renode/renode and link to your clone, with any additional explanations needed.

Files in the `artifacts/` directory will automatically be saved as build artifacts so if you want to share e.g. logs, make sure they end up there after the CI executes.

## Providing fixes

Sometimes you may already know what the fix should be - this repository is an easy way to get your fix included in mainline Renode!

To do that, implement changes in this repo which make the previously failing CI green again. One way to do that may involve providing standalone `.cs` files with the fixed model code and loading them in runtime to override the original implementations.

If you report an issue with such a fix already in place using this repository - we can then easily verify this on our end and help you prepare a PR.

### Overriding existing or adding new peripheral models in runtime

Loading new `.cs` files in runtime is as easy as executing `include @my_file.cs` in the `.resc` script or `ExecuteCommand    include @my_file.cs` in the `.robot` file. Please note that names of the dynamically added classes should not overlap with existing ones, so if you e.g., fix the `ABC_UART` class that is referenced in the `abc.repl` platform you should create the `ABC_UART_Fixed` class and update the `.repl` file to reference `ABC_UART_Fixed` instead of the original `ABC_UART`.

It might happen that during the dynamic compilation you see compilation errors about unknown types. In such case you should use the `EnsureTypeIsLoaded` command. See the example below for details.

```
# in case your implementation references types available in Renode 
# but not recognized by the dynamic compiler use the `EnsureTypeIsLoaded` command;
# this step is only needed if you encounter unreferenced types errors during execution of the `include` command
EnsureTypeIsLoaded "Antmicro.Renode.NameOfTheUnknownType"

# load your fixed implementation of the model
include @ABC_UART_Fixed.cs

# make sure that abc.repl references the ABC_UART_Fixed class instead of ABC_UART
mach create
machine LoadPlatformDescription @abc.repl

[...]
```

## Providing test software

If you can reproduce your problem with one of our demo binaries hosted at dl.antmicro.com or in the [Zephyr Dashboard](https://zephyr-dashboard.renode.io/), feel free to use that.

If you need your specific software to replicate the issue, please try to create the minimum failing binary (preferably in ELF form; for formats without debug symbols, remember to set the Program Counter after loading them).

You can just commit your binary into the repository and use it in the `.resc` script, especially in situations when due to confidentiality you can only share the binary.

If you can share the sources, please include them e.g. in a `src/` directory - and if you have the time to do so, also adapt `build.sh` to build it.
Otherwise you can just commit a binary you compiled yourself corresponding to the sources.

If you can't share your binary or a minimal test case based on it, you can always adapt the CI to pull it from some secret storage with authentication, but that of course may need more work.
