#
# sdl2-nuget.ps1
#

#########################

# Some customisation variables
$pkg_prefix = "" # Prefix of packages
$pkg_postfix = ".nuget" # Postfix of packages
$keep_sources = $true # Use $true to keep source files or $false to delete them, $true by default
$keep_autopkg = $true # Keep autopkg files, $false by default
$add_docs = $false # Add docs in system module, $false by default
$pkgs_hotfix = @{ "sdl2" = ""; "sdl2_image" = ""; "sdl2_ttf" = "2"; "sdl2_mixer" = ""; "sdl2_net" = "2" } # Packages hotfix version, "" by default for each module [means no hotfix]

# SDL2 packages variables
$sdl2_owners =	"xapdkop" # Packages "owner" name. Replace username with your name
$sdl2_tags = "SDL2 SDL Audio Graphics Keyboard Mouse Joystick Multi-Platform OpenGL Direct3D" # Tags for your packages, "SDL2, native, CoApp" by default

# SDL2 nuget packages 'generation' variables
$sdl2_packages = "sdl2", "sdl2_image", "sdl2_ttf", "sdl2_mixer", "sdl2_net" # SDL2 packages, that will be generated
$sdl2_version = @{ "sdl2" = "2.0.9"; "sdl2_image" = "2.0.4"; "sdl2_ttf" = "2.0.14"; "sdl2_mixer" = "2.0.4"; "sdl2_net" = "2.0.1" }
$sdl2_platforms = "x86", "x64"

#########################

# It's not recommended to change these values
$sdl2_download_url = "https://www.libsdl.org/release/"
$sdl2_projects_download_url = "https://www.libsdl.org/projects/"
$sdl2_authors = "Sam Lantinga and SDL2 contributors"
$sdl2_licence_url = "https://www.libsdl.org/license.php"
$sdl2_project_url = "https://www.libsdl.org"
$sdl2_icon_url = "https://www.libsdl.org/media/SDL_logo.png"
$sdl2_require_license_acceptance = "false"
$sdl2_summary = "Simple DirectMedia Layer is a cross-platform development library designed to provide low level access to audio, keyboard, mouse, joystick, and graphics hardware via OpenGL and Direct3D."
$sdl2_description = "Simple DirectMedia Layer is a cross-platform development library designed to provide low level access to audio, keyboard, mouse, joystick, and graphics hardware via OpenGL and Direct3D. It is used by video playback software, emulators, and popular games including Valve's award winning catalog and many Humble Bundle games.

SDL officially supports Windows, Mac OS X, Linux, iOS, and Android. Support for other platforms may be found in the source code.

SDL is written in C, works natively with C++, and there are bindings available for several other languages, including C# and Python.

Source code of this package and build script are available on https://github.com/xapdkop/sdl2-nuget"
$sdl2_changelog = "Look at the official SDL website https://libsdl.org"

# Don't change these values
$dir = Split-Path -Path $MyInvocation.MyCommand.Path
$coapp_download_url = "http://coapp.org/pages/releases.html"
$sdl2_dependencies = @{ "sdl2_image" = "sdl2" ; "sdl2_ttf" = "sdl2"; "sdl2_mixer" = "sdl2"; "sdl2_net" = "sdl2" }

#########################

function PackageHeader([string]$Package) {
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
		id = $pkg_prefix$Package$pkg_postfix;
		title: $pkg_prefix$Package$pkg_postfix;
		version: " + $sdl2_version[$Package] + $pkgs_hotfix[$Package] + ";
		authors: { $sdl2_authors };
		owners: { $sdl2_owners };
		licenseUrl: ""$sdl2_licence_url"";
		projectUrl: ""$sdl2_project_url"";
		iconUrl: ""$sdl2_icon_url"";
		requireLicenseAcceptance: $sdl2_require_license_acceptance;
		summary: ""$sdl2_summary"";
		description: @""$sdl2_description"";
		releaseNotes: ""$sdl2_changelog"";
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
        $datas += "		[$plf,dynamic] {"
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
			$pkg_prefix$dp$pkg_postfix/" + $sdl2_version[$dp] + $pkgs_hotfix[$dp] + ","
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
    $autopkg += "		nestedInclude: {
			#destination = `${d_include};
			""`${SRC}$Package\include\**\*""
		};

"
    if ($add_docs -ne $false) {
        $autopkg += "		docs: {
			`${SRC}$Package\docs\**\*
		};

"
    }
    $autopkg += PackageLibs($Package)
    $autopkg += "
	};

	targets {
		Defines += HAS_SDL2;
	}
}"
    $autopkg | Out-File "$pkg_prefix$Package$pkg_postfix.autopkg"
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip([string]$ZipFile, [string]$OutPath) {
    [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipFile, $OutPath)
}

function CreateDirectory([string]$Path) {
    if (-not (Test-Path $Path)) {
        New-Item "$Path" -ItemType Directory -Force | Out-Null
    }
}

#########################
########## Main #########
#########################

# Checking on installed CoApp Tools
try {
    Show-CoAppToolsVersion | Out-Null
}
catch {
    Write-Host -ForegroundColor Yellow "You need CoApp tools to build NuGet packages!"
    Read-Host "Press ENTER to open CoApp website or Ctrl-C to exit..."
    Start-Process $coapp_download_url
    Exit
}

foreach ($htfxKey in @($pkgs_hotfix.Keys)) {
    if ($pkgs_hotfix[$htfxKey] -ne "" -and -not $pkgs_hotfix[$htfxKey].StartsWith(".")) {
        $pkgs_hotfix[$htfxKey] = $pkgs_hotfix[$htfxKey].Insert(0, ".")
    }
}

CreateDirectory("$dir\temp")
CreateDirectory("$dir\sources")
CreateDirectory("$dir\distfiles")
CreateDirectory("$dir\build")

foreach ($pkg in $sdl2_packages) {
    $filename = "$pkg-devel-" + $sdl2_version[$pkg] + "-VC.zip"
    $filename = $filename.Replace("sdl", "SDL")
    $outfile = "$dir\distfiles\$filename"
    if (-not (Test-Path $outfile)) {
        if ($pkg -eq "sdl2") {
            $fileuri = $sdl2_download_url + $filename
        }
        else {
            $fileuri = $sdl2_projects_download_url + $pkg.Replace("sdl2", "SDL") + "/release/" + $filename
            #$fileuri = $fileuri.Replace("sdl_", "SDL_")
        }
        $webclient = New-Object System.Net.WebClient
        $downloaded = $false
        while ($downloaded -eq $false) {
            try {
                Write-Host "`nDownloading $filename..."
                $webclient.DownloadFile($fileuri, $outfile)
                $downloaded = $true
                Write-Host -ForegroundColor Green "$filename downloaded"
            }
            catch {
                Write-Warning "An error occurred while downloading the file $fileuri"
                Write-Host -ForegroundColor Yellow "Press ENTER to try again or Ctrl-C to exit..."
                Read-Host
            }
        }
    }
    Write-Host "`nExtracting $filename..."
    Remove-Item -Path "$dir\temp\*" -Recurse | Out-Null # Clearing directory to avoid Unzip exceptions
    try {
        Unzip "$outfile" "$dir\temp\"
        Write-Host -ForegroundColor Green "$filename extracted"
    }
    catch {
        Write-Warning -Message "An error occurred while extracting the file $filename"
        Write-Warning -Message "Restart the script!!!"
        Remove-Item -Path "$outfile" -Force | Out-Null
        Pause
        Exit
    }
    $zip = "$dir\temp\" + $pkg.Replace("sdl", "SDL") + "-" + $sdl2_version[$pkg]

    CreateDirectory("$dir\sources\$pkg")
    foreach ($plf in $sdl2_platforms) {
        CreateDirectory("$dir\sources\$pkg\lib\$plf")
        CreateDirectory("$dir\sources\$pkg\bin\$plf")
    }
    CreateDirectory("$dir\sources\$pkg\include")
    Move-Item -Path "$zip\include\*.h" -Destination "$dir\sources\$pkg\include\" -Force | Out-Null
    CreateDirectory("$dir\sources\$pkg\docs")
    Move-Item -Path (Get-ChildItem "$zip\" -File -Include "*.txt" -Recurse) -Destination "$dir\sources\$pkg\docs\" -Force | Out-Null
    if ($add_docs -ne $false) {
        if (Test-Path "$zip\docs\") {
            Copy-Item -Path "$zip\docs\*" -Destination "$dir\sources\$pkg\docs\" | Out-Null
        }
    }

    foreach ($plf in $sdl2_platforms) {
        Move-Item -Path "$zip\lib\$plf\*.dll" -Destination "$dir\sources\$pkg\bin\$plf\" -Force | Out-Null
        Move-Item -Path "$zip\lib\$plf\*.lib" -Destination "$dir\sources\$pkg\lib\$plf\" -Force | Out-Null
    }
    Remove-Item -Path "$zip" -Recurse | Out-Null
}

# Workaround for outdated zlib1.dll in SDL_ttf
Copy-Item -Path "$dir\sources\sdl2_image\bin\x64\zlib1.dll" -Destination "$dir\sources\sdl2_ttf\bin\x64\zlib1.dll"
Copy-Item -Path "$dir\sources\sdl2_image\bin\x86\zlib1.dll" -Destination "$dir\sources\sdl2_ttf\bin\x86\zlib1.dll"

Write-Host
Set-Location "$dir\build"
foreach ($module in $sdl2_packages) {
    Write-Host "Generating $pkg_prefix$module$pkg_postfix.autopkg..."
    GeneratePackage($module)
}
Set-Location -Path ".."

New-Item "$dir\repository" -ItemType Directory -Force | Out-Null
Set-Location "$dir\repository"
Get-ChildItem -Path "../build/" -Filter "$pkg_prefix*$pkg_postfix.autopkg" | Foreach-Object {
    Write-Host "`nGenerating NuGet package from $_...`n"
    Write-NuGetPackage ..\build\$_ | Out-Null
    if ($keep_autopkg -eq $false) {
        Remove-Item -Path "..\build\$_" | Out-Null
    }
}
Write-Host "`nCleaning..."
Remove-Item -Path "*.symbols.*" | Out-Null
Set-Location -Path ".."
Remove-Item -Path "$dir\temp" -Recurse | Out-Null
if ($keep_autopkg -eq $false) {
    Remove-Item -Path "$dir\build" -Recurse | Out-Null
}
if ($keep_sources -ne $true) {
    Remove-Item -Path "$dir\sources" -Recurse | Out-Null
}
Write-Host -ForegroundColor Green "Done! Your packages are available in $dir\repository"
Pause