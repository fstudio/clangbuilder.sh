#!/usr/bin/env pwsh
# build llvm on linux, mac use powershell

$CMakeArgs = "-DCMAKE_BUILD_TYPE=Release"
if ($null -ne $env:PREFIX) {
    Write-Host "Install Prefix: $env:PREFIX"
    $CMakeArgs += " -DCMAKE_INSTALL_PREFIX=`"$env:PREFIX`""
}
$CMakeArgs += " -DLLVM_ENABLE_ASSERTIONS=OFF -DCMAKE_C_COMPILER=`"$env:CC`" -DCMAKE_CXX_COMPILER=`"$env:CXX`""
$CMakeArgs += " -DCMAKE_BUILD_TYPE=Release -DCLANG_REPOSITORY_STRING=`"clangbuilder.io`""


if ($null -eq $env:CC) {
    $env:CC = "gcc"
}

if ($null -eq $env:CXX) {
    $env:CXX = "g++"
}

# when use clang ,support lld
if ($env:CXX.Contains("clang")) {
    $CMakeArgs += " -DLLVM_ENABLE_LLD=ON"
}

try {
    Write-Host "Feature llvm sources"
    $outdir = "$PSScriptRoot/out/released"
    $srcdir = "$PSScriptRoot/out/rel/llvm"
    Invoke-Expression "$PSScriptRoot/ps/LLVMDownload.ps1"
    if (Test-Path $outdir) {
        Remove-Item -Force -Recurse "$outdir/*"
    }
    else {
        New-Item -ItemType Directory -Path $outdir -Force
    }
    Set-Location $outdir
    $CMakeArgsImpl = "`"$srcdir`" " + $CMakeArgs
    Write-Host "cmake $CMakeArgsImpl"
    $process = Start-Process -FilePath cmake -ArgumentList $CMakeArgsImpl -PassThru -Wait -NoNewWindow
    if ($process.ExitCode -eq 0) {
        make
        exit $LASTEXITCODE
    }
}
catch {
    Write-Host -ForegroundColor Red "$_"
    exit 1
}
