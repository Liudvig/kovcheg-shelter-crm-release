$ErrorActionPreference = "Stop"
$lines = Get-Content build_v090.ps1 -Encoding UTF8
$filtered = @()
foreach($line in $lines) {
    if($line -like '*Label info=new Label*') { continue }
    $filtered += $line
}
Set-Content -Path build_v090_runtime.ps1 -Value $filtered -Encoding UTF8
.\build_v090_runtime.ps1
