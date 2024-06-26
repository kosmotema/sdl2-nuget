# sdl2.nuget ![version](https://img.shields.io/github/v/tag/kosmotema/sdl2-nuget?label=version)

PowerShell script to generate NuGet packages for SDL2. And pre-generated ones.

> [!IMPORTANT]
> `sdl2.nuget` packages intented for use in C++ projects only and don't support C# projects!
> 
> In C++ projects, to use SDL2, install `sdl2.nuget` package and simply write `#include "SDL.h"` in your `.cpp` or `.h` file. Find out more usage tutorials on the [official SDL2 website](https://wiki.libsdl.org/SDL2/Tutorials)

> [!TIP]
> If you see that SDL2-nuget packages are outdated, please [create an issue](https://github.com/kosmotema/sdl2-nuget/issues/new)

### You can download pre-generated packages from [nuget.org](https://nuget.org) (or from [here](https://github.com/kosmotema/sdl2-nuget/releases/)):

- [sdl2.nuget](https://www.nuget.org/packages/sdl2.nuget/) ![sdl2.nuget version](https://img.shields.io/nuget/v/sdl2.nuget?label=)

- [sdl2_image.nuget](https://www.nuget.org/packages/sdl2_image.nuget/) ![sdl2_image.nuget version](https://img.shields.io/nuget/v/sdl2_image.nuget?label=)
- [sdl2_ttf.nuget](https://www.nuget.org/packages/sdl2_ttf.nuget/) ![sdl2_ttf.nuget version](https://img.shields.io/nuget/v/sdl2_ttf.nuget?label=)
- [sdl2_mixer.nuget](https://www.nuget.org/packages/sdl2_mixer.nuget/) ![sdl2_mixer.nuget version](https://img.shields.io/nuget/v/sdl2_mixer.nuget?label=)
- [sdl2_net.nuget](https://www.nuget.org/packages/sdl2_net.nuget/) ![sdl2_net.nuget version](https://img.shields.io/nuget/v/sdl2_net.nuget?label=)

## Prerequisites for generating your own packages

To generate packages you need the CoApp tools: [Official website](http://coapp.org) | [Download page](http://coapp.org/pages/releases.html)

## How to generate

You just have to run the sdl2-nuget.ps1 script in a PowerShell instance.
It will download each needed files and output `.nupkg` files in the "repository" folder.
Also you can customize script if you want.

## Script command line parameters

### Packages

You can use parameters to generate only specific packages (with specific versions).

To generate a package of specific version, use following syntax: `-package:version` (e.g. `-sdl2:2.28.1`). You can use `latest` as the version to generate a package of the latest version available on GitHub releases.

For example, to generate SDL2 package of version 2.28.1 and SDL2_image of the latest version, run:

```
./sdl2-nuget.ps1 -sdl2:2.28.1 -sdl2_image:latest
```

List of available parameters:

- `sdl2`
- `sdl2_image`
- `sdl2_mixer`
- `sdl2_ttf`
- `sdl2_net`

**Note:** You can specify hotfix for a package (e.g. `-sdl2:2.28.1.1`), that will be used only for a NuGet version of a package.

### Customization

You can customize packages or keep some intermediate files by settings this params when executing the script:

- `-PackagesPrefix` to change packages prefix, **""** by default [empty quotes, means no prefix]
- `-PackagesPostfix` to change packages postfix, **".nuget"** by default [empty quotes, means no postfix]
- `-AddDocs` to add the SDL2's documentation, **false** by default
- `-KeepSources` to keep or delete unpacked source files inside the temporary `sources` folder, **false** by default
- `-KeepAutoPkg` to keep or delete `.autopkg` files inside the temporary `build` directory, **false** by default
- `-ClearOutDir` to delete everything in the `repository` folder before building packages, **false** by default

## Script variables

Also, there are some hidden variables you can change in the script:

- `$sdl2_owners` to change packages owner(s)
- `$sdl2_tags` to customize tags
- `$sdl2_module_list` to choose modules you need
- `$sdl2_default_versions` to choose packages default versions (used when passed `default` as value of command line parameter)
- `$sdl2_platforms` - for advanced users

## SDL2 links:

- [Official website](https://www.libsdl.org)
- [SDL Git](https://github.com/orgs/libsdl-org)
