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

$src = $src.Replace('Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Epoha", "watchdog.enabled")','Path.Combine(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Epoha"), "watchdog.enabled")')

if(-not $src.Contains('private void ExportConfig()')){
$helpers = @'
        private void ExportConfig()
        {
            try
            {
                using(SaveFileDialog d=new SaveFileDialog())
                {
                    d.Filter="EPOHA config|*.xml";d.FileName="epoha-config-PC"+cfg.PcNumber+".xml";
                    if(d.ShowDialog()!=DialogResult.OK)return;cfg.Save();File.Copy(Program.ConfigPath,d.FileName,true);
                    MessageBox.Show("Config exported.","EPOHA");
                }
            }
            catch(Exception ex){MessageBox.Show(ex.Message,"EPOHA",MessageBoxButtons.OK,MessageBoxIcon.Error);}
        }

        private void ImportConfig()
        {
            try
            {
                using(OpenFileDialog d=new OpenFileDialog())
                {
                    d.Filter="EPOHA config|*.xml|All files|*.*";if(d.ShowDialog()!=DialogResult.OK)return;
                    File.Copy(d.FileName,Program.ConfigPath,true);MessageBox.Show("Config imported. Shell will restart.","EPOHA");RestartShell();
                }
            }
            catch(Exception ex){MessageBox.Show(ex.Message,"EPOHA",MessageBoxButtons.OK,MessageBoxIcon.Error);}
        }

'@
    $src = $src.Replace('        private string InputBox', $helpers + '        private string InputBox')
}

Set-Content -Path ProgramV100Build.cs -Value $src -Encoding UTF8
