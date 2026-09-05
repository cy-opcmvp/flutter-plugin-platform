# Fix NuGet Package Issue for audioplayers_windows
# Run this script with Administrator privileges

Write-Host "Downloading Microsoft.Windows.ImplementationLibrary package..." -ForegroundColor Green

# Create temp directory
$tempDir = "$env:TEMP\nuget-fix"
New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

# Download the package
$packageUrl = "https://www.nuget.org/api/v2/package/Microsoft.Windows.ImplementationLibrary/1.0.210803.1"
$packagePath = Join-Path $tempDir "package.zip"

try {
    Invoke-WebRequest -Uri $packageUrl -OutFile $packagePath -UseBasicParsing
    Write-Host "Download completed." -ForegroundColor Green

    # Extract the package
    Write-Host "Extracting package..." -ForegroundColor Green
    $extractPath = Join-Path $tempDir "extracted"
    Expand-Archive -Path $packagePath -DestinationPath $extractPath -Force

    # Create NuGet packages directory
    $targetDir = "C:\Program Files (x86)\Microsoft SDKs\NuGetPackages\microsoft.windows.implementationlibrary\1.0.210803.1"
    New-Item -Path $targetDir -ItemType Directory -Force | Out-Null

    # Copy package files
    Write-Host "Installing package to $targetDir..." -ForegroundColor Green
    Copy-Item -Path "$extractPath\*" -Destination $targetDir -Recurse -Force

    Write-Host "`nPackage installed successfully!" -ForegroundColor Green
    Write-Host "You can now run 'flutter run -d windows'" -ForegroundColor Cyan

} catch {
    Write-Host "`nError: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please check your internet connection and try again." -ForegroundColor Yellow
} finally {
    # Cleanup
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force
    }
}

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
