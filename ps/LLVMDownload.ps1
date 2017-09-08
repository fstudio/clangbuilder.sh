# Unix download
#$MainURL="https://releases.llvm.org/4.0.1/llvm-4.0.1.src.tar.xz"
#$AllProtocols = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
#[System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
Function DownloadFile {
    param(
        [String]$Version,
        [String]$Name
    )
    Write-Host "Download $Name-$Version"
    if (Test-Path "$Name-$Version.tar.xz") {
        Write-Host "source $Name-$Version.tar.gz exists"
        return 
    }
    $UserAgent = [Microsoft.PowerShell.Commands.PSUserAgent]::Chrome 
    try {
        Invoke-WebRequest -Uri "https://releases.llvm.org/$Version/$Name-$Version.src.tar.xz" -OutFile "$Name-$Version.tar.xz" -UserAgent $UserAgent -UseBasicParsing
    }
    catch {
        Write-Host -ForegroundColor Red "$_"
    }
}

Function UnpackFile {
    param(
        [String]$File,
        [String]$Path,
        [String]$OldName,
        [String]$Name
    )
    if (!(Test-Path $Path)) {
        New-Item -Force -ItemType Directory $Path
    }
    # cmake -E tar -xvf file.tar.gz
    $process = Start-Process -FilePath "cmake" -ArgumentList "-E tar -xvf `"$File`"" -WorkingDirectory "$Path" -NoNewWindow -Wait -PassThru
    if ($process.ExitCode -eq 0) {
        Rename-Item -Path "$Path/$OldName" -NewName "$Name"
    }
    else {
        Write-Host -ForegroundColor Red "tar exit: $($process.ExitCode)"
    }
}

$ClangbuilderRoot = Split-Path -Parent $PSScriptRoot

Push-Location $PWD

$sourcedir = "$ClangbuilderRoot/out/rel"

if (!(Test-Path $sourcedir)) {
    New-Item -ItemType Directory -Force -Path $sourcedir
}


Set-Location $sourcedir

$revobj = Get-Content -Path "$ClangbuilderRoot/config/version.json" |ConvertFrom-Json
$release = $revobj.Release

if (Test-Path "$sourcedir/release.lock.json") {
    $freeze = Get-Content -Path "$sourcedir/release.lock.json" |ConvertFrom-Json
    if ($freeze.Version -eq $release -and (Test-Path "$sourcedir/llvm")) {
        Write-Host "Use llvm download cache"
        Pop-Location
        return ;
    }
}

if (Test-Path "$sourcedir/llvm") {
    Remove-Item -Force -Recurse "$sourcedir/llvm"
}

Write-Host "LLVM release: $release"

DownloadFile -Version $release -Name "llvm"
DownloadFile -Version $release -Name "cfe"
DownloadFile -Version $release -Name "lld"
DownloadFile -Version $release -Name "lldb"
DownloadFile -Version $release -Name "clang-tools-extra"
DownloadFile -Version $release -Name "compiler-rt"
DownloadFile -Version $release -Name "libcxx"
DownloadFile -Version $release -Name "libcxxabi"
DownloadFile -Version $release -Name "polly"

UnpackFile -File "$PWD/llvm-$release.tar.xz" -Path "." -OldName "llvm-$release.src" -Name "llvm"
UnpackFile -File "$PWD/cfe-$release.tar.xz" -Path "llvm/tools" -OldName "cfe-$release.src" -Name "clang"
UnpackFile -File "$PWD/lld-$release.tar.xz" -Path "llvm/tools" -OldName "lld-$release.src" -Name "lld"
UnpackFile -File "$PWD/lldb-$release.tar.xz" -Path "llvm/tools" -OldName "lldb-$release.src" -Name "lldb"
UnpackFile -File "$PWD/openmp-$release.tar.xz" -Path "llvm/tools" -OldName "polly-$release.src" -Name "polly"
UnpackFile -File "$PWD/clang-tools-extra-$release.tar.xz" -Path "llvm/tools/clang/tools" -OldName "clang-tools-extra-$release.src" -Name "extra"
UnpackFile -File "$PWD/compiler-rt-$release.tar.xz" -Path "llvm/projects" -OldName "compiler-rt-$release.src" -Name "compiler-rt"
UnpackFile -File "$PWD/libcxx-$release.tar.xz" -Path "llvm/projects" -OldName "libcxx-$release.src" -Name "libcxx"
UnpackFile -File "$PWD/libcxxabi-$release.tar.xz" -Path "llvm/projects" -OldName "libcxxabi-$release.src" -Name "libcxxabi"

$vercache = @{}
$vercache["Version"] = $release
ConvertTo-Json -InputObject $vercache|Out-File -Encoding utf8 -FilePath "$PWD/release.lock.json"

Pop-Location