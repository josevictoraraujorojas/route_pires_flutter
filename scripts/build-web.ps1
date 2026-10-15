$ErrorActionPreference = 'Stop'

flutter build web --release --base-href /app/ --no-wasm-dry-run
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Output 'Flutter Web pronto em build/web para publicação em /app/.'
