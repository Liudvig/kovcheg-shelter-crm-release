$ErrorActionPreference = "Stop"

# Run the 1.1.0 fixed builder without its old footer-layout replacement.
$lines = Get-Content build_v110_fix.ps1 -Encoding UTF8
$out = New-Object System.Collections.Generic.List[string]
$skip = $false
foreach($line in $lines) {
    if($line -like '# Make the footer*') { $skip = $true; continue }
    if($skip) {
        if($line -like '$taskMethods = @*') { $skip = $false; $out.Add($line) }
        continue
    }
    $out.Add($line)
}
Set-Content -Path build_v110_final_runtime.ps1 -Value $out -Encoding UTF8
.\build_v110_final_runtime.ps1

$src = Get-Content ProgramV110Build.cs -Raw -Encoding UTF8

# .NET 3.5 compatibility fixes in the generated branding code.
$src = $src.Replace('Environment.GetFolderPath(Environment.SpecialFolder.Windows)','Environment.GetEnvironmentVariable("WINDIR")')
$src = $src.Replace('g.FillEllipse(230,55,564,564);','g.FillEllipse(halo,230,55,564,564);')

# Initialize the EPOHA task strip as an overlay so it does not depend on legacy footer geometry.
$ctorOld = '            BuildChrome(); ApplyConfigToUi(); ShowGames();'
$ctorNew = '            BuildChrome(); InitClubTaskStrip(); ApplyConfigToUi(); ShowGames();'
if(-not $src.Contains($ctorOld)){ throw '1.1.0 final: constructor anchor missing' }
$src = $src.Replace($ctorOld,$ctorNew)

$init = @'
        private void InitClubTaskStrip()
        {
            if(clubTaskStrip!=null)return;
            clubTaskStrip=new FlowLayoutPanel();
            clubTaskStrip.Height=40;clubTaskStrip.Dock=DockStyle.Bottom;clubTaskStrip.WrapContents=false;clubTaskStrip.AutoScroll=true;
            clubTaskStrip.Padding=new Padding(8,4,8,2);clubTaskStrip.Margin=new Padding(0);clubTaskStrip.BackColor=Color.FromArgb(8,12,20);
            Controls.Add(clubTaskStrip);clubTaskStrip.BringToFront();
            clubWindowTimer=new System.Windows.Forms.Timer();clubWindowTimer.Interval=650;clubWindowTimer.Tick+=delegate{RefreshClubTaskStrip();};clubWindowTimer.Start();
            RefreshClubTaskStrip();
            Resize+=delegate{try{clubTaskStrip.BringToFront();}catch{}};
        }

'@
$anchor='        private void RefreshClubTaskStrip()'
if(-not $src.Contains($anchor)){ throw '1.1.0 final: task strip method anchor missing' }
$src=$src.Replace($anchor,$init+$anchor)

Set-Content -Path ProgramV110Build.cs -Value $src -Encoding UTF8
