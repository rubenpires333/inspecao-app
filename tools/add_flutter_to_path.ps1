$flutterBin = 'C:\src\flutter\bin'
if (-not (Test-Path "$flutterBin\flutter.bat")) {
    Write-Error "Nao encontrado: $flutterBin\flutter.bat"
    exit 1
}
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($userPath -like "*flutter\bin*") {
    Write-Host "PATH de utilizador ja contem flutter\bin"
    exit 0
}
$newPath = ($userPath.TrimEnd(';') + ';' + $flutterBin)
[Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
Write-Host "Adicionado ao PATH do utilizador: $flutterBin"
Write-Host "Feche e reabra o terminal (ou o Cursor) para aplicar."
