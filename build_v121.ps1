$ErrorActionPreference = "Stop"

.\build_v120.ps1
$src = Get-Content ProgramV120Build.cs -Raw -Encoding UTF8
$src = $src.Replace('1.2.0','1.2.1')

function Replace-One([string]$pattern,[string]$replacement,[string]$name) {
    $rx = New-Object System.Text.RegularExpressions.Regex($pattern,[System.Text.RegularExpressions.RegexOptions]::Singleline)
    $newSrc = $rx.Replace($script:src,$replacement,1)
    if($newSrc -eq $script:src){ throw ("1.2.1 patch failed: " + $name) }
    $script:src = $newSrc
}

# Rebuild the kiosk action with ASCII-only C# source. All Russian text is encoded as \uXXXX
# so the legacy .NET 3.5 compiler cannot reinterpret UTF-8 as Windows-1251/1252.
$applyMethod = @'
        private void ApplyWindowsBranding()
        {
            try
            {
                string image=CreateWindowsBrandingImage();
                ProcessStartInfo brand=new ProcessStartInfo(Application.ExecutablePath,"--apply-branding \""+image+"\"");
                brand.UseShellExecute=true;brand.Verb="runas";Process bp=Process.Start(brand);if(bp!=null)bp.WaitForExit();

                string report=Path.Combine(Program.AppDir,"kiosk-status.txt");try{if(File.Exists(report))File.Delete(report);}catch{}
                ProcessStartInfo kiosk=new ProcessStartInfo(Application.ExecutablePath,"--apply-kiosk");
                kiosk.UseShellExecute=true;kiosk.Verb="runas";Process kp=Process.Start(kiosk);if(kp!=null)kp.WaitForExit();
                if(!File.Exists(report))
                {
                    MessageBox.Show("\u0421\u0438\u0441\u0442\u0435\u043C\u043D\u044B\u0439 kiosk-\u0440\u0435\u0436\u0438\u043C \u043D\u0435 \u0431\u044B\u043B \u043F\u0440\u0438\u043C\u0435\u043D\u0451\u043D. \u041F\u0440\u043E\u0432\u0435\u0440\u044C\u0442\u0435 \u0437\u0430\u043F\u0440\u043E\u0441 UAC \u0438 \u0436\u0443\u0440\u043D\u0430\u043B \u042D\u041F\u041E\u0425\u0418.","\u042D\u041F\u041E\u0425\u0410",MessageBoxButtons.OK,MessageBoxIcon.Error);return;
                }
                string text=File.ReadAllText(report);
                if(text.IndexOf("LOCKDOWN=FULL\r",StringComparison.OrdinalIgnoreCase)>=0||text.IndexOf("LOCKDOWN=FULL\n",StringComparison.OrdinalIgnoreCase)>=0)
                    MessageBox.Show("\u0421\u0438\u0441\u0442\u0435\u043C\u043D\u044B\u0439 kiosk-\u0440\u0435\u0436\u0438\u043C \u043D\u0430\u0441\u0442\u0440\u043E\u0435\u043D \u043F\u043E\u043B\u043D\u043E\u0441\u0442\u044C\u044E. Custom Logon \u0430\u043A\u0442\u0438\u0432\u0438\u0440\u043E\u0432\u0430\u043D, Ctrl+Alt+Del \u043F\u0435\u0440\u0435\u0434\u0430\u043D \u0441\u0438\u0441\u0442\u0435\u043C\u043D\u043E\u043C\u0443 Keyboard Filter. \u041F\u0435\u0440\u0435\u0437\u0430\u0433\u0440\u0443\u0437\u0438\u0442\u0435 \u043A\u043E\u043C\u043F\u044C\u044E\u0442\u0435\u0440.","\u042D\u041F\u041E\u0425\u0410",MessageBoxButtons.OK,MessageBoxIcon.Information);
                else if(text.IndexOf("LOCKDOWN=FULL_PENDING_REBOOT",StringComparison.OrdinalIgnoreCase)>=0)
                    MessageBox.Show("\u041A\u043E\u043C\u043F\u043E\u043D\u0435\u043D\u0442\u044B Device Lockdown \u0432\u043A\u043B\u044E\u0447\u0435\u043D\u044B. \u0421\u0435\u0439\u0447\u0430\u0441 \u043D\u0443\u0436\u043D\u0430 \u043F\u0435\u0440\u0435\u0437\u0430\u0433\u0440\u0443\u0437\u043A\u0430. \u041F\u043E\u0441\u043B\u0435 \u043F\u0435\u0440\u0435\u0437\u0430\u0433\u0440\u0443\u0437\u043A\u0438 \u043E\u0434\u0438\u043D \u0440\u0430\u0437 \u0441\u043D\u043E\u0432\u0430 \u043D\u0430\u0436\u043C\u0438\u0442\u0435 \u044D\u0442\u0443 \u043A\u043D\u043E\u043F\u043A\u0443 \u2014 \u042D\u041F\u041E\u0425\u0410 \u0432\u043A\u043B\u044E\u0447\u0438\u0442 \u0441\u0438\u0441\u0442\u0435\u043C\u043D\u0443\u044E \u0444\u0438\u043B\u044C\u0442\u0440\u0430\u0446\u0438\u044E Ctrl+Alt+Del.","\u042D\u041F\u041E\u0425\u0410",MessageBoxButtons.OK,MessageBoxIcon.Information);
                else if(text.IndexOf("LOCKDOWN=LIMITED",StringComparison.OrdinalIgnoreCase)>=0)
                    MessageBox.Show("\u0414\u043B\u044F \u044D\u0442\u043E\u0439 \u0440\u0435\u0434\u0430\u043A\u0446\u0438\u0438 Windows \u043F\u0440\u0438\u043C\u0435\u043D\u0435\u043D\u043E \u0432\u0441\u0451 \u0434\u043E\u0441\u0442\u0443\u043F\u043D\u043E\u0435: \u0441\u043A\u0440\u044B\u0442\u044B \u0441\u0438\u0441\u0442\u0435\u043C\u043D\u044B\u0435 \u0441\u0442\u0430\u0442\u0443\u0441\u043D\u044B\u0435 \u0441\u043E\u043E\u0431\u0449\u0435\u043D\u0438\u044F \u0438 \u0432\u043A\u043B\u044E\u0447\u0435\u043D\u044B \u043E\u0431\u044B\u0447\u043D\u044B\u0435 \u043F\u043E\u043B\u0438\u0442\u0438\u043A\u0438 \u043A\u043B\u0443\u0431\u0430. \u041D\u043E \u0432 \u0441\u0438\u0441\u0442\u0435\u043C\u0435 \u043D\u0435\u0442 \u043E\u0434\u043D\u043E\u0432\u0440\u0435\u043C\u0435\u043D\u043D\u043E Custom Logon \u0438 Keyboard Filter, \u043F\u043E\u044D\u0442\u043E\u043C\u0443 \u043F\u043E\u043B\u043D\u043E\u0441\u0442\u044C\u044E \u0443\u0431\u0440\u0430\u0442\u044C \u0437\u0430\u0449\u0438\u0449\u0451\u043D\u043D\u044B\u0439 Ctrl+Alt+Del \u043D\u0435\u0432\u043E\u0437\u043C\u043E\u0436\u043D\u043E. \u0414\u043B\u044F \u043F\u043E\u043B\u043D\u043E\u0433\u043E \u0440\u0435\u0436\u0438\u043C\u0430 \u043D\u0443\u0436\u043D\u0430 \u0440\u0435\u0434\u0430\u043A\u0446\u0438\u044F Windows \u0441 Device Lockdown.","\u042D\u041F\u041E\u0425\u0410",MessageBoxButtons.OK,MessageBoxIcon.Warning);
                else MessageBox.Show("\u0421\u0438\u0441\u0442\u0435\u043C\u043D\u044B\u0439 kiosk-\u0440\u0435\u0436\u0438\u043C \u0437\u0430\u0432\u0435\u0440\u0448\u0438\u043B\u0441\u044F \u0441 \u043E\u0448\u0438\u0431\u043A\u043E\u0439.\r\n\r\n"+text,"\u042D\u041F\u041E\u0425\u0410",MessageBoxButtons.OK,MessageBoxIcon.Error);
            }
            catch(Exception ex){MessageBox.Show("\u041D\u0435 \u0443\u0434\u0430\u043B\u043E\u0441\u044C \u043F\u0440\u0438\u043C\u0435\u043D\u0438\u0442\u044C \u0441\u0438\u0441\u0442\u0435\u043C\u043D\u044B\u0439 kiosk-\u0440\u0435\u0436\u0438\u043C.\r\n\r\n"+ex.Message,"\u042D\u041F\u041E\u0425\u0410",MessageBoxButtons.OK,MessageBoxIcon.Error);}
        }

        private void BeginPowerTransition
'@
Replace-One '        private void ApplyWindowsBranding\(\).*?        private void BeginPowerTransition' $applyMethod 'ASCII-safe kiosk messages'

# Replace the button caption structurally so no Cyrillic literal from 1.2.0 survives into the compiler input.
$src = [regex]::Replace($src,'ActionButton\(p,"[^"]*",434,664,260,38,delegate\{ApplyWindowsBranding\(\);\}\);','ActionButton(p,"\u0421\u0418\u0421\u0422\u0415\u041C\u041D\u042B\u0419 KIOSK-\u0420\u0415\u0416\u0418\u041C",434,664,260,38,delegate{ApplyWindowsBranding();});',1)

Set-Content -Path ProgramV121Build.cs -Value $src -Encoding UTF8
