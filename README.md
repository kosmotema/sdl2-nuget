# SDL2-nuget_builder

PowerShell script to generate NuGet packages for SDL2.

### You can download pre-generated packages [here](https://github.com/xapdkop/sdl2-nuget) (look in [releases](https://github.com/xapdkop/sdl2-nuget/releases))

## Prerequisite

To generate packages you need:
- The CoApp tools: [Official website](http://coapp.org) | [Download page](http://coapp.org/pages/releases.html)
- Internet connection

## How to

You just have to run the sdl2-nuget.ps1 script in a PowerShell instance.
It will download each needed files and output nupkg files in the "repository" folder.
Also you can customize script if you want.

## Customization

You can customize packages by changing this params:
- `$pkg_prefix` to change packages prefix, **""** by default [empty quotes, means no prefix]
- `$pkg_postfix` to change packages postfix, **""** by default [empty quotes, means no postfix]
- `$keep_sources` to keep or delete source files, **true** by default
- `$keep_autopkg` to keep or delete autopkg files, **false** by default
- `$add_docs` to add the SDL2's documentation, **false** by default
- `$pkg_hotfix` to set hotfix version of generated packages, **""** by default [empty quotes, means no hotfix]
- `$sdl2_owners` to change packages owner(s)
- `$sdl2_tags` to customize tags
- `$sdl2_module_list` to choose modules you need
- `$sdl2_version` to choose packages versions
- `$sdl2_platforms` - for advanced users

### You should know what you are changing!!!