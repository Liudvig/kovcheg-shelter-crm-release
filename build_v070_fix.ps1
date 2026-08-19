$ErrorActionPreference = "Stop"

$script = Get-Content build_v070.ps1 -Raw -Encoding UTF8
$old = '$logoPattern=''Label logo = new Label\(\); logo\.Text="Э"; logo\.TextAlign=ContentAlignment\.MiddleCenter; logo\.SetBounds\(14,15,50,50\); logo\.Font=F\(24,FontStyle\.Bold\); logo\.ForeColor=Color\.FromArgb\(20,16,28\); logo\.BackColor=Accent; brandHeader\.Controls\.Add\(logo\);'''
$new = '$logoPattern=''(?s)Label logo = new Label\(\);.*?brandHeader\.Controls\.Add\(logo\);'''
if (-not $script.Contains($old)) { throw "0.7.0 logo-pattern line not found" }
$script = $script.Replace($old, $new)
Set-Content -Path build_v070_runtime.ps1 -Value $script -Encoding UTF8
.\build_v070_runtime.ps1
