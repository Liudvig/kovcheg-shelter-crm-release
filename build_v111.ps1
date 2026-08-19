$ErrorActionPreference = "Stop"

.\build_v110_final.ps1
$src = Get-Content ProgramV110Build.cs -Raw -Encoding UTF8
$src = $src.Replace('1.1.0','1.1.1')

function Replace-Exact([string]$old,[string]$replacement,[string]$name) {
    if(-not $script:src.Contains($old)){ throw ("1.1.1 target missing: " + $name) }
    $script:src = $script:src.Replace($old,$replacement)
}

# Do not list EPOHA itself or its owned dialogs as club tasks.
$filterOld = '                if(hWnd==Handle||!IsWindowVisible(hWnd))return true;'
$filterNew = $filterOld + "`r`n" + '                uint ownerPid=0;GetWindowThreadProcessId(hWnd,out ownerPid);if(ownerPid==(uint)Process.GetCurrentProcess().Id)return true;'
Replace-Exact $filterOld $filterNew 'window process filter'

# Remove the redundant EPOHA home tab and use the strip only for real external windows.
$homeLine = '                Button home=ClubTaskButton("\u042D\u041F\u041E\u0425\u0410");home.Width=104;home.Click+=delegate{ActivateEpohaWindow();};clubTaskStrip.Controls.Add(home);'
if($src.Contains($homeLine)){$src=$src.Replace($homeLine,'')}
$src=$src.Replace('int available=Math.Max(150,clubTaskStrip.ClientSize.Width-125);','int available=Math.Max(150,clubTaskStrip.ClientSize.Width-18);')

# Hide the task strip completely while there are no external windows.
$enumOld = '                clubWindowBuffer.Clear();EnumWindows(new ClubEnumWindowsProc(ClubEnumWindow),IntPtr.Zero);' + "`r`n" + '                clubTaskStrip.SuspendLayout();'
$enumNew = '                clubWindowBuffer.Clear();EnumWindows(new ClubEnumWindowsProc(ClubEnumWindow),IntPtr.Zero);' + "`r`n" + '                clubTaskStrip.Visible=clubWindowBuffer.Count>0;if(!clubTaskStrip.Visible)return;' + "`r`n" + '                clubTaskStrip.SuspendLayout();'
Replace-Exact $enumOld $enumNew 'task strip visibility'
$src=$src.Replace('clubTaskStrip.Height=40;clubTaskStrip.Dock=DockStyle.Bottom;','clubTaskStrip.Height=34;clubTaskStrip.Dock=DockStyle.Bottom;clubTaskStrip.Visible=false;')
$src=$src.Replace('clubTaskStrip.Padding=new Padding(8,4,8,2);','clubTaskStrip.Padding=new Padding(7,2,7,1);')

# Apply Windows 7 branding more defensively: default + current resolution + .DEFAULT secure desktop wallpaper.
$oldCopy = '                File.Copy(args[1],Path.Combine(dir,"backgroundDefault.jpg"),true);'
$newCopy = @'
                string def=Path.Combine(dir,"backgroundDefault.jpg");
                File.Copy(args[1],def,true);
                try
                {
                    Rectangle sr=Screen.PrimaryScreen.Bounds;
                    string sized=Path.Combine(dir,"background"+sr.Width.ToString()+"x"+sr.Height.ToString()+".jpg");
                    File.Copy(args[1],sized,true);
                    using(Image im=Image.FromFile(args[1]))im.Save(Path.Combine(dir,"epoha-secure.bmp"),System.Drawing.Imaging.ImageFormat.Bmp);
                }catch{}
'@
Replace-Exact $oldCopy $newCopy 'branding files'

$oldPolicy = '                using(RegistryKey k=Registry.LocalMachine.CreateSubKey(@"SOFTWARE\Policies\Microsoft\Windows\System"))k.SetValue("UseOEMBackground",1,RegistryValueKind.DWord);'
$newPolicy = @'
                using(RegistryKey k=Registry.LocalMachine.CreateSubKey(@"SOFTWARE\Policies\Microsoft\Windows\System")){k.SetValue("UseOEMBackground",1,RegistryValueKind.DWord);k.SetValue("OEMBackground",1,RegistryValueKind.DWord);}
                try
                {
                    using(RegistryKey k=Registry.Users.CreateSubKey(@".DEFAULT\Control Panel\Desktop"))
                    {
                        k.SetValue("Wallpaper",Path.Combine(dir,"epoha-secure.bmp"),RegistryValueKind.String);
                        k.SetValue("WallpaperStyle","2",RegistryValueKind.String);
                        k.SetValue("TileWallpaper","0",RegistryValueKind.String);
                    }
                }catch{}
'@
Replace-Exact $oldPolicy $newPolicy 'branding registry policies'

# Verify the actual machine-scope OEM logon switch before reporting success.
$oldMarker = '                File.WriteAllText(Path.Combine(AppDir,"windows-branding.installed"),DateTime.Now.ToString("s"));'
$newMarker = @'
                object chk=null;using(RegistryKey k=Registry.LocalMachine.OpenSubKey(@"SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\Background"))if(k!=null)chk=k.GetValue("OEMBackground");
                if(!File.Exists(Path.Combine(dir,"backgroundDefault.jpg"))||chk==null||Convert.ToInt32(chk)!=1)throw new Exception("Windows branding verification failed.");
                File.WriteAllText(Path.Combine(AppDir,"windows-branding.installed"),DateTime.Now.ToString("s")+"\r\n"+Path.Combine(dir,"backgroundDefault.jpg"));
'@
Replace-Exact $oldMarker $newMarker 'branding verification'

Set-Content -Path ProgramV111Build.cs -Value $src -Encoding UTF8
