$ErrorActionPreference = "Stop"

$script = Get-Content build_v070.ps1 -Raw -Encoding UTF8
$start = $script.IndexOf('$logoPattern=')
if ($start -lt 0) { throw "0.7.0 logo pattern assignment not found" }
$lineEnd = $script.IndexOf("`n", $start)
if ($lineEnd -lt 0) { $lineEnd = $script.Length }
$newLine = '$logoPattern=''(?s)Label logo = new Label\(\);.*?brandHeader\.Controls\.Add\(logo\);'''
$script = $script.Substring(0,$start) + $newLine + "`r`n" + $script.Substring($lineEnd + 1)

# The base prototype already has a WallpaperFlow type. Keep the 0.7 games grid type unique.
$script = $script.Replace('public class WallpaperFlow : FlowLayoutPanel','public class EpohaGamesFlow : FlowLayoutPanel')
$script = $script.Replace('public WallpaperFlow(){','public EpohaGamesFlow(){')
$script = $script.Replace('WallpaperFlow grid=new WallpaperFlow();','EpohaGamesFlow grid=new EpohaGamesFlow();')

Set-Content -Path build_v070_runtime.ps1 -Value $script -Encoding UTF8
.\build_v070_runtime.ps1
