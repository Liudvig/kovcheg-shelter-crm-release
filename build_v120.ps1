$ErrorActionPreference = "Stop"

.\build_v111.ps1
$src = Get-Content ProgramV111Build.cs -Raw -Encoding UTF8
$src = $src.Replace('1.1.1','1.2.0')

function Replace-One([string]$pattern,[string]$replacement,[string]$name) {
    $rx = New-Object System.Text.RegularExpressions.Regex($pattern,[System.Text.RegularExpressions.RegexOptions]::Singleline)
    $newSrc = $rx.Replace($script:src,$replacement,1)
    if($newSrc -eq $script:src){ throw ("1.2.0 patch failed: " + $name) }
    $script:src = $newSrc
}

function Replace-Exact([string]$old,[string]$replacement,[string]$name) {
    if(-not $script:src.Contains($old)){ throw ("1.2.0 target missing: " + $name) }
    $script:src = $script:src.Replace($old,$replacement)
}

# Elevated kiosk helper runs before the normal single-instance/watchdog path.
$argOld = @'
            if(args!=null&&args.Length>0&&String.Equals(args[0],"--apply-branding",StringComparison.OrdinalIgnoreCase))
            {
                ApplyWindowsBrandingFromArgs(args);return;
            }
'@
$argNew = @'
            if(args!=null&&args.Length>0&&String.Equals(args[0],"--apply-kiosk",StringComparison.OrdinalIgnoreCase))
            {
                ApplySystemKioskFromArgs(args);return;
            }
            if(args!=null&&args.Length>0&&String.Equals(args[0],"--apply-branding",StringComparison.OrdinalIgnoreCase))
            {
                ApplyWindowsBrandingFromArgs(args);return;
            }
'@
Replace-Exact $argOld $argNew 'kiosk argument handler'

$kioskProgram = @'
        private static string RunSystemTool(string fileName,string arguments)
        {
            ProcessStartInfo psi=new ProcessStartInfo(fileName,arguments);
            psi.UseShellExecute=false;psi.CreateNoWindow=true;psi.RedirectStandardOutput=true;psi.RedirectStandardError=true;
            Process p=Process.Start(psi);if(p==null)throw new Exception("Cannot start "+fileName);
            string so=p.StandardOutput.ReadToEnd();string se=p.StandardError.ReadToEnd();p.WaitForExit();
            return "EXIT="+p.ExitCode.ToString()+"\r\n"+so+"\r\n"+se;
        }

        private static void ApplySystemKioskFromArgs(string[] args)
        {
            string report=Path.Combine(AppDir,"kiosk-status.txt");
            StringBuilder log=new StringBuilder();bool full=false;bool customLogon=false;bool keyboardFilter=false;bool keyboardConfigured=false;bool reboot=false;
            try
            {
                using(RegistryKey k=Registry.LocalMachine.CreateSubKey(@"SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"))
                {
                    k.SetValue("DisableStatusMessages",1,RegistryValueKind.DWord);
                    k.SetValue("HideFastUserSwitching",1,RegistryValueKind.DWord);
                }
                using(RegistryKey k=Registry.LocalMachine.CreateSubKey(@"SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"))k.SetValue("UIVerbosityLevel",1,RegistryValueKind.DWord);
                using(RegistryKey k=Registry.LocalMachine.CreateSubKey(@"SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI"))k.SetValue("AnimationDisabled",1,RegistryValueKind.DWord);
                using(RegistryKey k=Registry.LocalMachine.CreateSubKey(@"SOFTWARE\Policies\Microsoft\Windows\Personalization"))k.SetValue("NoLockScreen",1,RegistryValueKind.DWord);
                using(RegistryKey k=Registry.LocalMachine.CreateSubKey(@"SOFTWARE\Microsoft\Windows Embedded\EmbeddedLogon"))
                {
                    k.SetValue("BrandingNeutral",17,RegistryValueKind.DWord);
                    k.SetValue("HideAutoLogonUI",1,RegistryValueKind.DWord);
                    k.SetValue("HideFirstLogonAnimation",1,RegistryValueKind.DWord);
                }
                log.AppendLine("STATUS_MESSAGES=HIDDEN");

                string features=RunSystemTool("dism.exe","/online /Get-Features /Format:Table");
                bool hasDevice=features.IndexOf("Client-DeviceLockdown",StringComparison.OrdinalIgnoreCase)>=0;
                bool hasLogon=features.IndexOf("Client-EmbeddedLogon",StringComparison.OrdinalIgnoreCase)>=0;
                bool hasKeyboard=features.IndexOf("Client-KeyboardFilter",StringComparison.OrdinalIgnoreCase)>=0;
                log.AppendLine("FEATURE_DEVICE_LOCKDOWN="+(hasDevice?"1":"0"));
                log.AppendLine("FEATURE_CUSTOM_LOGON="+(hasLogon?"1":"0"));
                log.AppendLine("FEATURE_KEYBOARD_FILTER="+(hasKeyboard?"1":"0"));

                if(hasDevice){RunSystemTool("dism.exe","/online /Enable-Feature /FeatureName:Client-DeviceLockdown /NoRestart");reboot=true;}
                if(hasLogon){string r=RunSystemTool("dism.exe","/online /Enable-Feature /FeatureName:Client-EmbeddedLogon /NoRestart");customLogon=r.IndexOf("EXIT=0",StringComparison.OrdinalIgnoreCase)>=0;reboot=true;}
                if(hasKeyboard){string r=RunSystemTool("dism.exe","/online /Enable-Feature /FeatureName:Client-KeyboardFilter /NoRestart");keyboardFilter=r.IndexOf("EXIT=0",StringComparison.OrdinalIgnoreCase)>=0;reboot=true;}

                if(hasKeyboard)
                {
                    try
                    {
                        string ps=Path.Combine(AppDir,"epoha-keyboard-filter.ps1");
                        string body="$ErrorActionPreference='Stop'\r\n"+
                            "$ns='root\\standardcimv2\\embedded'\r\n"+
                            "$r=Get-WmiObject -Namespace $ns -Class WEKF_PredefinedKey | Where-Object { $_.Id -eq 'Ctrl+Alt+Del' }\r\n"+
                            "if($r){$r.Enabled=$true;$r.Put()|Out-Null}else{throw 'Ctrl+Alt+Del predefined rule not found'}\r\n"+
                            "$s=Get-WmiObject -Namespace $ns -Class WEKF_Settings | Where-Object { $_.Name -eq 'DisableKeyboardFilterForAdministrators' }\r\n"+
                            "if($s){$s.Enabled=$true;$s.Put()|Out-Null}\r\n";
                        File.WriteAllText(ps,body,Encoding.ASCII);
                        string pr=RunSystemTool("powershell.exe","-NoProfile -ExecutionPolicy Bypass -File \""+ps+"\"");
                        keyboardConfigured=pr.IndexOf("EXIT=0",StringComparison.OrdinalIgnoreCase)>=0;
                    }
                    catch(Exception ex){log.AppendLine("KEYBOARD_FILTER_ERROR="+ex.Message.Replace('\r',' ').Replace('\n',' '));}
                }

                full=hasLogon&&hasKeyboard;
                log.AppendLine("CUSTOM_LOGON_ENABLED="+(customLogon?"1":"0"));
                log.AppendLine("KEYBOARD_FILTER_ENABLED="+(keyboardFilter?"1":"0"));
                log.AppendLine("CTRL_ALT_DEL_FILTER="+(keyboardConfigured?"1":"0"));
                log.AppendLine("REBOOT_REQUIRED="+(reboot?"1":"0"));
                log.AppendLine("LOCKDOWN="+(full?(keyboardConfigured?"FULL":"FULL_PENDING_REBOOT"):"LIMITED"));
                if(!full)log.AppendLine("DETAIL=This Windows edition does not expose both Custom Logon and Keyboard Filter Device Lockdown features.");
                else if(!keyboardConfigured)log.AppendLine("DETAIL=Device Lockdown features were enabled. Reboot, then run System Kiosk setup once more to configure Ctrl+Alt+Del filtering.");
                else log.AppendLine("DETAIL=System kiosk lockdown configured.");
                File.WriteAllText(report,log.ToString(),Encoding.UTF8);
            }
            catch(Exception ex)
            {
                log.AppendLine("LOCKDOWN=ERROR");log.AppendLine("ERROR="+ex.ToString());
                try{File.WriteAllText(report,log.ToString(),Encoding.UTF8);}catch{}
                try{File.AppendAllText(LogPath,"System kiosk: "+ex+"\r\n");}catch{}
            }
        }

'@
Replace-Exact '        private static void ApplyWindowsBrandingFromArgs' ($kioskProgram+'        private static void ApplyWindowsBrandingFromArgs') 'system kiosk elevated helper'

# Existing system-branding button becomes the one-shot system kiosk preparation action.
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
                if(!File.Exists(report)){MessageBox.Show("Системный kiosk-режим не был применён. Проверьте запрос UAC и журнал ЭПОХИ.","ЭПОХА",MessageBoxButtons.OK,MessageBoxIcon.Error);return;}
                string text=File.ReadAllText(report);
                if(text.IndexOf("LOCKDOWN=FULL\r",StringComparison.OrdinalIgnoreCase)>=0||text.IndexOf("LOCKDOWN=FULL\n",StringComparison.OrdinalIgnoreCase)>=0)
                    MessageBox.Show("Системный kiosk-режим настроен полностью. Custom Logon активирован, Ctrl+Alt+Del передан системному Keyboard Filter. Перезагрузите компьютер.","ЭПОХА",MessageBoxButtons.OK,MessageBoxIcon.Information);
                else if(text.IndexOf("LOCKDOWN=FULL_PENDING_REBOOT",StringComparison.OrdinalIgnoreCase)>=0)
                    MessageBox.Show("Компоненты Device Lockdown включены. Сейчас нужна перезагрузка. После перезагрузки один раз снова нажмите эту кнопку — ЭПОХА включит системную фильтрацию Ctrl+Alt+Del.","ЭПОХА",MessageBoxButtons.OK,MessageBoxIcon.Information);
                else if(text.IndexOf("LOCKDOWN=LIMITED",StringComparison.OrdinalIgnoreCase)>=0)
                    MessageBox.Show("Для этой редакции Windows применено всё доступное: скрыты системные статусные сообщения и включены обычные политики клуба. Но в системе нет одновременно Custom Logon и Keyboard Filter, поэтому полностью убрать защищённый Ctrl+Alt+Del невозможно. Для полного режима нужна редакция Windows с Device Lockdown.","ЭПОХА",MessageBoxButtons.OK,MessageBoxIcon.Warning);
                else MessageBox.Show("Системный kiosk-режим завершился с ошибкой.\r\n\r\n"+text,"ЭПОХА",MessageBoxButtons.OK,MessageBoxIcon.Error);
            }
            catch(Exception ex){MessageBox.Show("Не удалось применить системный kiosk-режим.\r\n\r\n"+ex.Message,"ЭПОХА",MessageBoxButtons.OK,MessageBoxIcon.Error);}
        }

        private void BeginPowerTransition
'@
Replace-One '        private void ApplyWindowsBranding\(\).*?        private void BeginPowerTransition' $applyMethod 'system kiosk main action'

# Rename the service action without adding another setting or button.
$src = [regex]::Replace($src,'ActionButton\(p,"[^"]*",434,664,260,38,delegate\{ApplyWindowsBranding\(\);\}\);','ActionButton(p,"СИСТЕМНЫЙ KIOSK-РЕЖИМ",434,664,260,38,delegate{ApplyWindowsBranding();});',1)

Set-Content -Path ProgramV120Build.cs -Value $src -Encoding UTF8
