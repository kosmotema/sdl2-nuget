#
# sdl2-nuget.ps1
#

#########################

# Some customisation variables
$pkg_prefix = "" # Prefix of packages
$pkg_postfix = ".nuget" # Postfix of packages
$keep_sources = $false # Use $true to keep source files or $false to delete them, $true by default
$keep_autopkg = $true # Keep autopkg files, $false by default
$add_docs = $false # Add docs in system module, $false by default
$pkgs_hotfix = @{ "sdl2" = ""; "sdl2_image" = ""; "sdl2_ttf" = ""; "sdl2_mixer" = ""; "sdl2_net" = "2" } # Packages hotfix version, "" by default for each module [means no hotfix]

# SDL2 packages variables
$sdl2_owners =	"xapdkop" # Packages "owner" name. Replace username with your name
$sdl2_tags = "C++ SDL2 SDL Audio Graphics Keyboard Mouse Joystick Multi-Platform OpenGL Direct3D" # Tags for your packages, "SDL2, native, CoApp" by default

# SDL2 nuget packages 'generation' variables
$sdl2_packages = "sdl2", "sdl2_image", "sdl2_ttf", "sdl2_mixer", "sdl2_net" # SDL2 packages, that will be generated
$sdl2_version = @{ "sdl2" = "2.0.22"; "sdl2_image" = "2.6.0"; "sdl2_ttf" = "2.0.18"; "sdl2_mixer" = "2.6.0"; "sdl2_net" = "2.0.1" }
$sdl2_platforms = "x86", "x64"

#########################

# It's not recommended to change these values
# $sdl2_download_url - deprecated, change it directly in the script
# $sdl2_projects_download_url - deprecated, change it directly in the script
$sdl2_authors = "Sam Lantinga and SDL contributors"
$sdl2_licence_url = "https://www.libsdl.org/license.php"
$sdl2_project_url = "https://www.libsdl.org"
$sdl2_icon_url = "https://www.libsdl.org/media/SDL_logo.png"
$sdl2_require_license_acceptance = "false"
$sdl2_summary = "Simple DirectMedia Layer is a cross-platform development library designed to provide low level access to audio, keyboard, mouse, joystick, and graphics hardware via OpenGL and Direct3D."
$sdl2_description = "Simple DirectMedia Layer is a cross-platform development library designed to provide low level access to audio, keyboard, mouse, joystick, and graphics hardware via OpenGL and Direct3D. It is used by video playback software, emulators, and popular games including Valve's award winning catalog and many Humble Bundle games.

SDL officially supports Windows, Mac OS X, Linux, iOS, and Android. Support for other platforms may be found in the source code.

SDL is written in C, works natively with C++, and there are bindings available for several other languages, including C# and Python.

Is this package outdated? Report here: https://github.com/kosmotema/sdl2-nuget"
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
			$pkg_prefix$dp$pkg_postfix,"
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
    $autopkg | Out-File "$pkg_prefix$Package$pkg_postfix.autopkg"
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip([string]$ZipFile, [string]$OutPath) {
    [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipFile, $OutPath)
}

function New-Directory([Parameter (Mandatory)][string]$Path, [switch]$ClearIfExists = $false) {
    if (-not (Test-Path $Path)) {
        New-Item $Path -ItemType Directory -Force | Out-Null
    }
    elseif ($ClearIfExists) {
        Get-ChildItem -Path $Path -Recurse | Remove-Item | Out-Null
    }
}

#########################

Import-Module CoApp

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

New-Directory "$dir\temp" -ClearIfExists
New-Directory "$dir\sources"
New-Directory "$dir\distfiles"
New-Directory "$dir\build" -ClearIfExists

foreach ($pkg in $sdl2_packages) {
    $version = $sdl2_version[$pkg]
    $packagename = $pkg.Replace("sdl", "SDL")
    $reponame = $packagename.Replace("SDL2", "SDL")
    $filename = "$packagename-devel-" + $version + "-VC.zip"
    $outfile = "$dir\distfiles\$filename"
    if (-not (Test-Path $outfile)) {
        $fileuri = "https://github.com/libsdl-org/$reponame/releases/download/release-$version/$filename"
        $webclient = New-Object System.Net.WebClient
        $downloaded = $false
        while ($downloaded -eq $false) {
            try {
                Write-Host "`nDownloading $filename from $fileuri ... " -NoNewLine
                $webclient.DownloadFile($fileuri, $outfile)
                $downloaded = $true
                Write-Host -ForegroundColor Green "OK"
            }
            catch {
                Write-Warning "ERROR"
                Write-Host -ForegroundColor Yellow "Press ENTER to try again or Ctrl-C to exit..."
                Read-Host
            }
        }
    }
    Write-Host "`nExtracting $filename... " -NoNewLine
    try {
        Unzip "$outfile" "$dir\temp\"
        Write-Host -ForegroundColor Green "OK"
    }
    catch {
        Write-Warning -Message "ERROR"
        Write-Warning -Message "Cannot unzip package"
        Remove-Item -Path "$outfile" -Force | Out-Null
        Pause
        Exit
    }
    $zip = "$dir\temp\" + $pkg.Replace("sdl", "SDL") + "-" + $sdl2_version[$pkg]

    New-Directory "$dir\sources\$pkg"
    foreach ($plf in $sdl2_platforms) {
        New-Directory "$dir\sources\$pkg\lib\$plf"
        New-Directory "$dir\sources\$pkg\bin\$plf"
    }
    New-Directory "$dir\sources\$pkg\include"
    Move-Item -Path "$zip\include\*.h" -Destination "$dir\sources\$pkg\include\" -Force | Out-Null
    New-Directory "$dir\sources\$pkg\docs"
    Move-Item -Path (Get-ChildItem "$zip\*.txt" -File) -Destination "$dir\sources\$pkg\docs\" -Force | Out-Null
    if ($add_docs -ne $false) {
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
if ($sdl2_version["sdl2_ttf"] -lt "2.0.15") {
    Copy-Item -Path "$dir\sources\sdl2_image\bin\x64\zlib1.dll" -Destination "$dir\sources\sdl2_ttf\bin\x64\zlib1.dll"
    Copy-Item -Path "$dir\sources\sdl2_image\bin\x86\zlib1.dll" -Destination "$dir\sources\sdl2_ttf\bin\x86\zlib1.dll"
}

Write-Host
Set-Location "$dir\build"
foreach ($module in $sdl2_packages) {
    Write-Host "Generating $pkg_prefix$module$pkg_postfix.autopkg... " -NoNewline
    try {
        GeneratePackage($module)
        Write-Host -ForegroundColor Green "OK"
    }
    catch {
        Write-Warning -Message "ERROR"
        Write-Warning "Cannot create .autopkg file"
    }
}
Set-Location -Path ".."

New-Directory "$dir\repository" -ClearIfExists
Set-Location "$dir\repository"
try {
    Get-ChildItem -Path "../build/" -Filter "$pkg_prefix*$pkg_postfix.autopkg" | Foreach-Object {
        Write-Host "`nGenerating NuGet package from $_...`n"
        Write-NuGetPackage ..\build\$_ | Out-Null
        if (-not ($keep_autopkg)) {
            Remove-Item -Path "..\build\$_" | Out-Null
        }
    }
    Write-Host "`nCleaning..."
    Remove-Item -Path "*.symbols.*" | Out-Null
    Set-Location -Path ".."
    Remove-Item -Path "$dir\temp" -Recurse | Out-Null
    if (-not ($keep_autopkg)) {
        Remove-Item -Path "$dir\build" -Recurse | Out-Null
    }
    if (-not ($keep_sources)) {
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