#
# sdl2-nuget.ps1
#

#########################

param([Alias("SDL")][string] $sdl2, [Alias("SDL-image")][string] $sdl2_image, [Alias("SDL-ttf")][string] $sdl2_ttf, 
    [Alias("SDL-mixer")][string] $sdl2_mixer, [Alias("SDL-net")][string] $sdl2_net,
    [string] $PackagesPrefix = "", [string] $PackagesPostfix = ".nuget", [switch] $KeepSources = $false,
    [switch] $KeepAutoPkg = $false, [switch] $AddDocs = $false, [switch] $ForceDownload = $false,
    [switch] $ClearOutDir = $false)

$version = "3.0.0-beta.3"

Write-Host -ForegroundColor Blue "sdl2-nuget v$version"

#########################

# SDL2 packages variables
$sdl2_owners =	"kosmotema" # Packages "owner" name. Replace it with your name
$sdl2_tags = "C++ SDL2 SDL Audio Graphics Keyboard Mouse Joystick Multi-Platform OpenGL Direct3D" # Tags for your packages

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
$coapp_download_url = "http://coapp.github.io/pages/releases.html"
$sdl2_default_dependency = @(@{ "name" = "sdl2"; "version" = "2.0.0" })
$sdl2_dependencies = @{
    "sdl2_image" = $sdl2_default_dependency
    "sdl2_ttf"   = $sdl2_default_dependency
    "sdl2_mixer" = $sdl2_default_dependency
    "sdl2_net"   = $sdl2_default_dependency
}

#########################

$sdl2_packages = @{
    "sdl2"       = $sdl2
    "sdl2_image" = $sdl2_image
    "sdl2_ttf"   = $sdl2_ttf
    "sdl2_mixer" = $sdl2_mixer
    "sdl2_net"   = $sdl2_net
}

#########################

function Get-PackageVersion([string] $Version, [string] $FallbackVersion) {
    if ($Version -eq "latest") {
        return $FallbackVersion
    }

    return $Version
}

function Get-TagVersion([string]$Version) {
    return $Version -replace '^(\d+)\.(\d+)\.(\d+).*$', '$1.$2.$3'
}

function Get-VersionFromRelease($ReleaseInfo) {
    return $ReleaseInfo['tag_name'] -replace "(pre)?release-", ""
}

function Get-TagFromVersion([string] $Version) {
    if ($Version -eq "latest") {
        return $version
    }

    $TagVersion = Get-TagVersion $Version;

    if ($Version -match "-") {
        return "tags/prerelease-$TagVersion"
    }

    return "tags/release-$TagVersion"
}

function Read-RepoInfo([string] $Package, [string] $Version) {
    $reponame = $Package.Replace("sdl", "SDL").Replace("SDL2", "SDL")
    $tag = Get-TagFromVersion $Version

    return (Invoke-WebRequest -Uri "https://api.github.com/repos/libsdl-org/$reponame/releases/$tag" | ConvertFrom-Json -AsHashtable)
}

function Format-PackageName([string]$Package) {
    return "$PackagesPrefix$Package$PackagesPostfix"
}

function New-PackageHeader([string]$Package, $Info) {
    $currentYear = (Get-Date).Year

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
		id = $(Format-PackageName $Package);
		title: $(Format-PackageName $Package);
		version: $(Get-PackageVersion $sdl2_packages[$Package] (Get-VersionFromRelease $Info));
		authors: { $sdl2_authors };
		owners: { $sdl2_owners };
		licenseUrl: ""$sdl2_licence_url"";
		projectUrl: ""$sdl2_project_url"";
		iconUrl: ""$sdl2_icon_url"";
		requireLicenseAcceptance: $sdl2_require_license_acceptance;
		summary: ""$sdl2_summary"";
		description: @""$sdl2_description"";
		releaseNotes: @""$($Info["body"])"";
		copyright: Copyright $currentYear;
		tags: ""$sdl2_tags"";
	}

	#output-packages {
		default : `${pkgname};
		redist : `${pkgname}.redist;
		symbols : `${pkgname}.symbols;
	}"
}

function New-PackageLibs([string]$Package) {
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

function New-PackageDependencies([string]$Package) {
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

function New-Package([string]$Package, $Info, [string]$OutFile) {

    $autopkg = New-PackageHeader $Package $Info
    $autopkg += New-PackageDependencies $Package
    $autopkg += "

	files {
		#defines {
			SRC = ..\..\sources\;
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
    $autopkg += New-PackageLibs($Package)
    $autopkg += "
	};

	targets {
		Defines += HAS_SDL2;
	}
}"
    $autopkg | Out-File $OutFile
}

function New-Directory([string]$Path, [switch]$ClearIfExists = $false, [switch]$PassThru = $false) {
    if (-not (Test-Path $Path)) {
        New-Item $Path -ItemType Directory -Force | Out-Null
    }
    elseif ($ClearIfExists) {
        Get-ChildItem -Path $Path -Recurse | Remove-Item -Recurse | Out-Null
    }

    if ($PassThru) {
        return $Path
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

New-Directory "$dir\temp" -ClearIfExists
New-Directory "$dir\sources"
New-Directory "$dir\distfiles"
New-Directory "$dir\build" -ClearIfExists
New-Directory "$dir\repository" -ClearIfExists:$ClearOutDir

foreach ($pkg in $sdl2_packages.keys) {
    if (-not $sdl2_packages[$pkg]) {
        continue
    }

    $info = Read-RepoInfo $pkg $sdl2_packages[$pkg]

    if (-not $info) {
        continue
    }

    $version = Get-PackageVersion $sdl2_packages[$pkg] (Get-VersionFromRelease $info)
    $file = $info['assets'] | Where-Object { $_.name -match "-devel-.+-VC\.zip$" }

    if (-not $file) {
        Write-Error "Cannot find downloadable file for $pkg"
        continue
    }

    $filename = $file["name"]
    $fileuri = $file["browser_download_url"]

    $outfile = "$dir\distfiles\$filename"

    if ($ForceDownload -or -not (Test-Path $outfile)) {
        while ($true) {
            try {
                Write-Host "`nDownloading $filename from $fileuri ... " -NoNewLine
                Invoke-WebRequest -Uri $fileuri -OutFile $outfile
                Write-Host -ForegroundColor Green "OK"
                break
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
        $zip = (Expand-Archive "$outfile" "$dir\temp\" -PassThru)[0].FullName
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

    New-Directory "$dir\sources\$pkg"

    foreach ($plf in $sdl2_platforms) {
        New-Directory "$dir\sources\$pkg\lib\$plf"
        New-Directory "$dir\sources\$pkg\bin\$plf"
    }

    New-Directory "$dir\sources\$pkg\include"
    Move-Item -Path "$zip\include\*.h" -Destination "$dir\sources\$pkg\include\" -Force | Out-Null
    New-Directory "$dir\sources\$pkg\docs"
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

    New-Directory "$dir\build\$pkg" -PassThru | Set-Location

    $autopkg = "$(Format-PackageName $pkg)-$version.autopkg"

    Write-Host "Generating $autopkg... " -NoNewline

    try {
        New-Package $pkg $info $autopkg
        Write-Host -ForegroundColor Green "OK"
    }
    catch {
        Write-Host -ForegroundColor Yellow "ERROR"
        Write-Warning "Cannot create .autopkg file"
        Write-Error $_
        continue
    }

    Set-Location "$dir\repository"

    try {
        Get-ChildItem -Path "..\build\$pkg\" -Filter "*-$version.autopkg" | Foreach-Object {
            Write-Host "`nGenerating NuGet package from $($_.Name)...`n"
    
            powershell.exe Write-NuGetPackage $_
    
            if (-not $?) {
                throw;
            }
    
            if (-not ($KeepAutoPkg)) {
                Remove-Item -Path $_ | Out-Null
            }
        }
    }
    catch {
        Write-Error $_
    }
}

try {
    Write-Host "`nCleaning..."
    Get-ChildItem -Path "$dir\repository" -Filter "*.symbols.*" | Remove-Item | Out-Null
    Remove-Item -Path "$dir\temp" -Recurse | Out-Null

    if (-not ($KeepSources)) {
        Remove-Item -Path "$dir\sources" -Recurse | Out-Null
    }
    
    Set-Location $dir

    Write-Host -ForegroundColor Green "Done! Your packages are available in $dir\repository"
    Pause
    explorer.exe $dir\repository
}
catch {
    Write-Error $_
    Set-Location $dir
}