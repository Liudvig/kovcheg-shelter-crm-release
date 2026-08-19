$ErrorActionPreference = "Stop"

.\build_v100_release.ps1
$src = Get-Content ProgramV100Build.cs -Raw -Encoding UTF8
$src = $src.Replace('1.0.0','1.1.0')

function Replace-One([string]$pattern,[string]$replacement,[string]$name) {
    $rx = New-Object System.Text.RegularExpressions.Regex($pattern,[System.Text.RegularExpressions.RegexOptions]::Singleline)
    $newSrc = $rx.Replace($script:src,$replacement,1)
    if($newSrc -eq $script:src){ throw ("1.1.0 patch failed: " + $name) }
    $script:src = $newSrc
}

function Replace-Exact([string]$old,[string]$replacement,[string]$name) {
    if(-not $script:src.Contains($old)){ throw ("1.1.0 target missing: " + $name) }
    $script:src = $script:src.Replace($old,$replacement)
}

# Elevated helper is handled before watchdog/mutex so it can run under UAC.
$oldArg = @'
            if(args!=null&&args.Length>0&&String.Equals(args[0],"--watchdog",StringComparison.OrdinalIgnoreCase))
            {
                RunWatchdog(args);return;
            }
'@
$newArg = @'
            if(args!=null&&args.Length>0&&String.Equals(args[0],"--apply-branding",StringComparison.OrdinalIgnoreCase))
            {
                ApplyWindowsBrandingFromArgs(args);return;
            }
            if(args!=null&&args.Length>0&&String.Equals(args[0],"--watchdog",StringComparison.OrdinalIgnoreCase))
            {
                RunWatchdog(args);return;
            }
'@
Replace-Exact $oldArg $newArg 'program argument handler'

$brandingProgramMethods = @'
        private static void ApplyWindowsBrandingFromArgs(string[] args)
        {
            try
            {
                if(args==null||args.Length<2||String.IsNullOrEmpty(args[1])||!File.Exists(args[1]))throw new Exception("Branding image not found.");
                string win=Environment.GetFolderPath(Environment.SpecialFolder.Windows);
                string dir=Path.Combine(win,@"System32\oobe\info\backgrounds");
                Directory.CreateDirectory(dir);
                File.Copy(args[1],Path.Combine(dir,"backgroundDefault.jpg"),true);
                using(RegistryKey k=Registry.LocalMachine.CreateSubKey(@"SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\Background"))k.SetValue("OEMBackground",1,RegistryValueKind.DWord);
                using(RegistryKey k=Registry.LocalMachine.CreateSubKey(@"SOFTWARE\Policies\Microsoft\Windows\System"))k.SetValue("UseOEMBackground",1,RegistryValueKind.DWord);
                using(RegistryKey k=Registry.LocalMachine.CreateSubKey(@"SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"))k.SetValue("HideFastUserSwitching",1,RegistryValueKind.DWord);
                File.WriteAllText(Path.Combine(AppDir,"windows-branding.installed"),DateTime.Now.ToString("s"));
            }
            catch(Exception ex)
            {
                try{File.AppendAllText(LogPath,"Windows branding: "+ex+"\r\n");}catch{}
                try{MessageBox.Show("Не удалось применить оформление Windows.\r\n\r\n"+ex.Message,"ЭПОХА",MessageBoxButtons.OK,MessageBoxIcon.Error);}catch{}
            }
        }

'@
Replace-Exact '        private static void RunWatchdog(string[] args)' ($brandingProgramMethods+'        private static void RunWatchdog(string[] args)') 'branding elevated helper'

$transitionClass = @'
    public class PowerTransitionForm : Form
    {
        private bool restart;
        private Color accent;
        public PowerTransitionForm(bool isRestart,Color a)
        {
            restart=isRestart;accent=a;FormBorderStyle=FormBorderStyle.None;StartPosition=FormStartPosition.Manual;Bounds=Screen.PrimaryScreen.Bounds;TopMost=true;ShowInTaskbar=false;KeyPreview=true;
            SetStyle(ControlStyles.UserPaint|ControlStyles.AllPaintingInWmPaint|ControlStyles.OptimizedDoubleBuffer,true);BackColor=Color.Black;
        }
        protected override void OnPaintBackground(PaintEventArgs e)
        {
            ThemeWallpaper.DrawBase(e.Graphics,this,Color.FromArgb(12,15,25),Color.FromArgb(3,5,10));
            using(SolidBrush shade=new SolidBrush(Color.FromArgb(205,3,6,12)))e.Graphics.FillRectangle(shade,ClientRectangle);
        }
        protected override void OnPaint(PaintEventArgs e)
        {
            e.Graphics.SmoothingMode=SmoothingMode.AntiAlias;
            int cx=Width/2;int cy=Height/2-40;
            Rectangle mark=new Rectangle(cx-46,cy-116,92,92);
            using(SolidBrush glow=new SolidBrush(Color.FromArgb(35,accent)))e.Graphics.FillEllipse(glow,mark.X-22,mark.Y-22,mark.Width+44,mark.Height+44);
            using(Pen p=new Pen(Color.FromArgb(235,accent),3f))e.Graphics.DrawEllipse(p,mark);
            using(Font ef=new Font("Tahoma",42f,FontStyle.Bold))
            {
                Rectangle er=new Rectangle(mark.X,mark.Y-2,mark.Width,mark.Height+4);
                TextRenderer.DrawText(e.Graphics,"Э",ef,er,Color.White,TextFormatFlags.HorizontalCenter|TextFormatFlags.VerticalCenter|TextFormatFlags.NoPadding);
            }
            using(Font title=new Font("Tahoma",34f,FontStyle.Bold))
            {
                Rectangle r=new Rectangle(30,cy-8,Width-60,62);
                TextRenderer.DrawText(e.Graphics,"ЭПОХА",title,r,Color.White,TextFormatFlags.HorizontalCenter|TextFormatFlags.VerticalCenter|TextFormatFlags.NoPadding);
            }
            using(Font sub=new Font("Tahoma",12f,FontStyle.Bold))
            {
                Rectangle r=new Rectangle(30,cy+58,Width-60,34);
                string s=restart?"ПЕРЕЗАГРУЗКА СИСТЕМЫ":"ЗАВЕРШЕНИЕ РАБОТЫ";
                TextRenderer.DrawText(e.Graphics,s,sub,r,Color.FromArgb(220,225,235),TextFormatFlags.HorizontalCenter|TextFormatFlags.VerticalCenter|TextFormatFlags.NoPadding);
            }
            using(Font foot=new Font("Tahoma",9f,FontStyle.Regular))
            {
                Rectangle r=new Rectangle(30,Height-76,Width-60,28);
                TextRenderer.DrawText(e.Graphics,"КОМПЬЮТЕРНЫЙ КЛУБ  •  2000—2015",foot,r,Color.FromArgb(150,170,195),TextFormatFlags.HorizontalCenter|TextFormatFlags.VerticalCenter|TextFormatFlags.NoPadding);
            }
        }
    }

'@
Replace-Exact '    public class MainForm : Form' ($transitionClass+'    public class MainForm : Form') 'transition form'

$brandingMethods = @'
        private string CreateWindowsBrandingImage()
        {
            Directory.CreateDirectory(Program.AppDir);
            string path=Path.Combine(Program.AppDir,"windows-branding.jpg");
            using(Bitmap bmp=new Bitmap(1024,768))
            using(Graphics g=Graphics.FromImage(bmp))
            {
                g.SmoothingMode=SmoothingMode.AntiAlias;
                Rectangle all=new Rectangle(0,0,bmp.Width,bmp.Height);
                using(LinearGradientBrush bg=new LinearGradientBrush(all,Color.FromArgb(20,24,40),Color.FromArgb(2,4,10),LinearGradientMode.Vertical))g.FillRectangle(bg,all);
                using(SolidBrush halo=new SolidBrush(Color.FromArgb(28,Accent)))g.FillEllipse(230,55,564,564);
                using(Pen grid=new Pen(Color.FromArgb(18,Accent),1f)){for(int x=-700;x<1200;x+=120)g.DrawLine(grid,x,768,x+768,0);}
                int cx=512;int cy=290;Rectangle mark=new Rectangle(cx-54,cy-54,108,108);
                using(SolidBrush gb=new SolidBrush(Color.FromArgb(42,Accent)))g.FillEllipse(gb,mark.X-26,mark.Y-26,mark.Width+52,mark.Height+52);
                using(Pen p=new Pen(Color.FromArgb(240,Accent),4f))g.DrawEllipse(p,mark);
                using(Font ef=new Font("Tahoma",48f,FontStyle.Bold))using(SolidBrush wb=new SolidBrush(Color.White))
                {
                    StringFormat sf=new StringFormat();sf.Alignment=StringAlignment.Center;sf.LineAlignment=StringAlignment.Center;g.DrawString("Э",ef,wb,mark,sf);sf.Dispose();
                }
                using(Font f=new Font("Tahoma",44f,FontStyle.Bold))using(SolidBrush wb=new SolidBrush(Color.White))
                {
                    StringFormat sf=new StringFormat();sf.Alignment=StringAlignment.Center;g.DrawString("ЭПОХА",f,wb,new RectangleF(0,365,1024,70),sf);sf.Dispose();
                }
                using(Font f=new Font("Tahoma",13f,FontStyle.Bold))using(SolidBrush b=new SolidBrush(Color.FromArgb(215,222,235)))
                {
                    StringFormat sf=new StringFormat();sf.Alignment=StringAlignment.Center;g.DrawString("КОМПЬЮТЕРНЫЙ КЛУБ",f,b,new RectangleF(0,447,1024,32),sf);sf.Dispose();
                }
                using(Font f=new Font("Tahoma",10f,FontStyle.Regular))using(SolidBrush b=new SolidBrush(Color.FromArgb(150,170,195)))
                {
                    StringFormat sf=new StringFormat();sf.Alignment=StringAlignment.Center;g.DrawString("2000—2015",f,b,new RectangleF(0,486,1024,28),sf);sf.Dispose();
                }
                SaveBrandingJpeg(bmp,path);
            }
            return path;
        }

        private void SaveBrandingJpeg(Image img,string path)
        {
            System.Drawing.Imaging.ImageCodecInfo jpg=null;
            System.Drawing.Imaging.ImageCodecInfo[] codecs=System.Drawing.Imaging.ImageCodecInfo.GetImageEncoders();
            foreach(System.Drawing.Imaging.ImageCodecInfo c in codecs)if(c.MimeType=="image/jpeg"){jpg=c;break;}
            if(jpg==null){img.Save(path,System.Drawing.Imaging.ImageFormat.Jpeg);return;}
            long[] q=new long[]{78,68,58,48,38};string tmp=path+".tmp";
            foreach(long quality in q)
            {
                if(File.Exists(tmp))File.Delete(tmp);
                System.Drawing.Imaging.EncoderParameters ep=new System.Drawing.Imaging.EncoderParameters(1);
                ep.Param[0]=new System.Drawing.Imaging.EncoderParameter(System.Drawing.Imaging.Encoder.Quality,quality);
                img.Save(tmp,jpg,ep);ep.Dispose();
                FileInfo fi=new FileInfo(tmp);if(fi.Length<=250*1024){File.Copy(tmp,path,true);File.Delete(tmp);return;}
            }
            File.Copy(tmp,path,true);File.Delete(tmp);
        }

        private void ApplyWindowsBranding()
        {
            try
            {
                string image=CreateWindowsBrandingImage();
                ProcessStartInfo psi=new ProcessStartInfo(Application.ExecutablePath,"--apply-branding \""+image+"\"");
                psi.UseShellExecute=true;psi.Verb="runas";Process p=Process.Start(psi);if(p!=null)p.WaitForExit();
                if(File.Exists(Path.Combine(Program.AppDir,"windows-branding.installed")))MessageBox.Show("Оформление Windows применено. После перезагрузки защищённые экраны Windows будут использовать стиль ЭПОХИ, а пункт смены пользователя будет скрыт.","ЭПОХА",MessageBoxButtons.OK,MessageBoxIcon.Information);
            }
            catch(Exception ex){MessageBox.Show("Не удалось применить оформление Windows.\r\n\r\n"+ex.Message,"ЭПОХА",MessageBoxButtons.OK,MessageBoxIcon.Error);}
        }

        private void BeginPowerTransition(bool restart)
        {
            try{if(File.Exists(Program.WatchdogMarkerPath))File.Delete(Program.WatchdogMarkerPath);}catch{}
            PowerTransitionForm cover=new PowerTransitionForm(restart,Accent);cover.Show();cover.BringToFront();cover.Refresh();Application.DoEvents();System.Threading.Thread.Sleep(180);
            string args=restart?"/r /t 0 /f":"/s /t 0 /f";
            try{Process.Start(new ProcessStartInfo("shutdown.exe",args){UseShellExecute=false,CreateNoWindow=true});}
            catch(Exception ex){cover.Close();MessageBox.Show(ex.Message,"ЭПОХА",MessageBoxButtons.OK,MessageBoxIcon.Error);}
        }

'@
Replace-Exact '        private void Restart_Click(object sender,EventArgs e)' ($brandingMethods+'        private void Restart_Click(object sender,EventArgs e)') 'branding mainform methods'

$oldPower = '        private void Restart_Click(object sender,EventArgs e){if(cfg.ConfirmPower&&MessageBox.Show("Перезагрузить компьютер?","ЭПОХА",MessageBoxButtons.YesNo,MessageBoxIcon.Question)!=DialogResult.Yes)return;Process.Start(new ProcessStartInfo("shutdown.exe","/r /t 0"){UseShellExecute=false,CreateNoWindow=true});}`r`n        private void Power_Click(object sender,EventArgs e){if(cfg.ConfirmPower&&MessageBox.Show("Выключить компьютер?","ЭПОХА",MessageBoxButtons.YesNo,MessageBoxIcon.Question)!=DialogResult.Yes)return;Process.Start(new ProcessStartInfo("shutdown.exe","/s /t 0"){UseShellExecute=false,CreateNoWindow=true});}'
$newPower = '        private void Restart_Click(object sender,EventArgs e){if(cfg.ConfirmPower&&MessageBox.Show("Перезагрузить компьютер?","ЭПОХА",MessageBoxButtons.YesNo,MessageBoxIcon.Question)!=DialogResult.Yes)return;BeginPowerTransition(true);}`r`n        private void Power_Click(object sender,EventArgs e){if(cfg.ConfirmPower&&MessageBox.Show("Выключить компьютер?","ЭПОХА",MessageBoxButtons.YesNo,MessageBoxIcon.Question)!=DialogResult.Yes)return;BeginPowerTransition(false);}'
Replace-Exact $oldPower $newPower 'power handlers'

# One maintenance button: install the club branding into Winlogon/OEM screens.
$brandButton = @'
            ActionButton(p,"\u041E\u0424\u041E\u0420\u041C\u0418\u0422\u042C WINDOWS \u0412 \u0421\u0422\u0418\u041B\u0415 \u042D\u041F\u041E\u0425\u0418",434,664,260,38,delegate{ApplyWindowsBranding();});
'@
$adminAnchor = '            Label info=new Label();info.Text="Ctrl + Alt + E - \u0430\u0432\u0430\u0440\u0438\u0439\u043D\u044B\u0439 \u0432\u0445\u043E\u0434 \u0430\u0434\u043C\u0438\u043D\u0438\u0441\u0442\u0440\u0430\u0442\u043E\u0440\u0430. Ctrl+Alt+Del \u043E\u0441\u0442\u0430\u0451\u0442\u0441\u044F \u0437\u0430\u0449\u0438\u0449\u0451\u043D\u043D\u043E\u0439 \u043A\u043E\u043C\u0431\u0438\u043D\u0430\u0446\u0438\u0435\u0439 Windows.";info.SetBounds(30,718,820,50);info.ForeColor=Color.FromArgb(180,194,216);info.BackColor=Color.Transparent;p.Controls.Add(info);'
$adminNew = $brandButton + '            Label info=new Label();info.Text="Ctrl + Alt + E - \u0430\u0432\u0430\u0440\u0438\u0439\u043D\u044B\u0439 \u0432\u0445\u043E\u0434 \u0430\u0434\u043C\u0438\u043D\u0438\u0441\u0442\u0440\u0430\u0442\u043E\u0440\u0430. Ctrl+Alt+Del \u043E\u0441\u0442\u0430\u0451\u0442\u0441\u044F \u0437\u0430\u0449\u0438\u0449\u0451\u043D\u043D\u043E\u0439 \u043A\u043E\u043C\u0431\u0438\u043D\u0430\u0446\u0438\u0435\u0439 Windows.";info.SetBounds(30,718,820,50);info.ForeColor=Color.FromArgb(180,194,216);info.BackColor=Color.Transparent;p.Controls.Add(info);'
Replace-Exact $adminAnchor $adminNew 'branding admin button'

Set-Content -Path ProgramV110Build.cs -Value $src -Encoding UTF8
