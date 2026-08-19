$ErrorActionPreference = "Stop"
.\build_v100_final.ps1
$src = Get-Content ProgramV100Build.cs -Raw -Encoding UTF8

$load = '                c.ClubModeEnabled = BoolAttr(root, "clubModeEnabled", false);' + "`r`n" +
        '                c.WatchdogEnabled = BoolAttr(root, "watchdogEnabled", true);' + "`r`n" +
        '                c.ReplaceExplorerShell = BoolAttr(root, "replaceExplorerShell", false);'
$save = '            root.SetAttribute("closeExplorerInClubMode", CloseExplorerInClubMode.ToString()); root.SetAttribute("clubModeEnabled", ClubModeEnabled.ToString());' + "`r`n" +
        '            root.SetAttribute("watchdogEnabled", WatchdogEnabled.ToString()); root.SetAttribute("replaceExplorerShell", ReplaceExplorerShell.ToString());'

$src = [regex]::Replace($src,'(?m)^\s*c\.ClubModeEnabled = BoolAttr\(root, \\.*$',$load,1)
$src = [regex]::Replace($src,'(?m)^\s*root\.SetAttribute\(\\.*$',$save,1)
Set-Content -Path ProgramV100Build.cs -Value $src -Encoding UTF8
