$ErrorActionPreference = "Stop"

.\build_v061.ps1
$src = Get-Content ProgramV061Build.cs -Raw -Encoding UTF8

# build_v061.ps1 intentionally patches generated source; normalize the one multiline replacement
# using a real CRLF instead of a literal backslash-n sequence.
$bad = 'int baseAlpha=105+(100-t)*120/100;\n            using(SolidBrush baseShade=new SolidBrush(Color.FromArgb(baseAlpha,7,10,17)))e.Graphics.FillRectangle(baseShade,ClientRectangle);'
$good = "int baseAlpha=105+(100-t)*120/100;`r`n            using(SolidBrush baseShade=new SolidBrush(Color.FromArgb(baseAlpha,7,10,17)))e.Graphics.FillRectangle(baseShade,ClientRectangle);"
if (-not $src.Contains($bad)) { throw "0.6.1 generated newline patch target not found" }
$src = $src.Replace($bad, $good)

# Force the left host and navigation list to use the same value as the header.
$src = $src.Replace('navHost.Transparency=cfg.SidebarTransparency;', 'navHost.Transparency=cfg.HeaderTransparency;')
$src = $src.Replace('navList.Transparency=cfg.SidebarTransparency;', 'navList.Transparency=cfg.HeaderTransparency;')

Set-Content -Path ProgramV061Build.cs -Value $src -Encoding UTF8
