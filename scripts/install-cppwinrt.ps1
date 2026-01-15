# Install Microsoft.Windows.CppWinRT NuGet Package
# Run with Administrator privileges

Write-Host "Installing Microsoft.Windows.CppWinRT package..." -ForegroundColor Green

$tempDir = "$env:TEMP\nuget-cppwinrt"
New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

$packageUrl = "https://www.nuget.org/api/v2/package/Microsoft.Windows.CppWinRT/2.0.210806.1"
$packagePath = Join-Path $tempDir "package.zip"

try {
    Write-Host "Downloading package..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $packageUrl -OutFile $packagePath -UseBasicParsing

    Write-Host "Extracting package..." -ForegroundColor Cyan
    $extractPath = Join-Path $tempDir "extracted"
    Expand-Archive -Path $packagePath -DestinationPath $extractPath -Force

    $targetDir = "C:\Program Files (x86)\Microsoft SDKs\NuGetPackages\microsoft.windows.cppwinrt\2.0.210806.1"
    New-Item -Path $targetDir -ItemType Directory -Force | Out-Null

    Write-Host "Installing to $targetDir..." -ForegroundColor Cyan
    Copy-Item -Path "$extractPath\*" -Destination $targetDir -Recurse -Force

    Write-Host "`n✅ Package installed successfully!" -ForegroundColor Green
    Write-Host "You can now run 'flutter run -d windows'" -ForegroundColor Cyan

} catch {
    Write-Host "`n❌ Error: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force
    }
}

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
