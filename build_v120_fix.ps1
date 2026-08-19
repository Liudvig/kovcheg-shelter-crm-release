$ErrorActionPreference = "Stop"
.\build_v120.ps1
$src = Get-Content ProgramV120Build.cs -Raw -Encoding UTF8
$src = $src.Replace('StringBuilder log=new StringBuilder();','System.Text.StringBuilder log=new System.Text.StringBuilder();')
$src = $src.Replace('Encoding.ASCII','System.Text.Encoding.ASCII')
$src = $src.Replace('Encoding.UTF8','System.Text.Encoding.UTF8')
Set-Content -Path ProgramV120Build.cs -Value $src -Encoding UTF8
