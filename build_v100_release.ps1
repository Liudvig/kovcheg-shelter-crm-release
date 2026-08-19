$ErrorActionPreference = "Stop"
.\build_v100_final.ps1
$src = Get-Content ProgramV100Build.cs -Raw -Encoding UTF8
$names = @('clubModeEnabled','watchdogEnabled','replaceExplorerShell','closeExplorerInClubMode')
foreach($name in $names){
    $src = $src.Replace(('\"'+$name+'\"'),('"'+$name+'"'))
}
Set-Content -Path ProgramV100Build.cs -Value $src -Encoding UTF8
