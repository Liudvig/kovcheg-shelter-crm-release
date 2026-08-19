$ErrorActionPreference = "Stop"

$script = Get-Content build_v080.ps1 -Raw -Encoding UTF8
$bad = ',1,[System.Text.RegularExpressions.RegexOptions]::Singleline)'
$good = ',[System.Text.RegularExpressions.RegexOptions]::Singleline)'
if (-not $script.Contains($bad)) { throw "0.8 regex overload patch target not found" }
$script = $script.Replace($bad,$good)
Set-Content -Path build_v080_runtime.ps1 -Value $script -Encoding UTF8
.\build_v080_runtime.ps1
