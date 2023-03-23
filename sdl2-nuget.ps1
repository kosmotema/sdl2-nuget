#
# sdl2-nuget.ps1
#

#########################

param([string] $sdl2, [string] $sdl2_image, [string] $sdl2_ttf, [string] $sdl2_mixer, [string] $sdl2_net,
    [string] $PackagesPrefix = "", [string] $PackagesPostfix = ".nuget", [switch] $KeepSources = $false,
    [switch] $KeepAutoPkg = $false, [switch] $AddDocs = $false)

$version = "2.3.0"

Write-Host -ForegroundColor Blue "sdl2-nuget v$version"

#########################

# SDL2 packages variables
$sdl2_owners =	"xapdkop" # Packages "owner" name. Replace username with your name
$sdl2_tags = "C++ SDL2 SDL Audio Graphics Keyboard Mouse Joystick Multi-Platform OpenGL Direct3D" # Tags for your packages, "SDL2, native, CoApp" by default

$sdl2_default_versions = @{ "sdl2" = "2.26.3"; "sdl2_image" = "2.6.3"; "sdl2_ttf" = "2.20.2"; "sdl2_mixer" = "2.6.3"; "sdl2_net" = "2.2.0" } 

$sdl2_platforms = "x86", "x64"

#########################

# It's not recommended to change these values
$sdl2_authors = "Sam Lantinga and SDL contributors"
$sdl2_licence_url = "https://www.libsdl.org/license.php"
$sdl2_project_url = "https://www.libsdl.org"
$sdl2_icon_url = "https://www.libsdl.org/media/SDL_logo.png"
$sdl2_require_license_acceptance = "false"
$sdl2_summary = "Simple DirectMedia Layer is a cross-platform development library designed to provide low level access to audio, keyboard, mouse, joystick, and graphics hardware via OpenGL and Direct3D."
$sdl2_description = "Simple DirectMedia Layer is a cross-platform development library designed to provide low level access to audio, keyboard, mouse, joystick, and graphics hardware via OpenGL and Direct3D. It is used by video playback software, emulators, and popular games including Valve's award winning catalog and many Humble Bundle games.

SDL officially supports Windows, Mac OS X, Linux, iOS, and Android. Support for other platforms may be found in the source code.

SDL is written in C, works natively with C++, and there are bindings available for several other languages, including C# and Python.

---

Is this package outdated? Report here: https://github.com/kosmotema/sdl2-nuget"

# Don't change these values
$dir = Split-Path -Path $MyInvocation.MyCommand.Path
$coapp_download_url = "http://coapp.org/pages/releases.html"
$sdl2_default_dependency = @(@{ "name" = "sdl2"; "version" = "2.0.0" })
$sdl2_dependencies = @{
    "sdl2_image" = $sdl2_default_dependency
    "sdl2_ttf"   = $sdl2_default_dependency
    "sdl2_mixer" = $sdl2_default_dependency
    "sdl2_net"   = $sdl2_default_dependency
}

#########################

$sdl2_packages = @{}

function SetPackageVersionFromParameter([string]$Name, [string]$Version) {
    if (-not ($Version)) {
        return
    }

    $v = $sdl2_packages[$Name] = if ($Version -ne "default") { $Version } else { $sdl2_default_versions[$Name] }

    # https://semver.org/spec/v2.0.0.html#is-there-a-suggested-regular-expression-regex-to-check-a-semver-string
    if (-not ($v -match '^2\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$')) {
        Write-Warning "Bad version of package `"${Name}`": $v"
        Exit
    }
}

SetPackageVersionFromParameter "sdl2" $sdl2
SetPackageVersionFromParameter "sdl2_image" $sdl2_image
SetPackageVersionFromParameter "sdl2_mixer" $sdl2_mixer
SetPackageVersionFromParameter "sdl2_ttf" $sdl2_ttf
SetPackageVersionFromParameter "sdl2_net" $sdl2_net

if ($sdl2_packages.count -eq 0) {
    $sdl2_packages = $sdl2_default_versions
}

#########################

function TrimVersion([string]$Version) {
    return $Version -replace '^(\d+)\.(\d+)\.(\d+).*$', '$1.$2.$3'
}

function RepoInfo([string]$Package) {
    $version = TrimVersion $sdl2_packages[$Package]
    $packagename = $Package.Replace("sdl", "SDL")
    $reponame = $packagename.Replace("SDL2", "SDL")
    $filename = "$packagename-devel-" + $version + "-VC.zip"

    return @{
        "version" = $version
        "repo"    = "libsdl-org/$reponame"
        "file"    = $filename
        "tag"     = "release-$version"
    }
}

function FetchChangelog([string]$Package) {
    $info = RepoInfo $Package
    $release = Invoke-WebRequest -Uri "https://api.github.com/repos/$($info["repo"])/releases/tags/$($info["tag"])" | ConvertFrom-Json

    return $release.body
}

function GetFullPackageName([string]$Package) {
    return "$PackagesPrefix$Package$PackagesPostfix"
}

function PackageHeader([string]$Package) {
    $currentYear = (Get-Date).Year
    $changelog = FetchChangelog $Package

    return "configurations {
    Platform {
        key : ""Platform"";
        choices : { Win32, x64 };
        Win32.aliases : { x86, win32, ia32, 386 };
        x64.aliases : { x64, amd64, em64t, intel64, x86-64, x86_64 };
    };
    Linkage {
        choices : { dynamic };
    };
};

nuget {
	nuspec {
		id = $(GetFullPackageName $Package);
		title: $(GetFullPackageName $Package);
		version: $($sdl2_packages[$Package]);
		authors: { $sdl2_authors };
		owners: { $sdl2_owners };
		licenseUrl: ""$sdl2_licence_url"";
		projectUrl: ""$sdl2_project_url"";
		iconUrl: ""$sdl2_icon_url"";
		requireLicenseAcceptance: $sdl2_require_license_acceptance;
		summary: ""$sdl2_summary"";
		description: @""$sdl2_description"";
		releaseNotes: @""$changelog"";
		copyright: Copyright $currentYear;
		tags: ""$sdl2_tags"";
	}

	#output-packages {
		default : `${pkgname};
		redist : `${pkgname}.redist;
		symbols : `${pkgname}.symbols;
	}"
}

function PackageLibs([string]$Package) {
    $datas = ""

    foreach ($plf in $sdl2_platforms) {
        $datas += "		[$plf] {"
        $libfile = "			lib: { `${SRC}$Package\lib\$plf\*.lib };"
        $binfile = "			bin: { `${SRC}$Package\bin\$plf\*.dll };"
        $datas += "
$libfile"

        $datas += "
$binfile"
        $datas += "
		}
"	
    }

    return $datas
}

function PackageDependencies([string]$Package) {
    if (-not $sdl2_dependencies.ContainsKey($Package)) {
        return ""
    }
    $datas += "

	dependencies {
		packages : {"
    foreach ($dp in $sdl2_dependencies[$Package]) {
        $datas += "
			$PackagesPrefix$($dp["name"])$PackagesPostfix/" + $dp["version"] + ","
    }
    $datas = $datas.TrimEnd(",")
    $datas += "
		};
	}"
    return $datas
}

function GeneratePackage([string]$Package) {

    $autopkg = PackageHeader($Package)
    $autopkg += PackageDependencies($Package)
    $autopkg += "

	files {
		#defines {
			SRC = ..\sources\;
		}

"
    $autopkg += "		include: {
			`${SRC}$Package\include\*.h
		};

"
    $autopkg += "		docs: {
			`${SRC}$Package\docs\**\*
		};

"
    $autopkg += PackageLibs($Package)
    $autopkg += "
	};

	targets {
		Defines += HAS_SDL2;
	}
}"
    $autopkg | Out-File "$(GetFullPackageName $Package).autopkg"
}

function NewDirectory([string]$Path, [switch]$ClearIfExists = $false) {
    if (-not (Test-Path $Path)) {
        New-Item $Path -ItemType Directory -Force | Out-Null
    }
    elseif ($ClearIfExists) {
        Get-ChildItem -Path $Path -Recurse | Remove-Item -Recurse | Out-Null
    }
}

#########################

# Checking on installed CoApp Tools
try {
    powershell.exe Show-CoAppToolsVersion | Out-Null

    if (-not $?) {
        throw;
    }
}
catch {
    Write-Warning "You need CoApp tools to build NuGet packages!"
    Read-Host "Press ENTER to open CoApp website or Ctrl-C to exit..."
    Start-Process $coapp_download_url
    Exit
}

NewDirectory "$dir\temp" -ClearIfExists
NewDirectory "$dir\sources"
NewDirectory "$dir\distfiles"
NewDirectory "$dir\build" -ClearIfExists

foreach ($pkg in $sdl2_packages.keys) {
    $info = RepoInfo $pkg

    $version = $info["version"]
    $filename = $info["file"]
    $outfile = "$dir\distfiles\$filename"

    if (-not (Test-Path $outfile)) {
        $fileuri = "https://github.com/$($info["repo"])/releases/download/$($info["tag"])/$filename"
        $downloaded = $false

        while ($downloaded -eq $false) {
            try {
                Write-Host "`nDownloading $filename from $fileuri ... " -NoNewLine
                Invoke-WebRequest -Uri $fileuri -OutFile $outfile
                $downloaded = $true
                Write-Host -ForegroundColor Green "OK"
            }
            catch {
                Write-Host -ForegroundColor Yellow "ERROR"
                Write-Host -ForegroundColor Yellow "Press ENTER to try again or Ctrl-C to exit..."
                Read-Host
            }
        }
    }

    Write-Host "`nExtracting $filename... " -NoNewLine

    try {
        Expand-Archive "$outfile" "$dir\temp\"
        Write-Host -ForegroundColor Green "OK"
    }
    catch {
        Write-Host -ForegroundColor Yellow "ERROR"
        Write-Warning "Cannot unzip package $filename"
        Write-Warning $_
        Remove-Item -Path "$outfile" -Force | Out-Null
        Pause
        Exit
    }

    $zip = "$dir\temp\" + $pkg.Replace("sdl", "SDL") + "-" + $version

    NewDirectory "$dir\sources\$pkg"

    foreach ($plf in $sdl2_platforms) {
        NewDirectory "$dir\sources\$pkg\lib\$plf"
        NewDirectory "$dir\sources\$pkg\bin\$plf"
    }

    NewDirectory "$dir\sources\$pkg\include"
    Move-Item -Path "$zip\include\*.h" -Destination "$dir\sources\$pkg\include\" -Force | Out-Null
    NewDirectory "$dir\sources\$pkg\docs"
    Move-Item -Path (Get-ChildItem "$zip\*.txt" -File) -Destination "$dir\sources\$pkg\docs\" -Force | Out-Null

    if ($AddDocs -ne $false) {
        if (Test-Path "$zip\docs\") {
            Copy-Item -Path "$zip\docs\*" -Destination "$dir\sources\$pkg\docs\" -Force | Out-Null
        }
    }

    foreach ($plf in $sdl2_platforms) {
        Move-Item -Path "$zip\lib\$plf\*.dll" -Destination "$dir\sources\$pkg\bin\$plf\" -Force | Out-Null
        Move-Item -Path "$zip\lib\$plf\*.lib" -Destination "$dir\sources\$pkg\lib\$plf\" -Force | Out-Null
    }

    Remove-Item -Path "$zip" -Recurse | Out-Null
}

# Workaround for outdated zlib1.dll in SDL_ttf <2.0.15
# if ($sdl2_packages["sdl2_ttf"] -and $(TrimVersion $sdl2_packages["sdl2_ttf"]) -lt "2.0.15") {
#     Copy-Item -Path "$dir\sources\sdl2_image\bin\x64\zlib1.dll" -Destination "$dir\sources\sdl2_ttf\bin\x64\zlib1.dll"
#     Copy-Item -Path "$dir\sources\sdl2_image\bin\x86\zlib1.dll" -Destination "$dir\sources\sdl2_ttf\bin\x86\zlib1.dll"
# }

Write-Host
Set-Location "$dir\build"

foreach ($module in $sdl2_packages.keys) {
    Write-Host "Generating $PackagesPrefix$module$PackagesPostfix.autopkg... " -NoNewline

    try {
        GeneratePackage $module
        Write-Host -ForegroundColor Green "OK"
    }
    catch {
        Write-Host -ForegroundColor Yellow "ERROR"
        Write-Warning "Cannot create .autopkg file"
        Write-Error $_
    }
}

Set-Location -Path ".."

NewDirectory "$dir\repository" -ClearIfExists
Set-Location "$dir\repository"

try {
    Get-ChildItem -Path "../build/" -Filter "$PackagesPrefix*$PackagesPostfix.autopkg" | Foreach-Object {
        Write-Host "`nGenerating NuGet package from $_...`n"

        powershell.exe Write-NuGetPackage $_

        if (-not $?) {
            throw;
        }

        if (-not ($KeepAutoPkg)) {
            Remove-Item -Path "..\build\$_" | Out-Null
        }
    }

    Write-Host "`nCleaning..."
    Remove-Item -Path "*.symbols.*" | Out-Null
    Set-Location -Path ".."
    Remove-Item -Path "$dir\temp" -Recurse | Out-Null

    if (-not ($KeepAutoPkg)) {
        Remove-Item -Path "$dir\build" -Recurse | Out-Null
    }

    if (-not ($KeepSources)) {
        Remove-Item -Path "$dir\sources" -Recurse | Out-Null
    }

    Write-Host -ForegroundColor Green "Done! Your packages are available in $dir\repository"
    Pause
    explorer.exe $dir\repository
}
catch {
    Write-Error $_
    Set-Location $dir
}