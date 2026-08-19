$ErrorActionPreference = "Stop"
.\build_v100_final.ps1
$src = Get-Content ProgramV100Build.cs -Raw -Encoding UTF8
$names = @('clubModeEnabled','watchdogEnabled','replaceExplorerShell','closeExplorerInClubMode')
foreach($name in $names){
    $clean='"'+$name+'"'
    $src=$src.Replace(('\"'+$name+'\"'),$clean)
    $src=$src.Replace(('\\"'+$name+'\\"'),$clean)
    $src=$src.Replace(('\\\"'+$name+'\\\"'),$clean)
}
Set-Content -Path ProgramV100Build.cs -Value $src -Encoding UTF8
$lines=Get-Content ProgramV100Build.cs
for($i=168;$i -le 230 -and $i -le $lines.Count;$i++){Write-Host (("{0}: {1}" -f $i,$lines[$i-1]))}
