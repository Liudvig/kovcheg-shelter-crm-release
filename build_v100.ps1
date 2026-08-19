$ErrorActionPreference = "Stop"

.\build_v090.ps1
$src = Get-Content ProgramV090Build.cs -Raw -Encoding UTF8
$src = $src.Replace('0.9.0','1.0.0')

function Replace-One([string]$pattern,[string]$replacement,[string]$name) {
    $rx = New-Object System.Text.RegularExpressions.Regex($pattern,[System.Text.RegularExpressions.RegexOptions]::Singleline)
    $newSrc = $rx.Replace($script:src,$replacement,1)
    if($newSrc -eq $script:src){ throw ("1.0.0 patch failed: " + $name) }
    $script:src = $newSrc
}

# Persistent club-runtime options.
$src = $src.Replace('        public bool ClubModeEnabled = false;','        public bool ClubModeEnabled = false;`r`n        public bool WatchdogEnabled = true;`r`n        public bool ReplaceExplorerShell = false;')
$src = $src.Replace('                c.ClubModeEnabled = BoolAttr(root, "clubModeEnabled", false);','                c.ClubModeEnabled = BoolAttr(root, "clubModeEnabled", false);`r`n                c.WatchdogEnabled = BoolAttr(root, "watchdogEnabled", true);`r`n                c.ReplaceExplorerShell = BoolAttr(root, "replaceExplorerShell", false);')
$src = $src.Replace('            root.SetAttribute("closeExplorerInClubMode", CloseExplorerInClubMode.ToString()); root.SetAttribute("clubModeEnabled", ClubModeEnabled.ToString());','            root.SetAttribute("closeExplorerInClubMode", CloseExplorerInClubMode.ToString()); root.SetAttribute("clubModeEnabled", ClubModeEnabled.ToString());`r`n            root.SetAttribute("watchdogEnabled", WatchdogEnabled.ToString()); root.SetAttribute("replaceExplorerShell", ReplaceExplorerShell.ToString());')

# Program: watchdog mode and single-instance guard.
$src = $src.Replace('        public static string LogPath = Path.Combine(Path.GetTempPath(), "EpohaShell-1.0.0.log");','        public static string LogPath = Path.Combine(Path.GetTempPath(), "EpohaShell-1.0.0.log");`r`n        public static string WatchdogMarkerPath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Epoha", "watchdog.enabled");')
if(-not $src.Contains('WatchdogMarkerPath')) {
    $src = $src.Replace('        public static string LogPath = Path.Combine(Path.GetTempPath(), "EpohaShell-0.4.1.log");','        public static string LogPath = Path.Combine(Path.GetTempPath(), "EpohaShell-1.0.0.log");`r`n        public static string WatchdogMarkerPath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Epoha", "watchdog.enabled");')
}

$mainReplacement = @'
        [STAThread]
        public static void Main(string[] args)
        {
            if(args!=null&&args.Length>0&&String.Equals(args[0],"--watchdog",StringComparison.OrdinalIgnoreCase))
            {
                RunWatchdog(args);return;
            }
            bool created=true;
            try
            {
                bool newOne=false;new System.Threading.Mutex(true,"Local\\EpohaShell.Main",out newOne);created=newOne;
            }
            catch{}
            if(!created)return;
'@
Replace-One '        \[STAThread\]\s*public static void Main\(\)\s*\{' $mainReplacement 'Program.Main'

$watchdogMethod = @'
        private static void RunWatchdog(string[] args)
        {
            try
            {
                int pid=0;if(args.Length<2||!Int32.TryParse(args[1],out pid))return;
                try{Process p=Process.GetProcessById(pid);p.WaitForExit();}catch{}
                System.Threading.Thread.Sleep(1200);
                if(!File.Exists(WatchdogMarkerPath))return;
                string exe=Application.ExecutablePath;
                for(int attempt=0;attempt<4&&File.Exists(WatchdogMarkerPath);attempt++)
                {
                    try
                    {
                        Process n=Process.Start(exe);
                        if(n==null)return;
                        if(!n.WaitForExit(5000))return;
                    }
                    catch(Exception ex){try{File.AppendAllText(LogPath,"Watchdog restart: "+ex+"\r\n");}catch{}}
                    System.Threading.Thread.Sleep(1200);
                }
            }
            catch(Exception ex){try{File.AppendAllText(LogPath,"Watchdog: "+ex+"\r\n");}catch{}}
        }

'@
$src = $src.Replace('        private static void Fatal(string where, Exception ex)', $watchdogMethod + '        private static void Fatal(string where, Exception ex)')

# MainForm watchdog state.
$src = $src.Replace('        private IntPtr keyboardHook = IntPtr.Zero;','        private IntPtr keyboardHook = IntPtr.Zero;`r`n        private bool watchdogStarted = false;')

# System admin page: keep the existing features, add the two runtime-critical controls only.
$systemPage = @'
        private void BuildAdminSystem(DbPanel p)
        {
            Title(p,"\u0421\u0438\u0441\u0442\u0435\u043C\u0430");
            CheckBox auto=new CheckBox();auto.Text="\u0417\u0430\u043F\u0443\u0441\u043A\u0430\u0442\u044C \u042D\u041F\u041E\u0425\u0423 \u043F\u0440\u0438 \u0432\u0445\u043E\u0434\u0435 Windows";auto.Checked=cfg.AutoStart;auto.SetBounds(30,78,480,25);p.Controls.Add(auto);
            CheckBox top=new CheckBox();top.Text="\u0414\u0435\u0440\u0436\u0430\u0442\u044C Shell \u043F\u043E\u0432\u0435\u0440\u0445 \u0434\u0440\u0443\u0433\u0438\u0445 \u043E\u043A\u043E\u043D";top.Checked=cfg.AlwaysOnTop;top.SetBounds(30,110,480,25);p.Controls.Add(top);
            CheckBox single=new CheckBox();single.Text="\u041D\u0435 \u0437\u0430\u043F\u0443\u0441\u043A\u0430\u0442\u044C \u0432\u0442\u043E\u0440\u0443\u044E \u0438\u0433\u0440\u0443, \u043F\u043E\u043A\u0430 \u043F\u0435\u0440\u0432\u0430\u044F \u0440\u0430\u0431\u043E\u0442\u0430\u0435\u0442";single.Checked=cfg.SingleGameMode;single.SetBounds(30,142,620,25);p.Controls.Add(single);
            CheckBox explorer=new CheckBox();explorer.Text="\u0417\u0430\u043F\u0443\u0441\u043A\u0430\u0442\u044C Explorer \u043F\u0440\u0438 \u0432\u044B\u0445\u043E\u0434\u0435 \u0438\u0437 Shell";explorer.Checked=cfg.StartExplorerOnShellExit;explorer.SetBounds(30,174,520,25);p.Controls.Add(explorer);
            CheckBox confirm=new CheckBox();confirm.Text="\u041F\u043E\u0434\u0442\u0432\u0435\u0440\u0436\u0434\u0430\u0442\u044C \u0432\u044B\u043A\u043B\u044E\u0447\u0435\u043D\u0438\u0435 \u0438 \u043F\u0435\u0440\u0435\u0437\u0430\u0433\u0440\u0443\u0437\u043A\u0443 \u041F\u041A";confirm.Checked=cfg.ConfirmPower;confirm.SetBounds(30,206,570,25);p.Controls.Add(confirm);
            CheckBox task=new CheckBox();task.Text="\u0411\u043B\u043E\u043A\u0438\u0440\u043E\u0432\u0430\u0442\u044C \u0414\u0438\u0441\u043F\u0435\u0442\u0447\u0435\u0440 \u0437\u0430\u0434\u0430\u0447 \u0438 \u043B\u0438\u0448\u043D\u0438\u0435 \u043F\u0443\u043D\u043A\u0442\u044B Ctrl+Alt+Del";task.Checked=cfg.BlockTaskManager;task.SetBounds(30,238,650,25);p.Controls.Add(task);
            CheckBox keys=new CheckBox();keys.Text="\u0411\u043B\u043E\u043A\u0438\u0440\u043E\u0432\u0430\u0442\u044C Win, Alt+Tab, Alt+Esc, Alt+F4 \u0432 \u043A\u043B\u0438\u0435\u043D\u0442\u0441\u043A\u043E\u043C \u0440\u0435\u0436\u0438\u043C\u0435";keys.Checked=cfg.BlockSystemKeys;keys.SetBounds(30,270,650,25);p.Controls.Add(keys);
            CheckBox closeExp=new CheckBox();closeExp.Text="\u0417\u0430\u043A\u0440\u044B\u0432\u0430\u0442\u044C Explorer \u043F\u0440\u0438 \u0432\u043A\u043B\u044E\u0447\u0435\u043D\u0438\u0438 \u043A\u043B\u0443\u0431\u043D\u043E\u0433\u043E \u0440\u0435\u0436\u0438\u043C\u0430";closeExp.Checked=cfg.CloseExplorerInClubMode;closeExp.SetBounds(30,302,610,25);p.Controls.Add(closeExp);
            CheckBox watchdog=new CheckBox();watchdog.Text="\u0410\u0432\u0442\u043E\u043C\u0430\u0442\u0438\u0447\u0435\u0441\u043A\u0438 \u0432\u043E\u0441\u0441\u0442\u0430\u043D\u0430\u0432\u043B\u0438\u0432\u0430\u0442\u044C Shell \u043F\u043E\u0441\u043B\u0435 \u0441\u0431\u043E\u044F";watchdog.Checked=cfg.WatchdogEnabled;watchdog.SetBounds(30,334,620,25);p.Controls.Add(watchdog);
            CheckBox shell=new CheckBox();shell.Text="\u0418\u0441\u043F\u043E\u043B\u044C\u0437\u043E\u0432\u0430\u0442\u044C \u042D\u041F\u041E\u0425\u0423 \u043A\u0430\u043A \u043E\u0431\u043E\u043B\u043E\u0447\u043A\u0443 Windows \u0432\u043C\u0435\u0441\u0442\u043E Explorer";shell.Checked=cfg.ReplaceExplorerShell;shell.SetBounds(30,366,650,25);p.Controls.Add(shell);
            ActionButton(p,"\u0421\u041E\u0425\u0420\u0410\u041D\u0418\u0422\u042C",30,406,145,36,delegate{cfg.AutoStart=auto.Checked;cfg.AlwaysOnTop=top.Checked;cfg.SingleGameMode=single.Checked;cfg.StartExplorerOnShellExit=explorer.Checked;cfg.ConfirmPower=confirm.Checked;cfg.BlockTaskManager=task.Checked;cfg.BlockSystemKeys=keys.Checked;cfg.CloseExplorerInClubMode=closeExp.Checked;cfg.WatchdogEnabled=watchdog.Checked;cfg.ReplaceExplorerShell=shell.Checked;cfg.Save();ApplyConfigToUi();MessageBox.Show("\u041D\u0430\u0441\u0442\u0440\u043E\u0439\u043A\u0438 \u0441\u043E\u0445\u0440\u0430\u043D\u0435\u043D\u044B.","\u042D\u041F\u041E\u0425\u0410");});

            Label club=new Label();club.Text="\u041A\u041B\u0423\u0411\u041D\u042B\u0419 \u0420\u0415\u0416\u0418\u041C";club.SetBounds(30,466,350,28);club.Font=F(11,FontStyle.Bold);club.ForeColor=Accent;club.BackColor=Color.Transparent;p.Controls.Add(club);
            Label state=new Label();state.Text=cfg.ClubModeEnabled?"\u0421\u0422\u0410\u0422\u0423\u0421: \u0412\u041A\u041B\u042E\u0427\u0415\u041D":"\u0421\u0422\u0410\u0422\u0423\u0421: \u0412\u042B\u041A\u041B\u042E\u0427\u0415\u041D";state.SetBounds(350,470,300,24);state.Font=F(9,FontStyle.Bold);state.ForeColor=cfg.ClubModeEnabled?Color.FromArgb(126,235,165):Color.FromArgb(210,185,120);state.BackColor=Color.Transparent;p.Controls.Add(state);
            ActionButton(p,"\u0412\u041A\u041B\u042E\u0427\u0418\u0422\u042C \u041A\u041B\u0423\u0411\u041D\u042B\u0419 \u0420\u0415\u0416\u0418\u041C",30,504,230,40,delegate{SetClubMode(true);ShowAdmin("\u0421\u0438\u0441\u0442\u0435\u043C\u0430");});
            ActionButton(p,"\u0412\u042B\u041A\u041B\u042E\u0427\u0418\u0422\u042C \u041A\u041B\u0423\u0411\u041D\u042B\u0419 \u0420\u0415\u0416\u0418\u041C",272,504,240,40,delegate{SetClubMode(false);ShowAdmin("\u0421\u0438\u0441\u0442\u0435\u043C\u0430");});

            Label service=new Label();service.Text="\u041E\u0411\u0421\u041B\u0423\u0416\u0418\u0412\u0410\u041D\u0418\u0415";service.SetBounds(30,574,350,28);service.Font=F(11,FontStyle.Bold);service.ForeColor=Accent;service.BackColor=Color.Transparent;p.Controls.Add(service);
            ActionButton(p,"\u0412\u042B\u041A\u041B\u042E\u0427\u0418\u0422\u042C SHELL",30,610,180,40,delegate{ExitShellToExplorer();});ActionButton(p,"\u041E\u0422\u041A\u0420\u042B\u0422\u042C EXPLORER",222,610,180,40,delegate{OpenExplorer();});ActionButton(p,"\u041F\u0415\u0420\u0415\u0417\u0410\u041F\u0423\u0421\u0422\u0418\u0422\u042C SHELL",414,610,205,40,delegate{RestartShell();});
            ActionButton(p,"\u042D\u041A\u0421\u041F\u041E\u0420\u0422 \u041D\u0410\u0421\u0422\u0420\u041E\u0415\u041A",30,664,190,38,delegate{ExportConfig();});ActionButton(p,"\u0418\u041C\u041F\u041E\u0420\u0422 \u041D\u0410\u0421\u0422\u0420\u041E\u0415\u041A",232,664,190,38,delegate{ImportConfig();});
            Label info=new Label();info.Text="Ctrl + Alt + E — \u0430\u0432\u0430\u0440\u0438\u0439\u043D\u044B\u0439 \u0432\u0445\u043E\u0434 \u0430\u0434\u043C\u0438\u043D\u0438\u0441\u0442\u0440\u0430\u0442\u043E\u0440\u0430. Ctrl+Alt+Del \u043E\u0441\u0442\u0430\u0451\u0442\u0441\u044F \u0437\u0430\u0449\u0438\u0449\u0451\u043D\u043D\u043E\u0439 \u043A\u043E\u043C\u0431\u0438\u043D\u0430\u0446\u0438\u0435\u0439 Windows.";info.SetBounds(30,718,820,50);info.ForeColor=Color.FromArgb(180,194,216);info.BackColor=Color.Transparent;p.Controls.Add(info);
        }

        private string InputBox
'@
Replace-One '        private void BuildAdminSystem\(DbPanel p\).*?        private string InputBox' $systemPage 'BuildAdminSystem'

# Full club-mode runtime. The watchdog is the same EXE in a hidden argument mode.
$clubRuntime = @'
        private void SetClubMode(bool enabled)
        {
            if(enabled&&MessageBox.Show("\u0412\u043A\u043B\u044E\u0447\u0438\u0442\u044C \u043A\u043B\u0443\u0431\u043D\u044B\u0439 \u0440\u0435\u0436\u0438\u043C?", "\u042D\u041F\u041E\u0425\u0410",MessageBoxButtons.YesNo,MessageBoxIcon.Question)!=DialogResult.Yes)return;
            cfg.ClubModeEnabled=enabled;cfg.Save();ApplyClubMode();
            if(!enabled)OpenExplorer();
        }

        private void ApplyClubMode()
        {
            try
            {
                ThemeWallpaper.HeaderTransparency=cfg.HeaderTransparency;
                SetTaskManagerPolicy(cfg.ClubModeEnabled&&cfg.BlockTaskManager);
                SetKeyboardHook(cfg.ClubModeEnabled&&cfg.BlockSystemKeys);
                ApplyUserShell(cfg.ClubModeEnabled&&cfg.ReplaceExplorerShell);
                ApplyWatchdog(cfg.ClubModeEnabled&&cfg.WatchdogEnabled);
                if(cfg.ClubModeEnabled&&cfg.CloseExplorerInClubMode)CloseExplorer();
            }
            catch(Exception ex){File.AppendAllText(Program.LogPath,"ClubMode: "+ex+"\r\n");}
        }

        private void ApplyWatchdog(bool enabled)
        {
            try
            {
                string dir=Path.GetDirectoryName(Program.WatchdogMarkerPath);if(!Directory.Exists(dir))Directory.CreateDirectory(dir);
                if(enabled)
                {
                    File.WriteAllText(Program.WatchdogMarkerPath,Application.ExecutablePath);
                    if(!watchdogStarted)
                    {
                        ProcessStartInfo pi=new ProcessStartInfo(Application.ExecutablePath,"--watchdog "+Process.GetCurrentProcess().Id.ToString());pi.UseShellExecute=false;pi.CreateNoWindow=true;Process.Start(pi);watchdogStarted=true;
                    }
                }
                else{if(File.Exists(Program.WatchdogMarkerPath))File.Delete(Program.WatchdogMarkerPath);}
            }
            catch(Exception ex){File.AppendAllText(Program.LogPath,"Watchdog config: "+ex+"\r\n");}
        }

        private void ApplyUserShell(bool enabled)
        {
            const string winlogon=@"Software\Microsoft\Windows NT\CurrentVersion\Winlogon";const string own=@"Software\Epoha";
            using(RegistryKey state=Registry.CurrentUser.CreateSubKey(own))using(RegistryKey wk=Registry.CurrentUser.CreateSubKey(winlogon))
            {
                if(enabled)
                {
                    if(Convert.ToInt32(state.GetValue("ShellBackupSaved",0))==0)
                    {
                        object old=wk.GetValue("Shell",null);state.SetValue("ShellBackupSaved",1,RegistryValueKind.DWord);
                        if(old==null)state.SetValue("ShellBackupEmpty",1,RegistryValueKind.DWord);else state.SetValue("ShellBackup",old.ToString(),RegistryValueKind.String);
                    }
                    wk.SetValue("Shell",Application.ExecutablePath,RegistryValueKind.String);
                }
                else
                {
                    if(Convert.ToInt32(state.GetValue("ShellBackupSaved",0))!=0)
                    {
                        if(Convert.ToInt32(state.GetValue("ShellBackupEmpty",0))!=0)wk.DeleteValue("Shell",false);
                        else{object old=state.GetValue("ShellBackup",null);if(old!=null)wk.SetValue("Shell",old.ToString(),RegistryValueKind.String);}
                        state.DeleteValue("ShellBackupSaved",false);state.DeleteValue("ShellBackupEmpty",false);state.DeleteValue("ShellBackup",false);
                    }
                    else
                    {
                        object cur=wk.GetValue("Shell",null);if(cur!=null&&String.Equals(cur.ToString(),Application.ExecutablePath,StringComparison.OrdinalIgnoreCase))wk.DeleteValue("Shell",false);
                    }
                }
            }
        }

        private void SetTaskManagerPolicy(bool enabled)
        {
            using(RegistryKey k=Registry.CurrentUser.CreateSubKey(@"Software\Microsoft\Windows\CurrentVersion\Policies\System"))
            {
                if(enabled){k.SetValue("DisableTaskMgr",1,RegistryValueKind.DWord);k.SetValue("DisableLockWorkstation",1,RegistryValueKind.DWord);k.SetValue("DisableChangePassword",1,RegistryValueKind.DWord);}else{k.DeleteValue("DisableTaskMgr",false);k.DeleteValue("DisableLockWorkstation",false);k.DeleteValue("DisableChangePassword",false);}
            }
            using(RegistryKey e=Registry.CurrentUser.CreateSubKey(@"Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"))
            {
                if(enabled)e.SetValue("NoLogoff",1,RegistryValueKind.DWord);else e.DeleteValue("NoLogoff",false);
            }
        }

        private void SetKeyboardHook(bool enabled)
        {
            if(enabled&&keyboardHook==IntPtr.Zero){keyboardProc=new LowLevelKeyboardProc(KeyboardHookCallback);keyboardHook=SetWindowsHookEx(WH_KEYBOARD_LL,keyboardProc,GetModuleHandle(null),0);}
            else if(!enabled&&keyboardHook!=IntPtr.Zero){UnhookWindowsHookEx(keyboardHook);keyboardHook=IntPtr.Zero;keyboardProc=null;}
        }

        private IntPtr KeyboardHookCallback(int nCode,IntPtr wParam,IntPtr lParam)
        {
            if(nCode>=0&&cfg.ClubModeEnabled&&cfg.BlockSystemKeys&&!adminMode)
            {
                int vk=System.Runtime.InteropServices.Marshal.ReadInt32(lParam);bool alt=(Control.ModifierKeys&Keys.Alt)==Keys.Alt;bool ctrl=(Control.ModifierKeys&Keys.Control)==Keys.Control;
                if(vk==(int)Keys.LWin||vk==(int)Keys.RWin||(alt&&vk==(int)Keys.Tab)||(alt&&vk==(int)Keys.Escape)||(alt&&vk==(int)Keys.F4)||(ctrl&&vk==(int)Keys.Escape))return (IntPtr)1;
            }
            return CallNextHookEx(keyboardHook,nCode,wParam,lParam);
        }

        private void CloseExplorer()
        {
            try{Process[] ps=Process.GetProcessesByName("explorer");foreach(Process p in ps){try{p.Kill();}catch{}}}catch{}
        }

'@
Replace-One '        private void SetClubMode\(bool enabled\).*?(?=        private void OpenExplorer\(\))' $clubRuntime 'club runtime'

# Exit to maintenance must restore policies, user shell and watchdog before closing.
$exitMethod = @'
        private void ExitShellToExplorer()
        {
            if(MessageBox.Show("\u0412\u044B\u043A\u043B\u044E\u0447\u0438\u0442\u044C Shell \u0438 \u043F\u0435\u0440\u0435\u0439\u0442\u0438 \u0432 \u043E\u0431\u044B\u0447\u043D\u0443\u044E Windows?","\u042D\u041F\u041E\u0425\u0410",MessageBoxButtons.YesNo,MessageBoxIcon.Question)!=DialogResult.Yes)return;
            cfg.ClubModeEnabled=false;cfg.Save();ApplyClubMode();if(cfg.StartExplorerOnShellExit)OpenExplorer();Application.Exit();
        }
'@
Replace-One '        private void ExitShellToExplorer\(\).*?(?=        private void RestartShell\(\))' $exitMethod 'ExitShellToExplorer'

Set-Content -Path ProgramV100Build.cs -Value $src -Encoding UTF8
