# SDL2-nuget

PowerShell script to generate NuGet packages for SDL2. And pre-generated ones.

## **Disclaimer! All packages are provided "AS IS"**

#### If you see that SDL2-nuget packages are outdated, create an issue or send me an email on [sdl2-nuget@xapdkop.space](mailto:sdl2-nuget@xapdkop.space)

### You can download pre-generated packages from [here](https://github.com/xapdkop/sdl2-nuget/releases/) or from [nuget.org](https://nuget.org) (rather):

- [sdl2.nuget](https://www.nuget.org/packages/sdl2.nuget/)
- [sdl2_image.nuget](https://www.nuget.org/packages/sdl2_image.nuget/)
- [sdl2_ttf.nuget](https://www.nuget.org/packages/sdl2_ttf.nuget/)
- [sdl2_mixer.nuget](https://www.nuget.org/packages/sdl2_mixer.nuget/)
- [sdl2_net.nuget](https://www.nuget.org/packages/sdl2_net.nuget/)

#### The packages source code is availbale in the [nuget/source](https://github.com/xapdkop/sdl2-nuget/tree/nuget/source) branch.

## Versions of SDL2 by default:

- SDL2 - **2.0.12**
- SDL2_image - **2.0.5**
- SDL2_ttf - **2.0.15**
- SDL2_mixer - **2.0.4**
- SDL2_net - **2.0.1**

## Prerequisites for generating your own packages

To generate packages you need:
- The CoApp tools: [Official website](http://coapp.org) | [Download page](http://coapp.org/pages/releases.html)
- Internet connection

## How to generate

You just have to run the sdl2-nuget.ps1 script in a PowerShell instance.
It will download each needed files and output nupkg files in the "repository" folder.
Also you can customize script if you want.

## Packages customization

You can customize packages by changing this params **(you should know what you are changing!!!)**:
- `$pkg_prefix` to change packages prefix, **""** by default [empty quotes, means no prefix]
- `$pkg_postfix` to change packages postfix, **""** by default [empty quotes, means no postfix]
- `$keep_sources` to keep or delete source files, **true** by default
- `$keep_autopkg` to keep or delete autopkg files, **false** by default
- `$add_docs` to add the SDL2's documentation, **false** by default
- `$pkg_hotfix` to set hotfix versions of generated packages, **""** by default for each package [empty quotes, means no hotfix]
- `$sdl2_owners` to change packages owner(s)
- `$sdl2_tags` to customize tags
- `$sdl2_module_list` to choose modules you need
- `$sdl2_version` to choose packages versions
- `$sdl2_platforms` - for advanced users

## SDL2 links:

- [Official website](https://www.libsdl.org)
- [SDL Mercurial repository](http://hg.libsdl.org/SDL)
- [SDL Bugzilla issue tracker](https://bugzilla.libsdl.org)