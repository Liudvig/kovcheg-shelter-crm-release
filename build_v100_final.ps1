$ErrorActionPreference = "Stop"

$script = Get-Content build_v100_fix.ps1 -Raw -Encoding UTF8
$script = $script.Replace('public static string LogPath','public static readonly string LogPath')
$script = $script.Replace('public static string WatchdogMarkerPath','public static readonly string WatchdogMarkerPath')
$script = $script.Replace('private static void Fatal','public static void Fatal')
Set-Content -Path build_v100_runtime.ps1 -Value $script -Encoding UTF8
.\build_v100_runtime.ps1
