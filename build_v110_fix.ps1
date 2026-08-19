$ErrorActionPreference = "Stop"

# Sanitize the 1.1.0 builder before PowerShell parses its legacy Cyrillic replacement lines.
$lines = Get-Content build_v110.ps1 -Encoding UTF8
$out = New-Object System.Collections.Generic.List[string]
$skip = $false
foreach($line in $lines) {
    if($line -like '$oldPower =*') { $skip = $true; continue }
    if($skip) {
        if($line -like 'Replace-Exact $oldPower*') { $skip = $false }
        continue
    }
    $out.Add($line)
}
Set-Content -Path build_v110_runtime.ps1 -Value $out -Encoding UTF8
.\build_v110_runtime.ps1

$src = Get-Content ProgramV110Build.cs -Raw -Encoding UTF8

function Replace-One([string]$pattern,[string]$replacement,[string]$name) {
    $rx = New-Object System.Text.RegularExpressions.Regex($pattern,[System.Text.RegularExpressions.RegexOptions]::Singleline)
    $newSrc = $rx.Replace($script:src,$replacement,1)
    if($newSrc -eq $script:src){ throw ("1.1.0 final patch failed: " + $name) }
    $script:src = $newSrc
}

# Keep EPOHA on screen until Windows switches to Winlogon; no Explorer flash.
$powerHandlers = @'
        private void Restart_Click(object sender,EventArgs e)
        {
            if(cfg.ConfirmPower&&MessageBox.Show("\u041F\u0435\u0440\u0435\u0437\u0430\u0433\u0440\u0443\u0437\u0438\u0442\u044C \u043A\u043E\u043C\u043F\u044C\u044E\u0442\u0435\u0440?","\u042D\u041F\u041E\u0425\u0410",MessageBoxButtons.YesNo,MessageBoxIcon.Question)!=DialogResult.Yes)return;
            BeginPowerTransition(true);
        }
        private void Power_Click(object sender,EventArgs e)
        {
            if(cfg.ConfirmPower&&MessageBox.Show("\u0412\u044B\u043A\u043B\u044E\u0447\u0438\u0442\u044C \u043A\u043E\u043C\u043F\u044C\u044E\u0442\u0435\u0440?","\u042D\u041F\u041E\u0425\u0410",MessageBoxButtons.YesNo,MessageBoxIcon.Question)!=DialogResult.Yes)return;
            BeginPowerTransition(false);
        }

        private void MainForm_KeyDown
'@
Replace-One '        private void Restart_Click\(object sender,EventArgs e\).*?        private void MainForm_KeyDown' $powerHandlers 'power handlers'

# Native window switcher for the club task strip.
$native = @'
        private FlowLayoutPanel clubTaskStrip;
        private System.Windows.Forms.Timer clubWindowTimer;
        private List<IntPtr> clubWindowBuffer = new List<IntPtr>();
        private delegate bool ClubEnumWindowsProc(IntPtr hWnd,IntPtr lParam);
        [System.Runtime.InteropServices.DllImport("user32.dll")] private static extern bool EnumWindows(ClubEnumWindowsProc cb,IntPtr lp);
        [System.Runtime.InteropServices.DllImport("user32.dll")] private static extern bool IsWindowVisible(IntPtr hWnd);
        [System.Runtime.InteropServices.DllImport("user32.dll",CharSet=System.Runtime.InteropServices.CharSet.Unicode)] private static extern int GetWindowText(IntPtr hWnd,System.Text.StringBuilder text,int max);
        [System.Runtime.InteropServices.DllImport("user32.dll")] private static extern int GetWindowTextLength(IntPtr hWnd);
        [System.Runtime.InteropServices.DllImport("user32.dll")] private static extern uint GetWindowThreadProcessId(IntPtr hWnd,out uint processId);
        [System.Runtime.InteropServices.DllImport("user32.dll")] private static extern bool SetForegroundWindow(IntPtr hWnd);
        [System.Runtime.InteropServices.DllImport("user32.dll")] private static extern bool ShowWindow(IntPtr hWnd,int cmd);
        [System.Runtime.InteropServices.DllImport("user32.dll")] private static extern bool IsIconic(IntPtr hWnd);
        [System.Runtime.InteropServices.DllImport("user32.dll")] private static extern bool PostMessage(IntPtr hWnd,uint msg,IntPtr wParam,IntPtr lParam);
'@
if($src.Contains('        private IntPtr keyboardHook = IntPtr.Zero;')) {
    $src = $src.Replace('        private IntPtr keyboardHook = IntPtr.Zero;','        private IntPtr keyboardHook = IntPtr.Zero;' + "`r`n" + $native)
} elseif($src.Contains('        private bool watchdogStarted = false;')) {
    $src = $src.Replace('        private bool watchdogStarted = false;','        private bool watchdogStarted = false;' + "`r`n" + $native)
} else { throw '1.1.0 final patch failed: native field anchor' }

# Make the footer a real club taskbar instead of a tiny status strip.
$src = $src.Replace('root.RowStyles.Add(new RowStyle(SizeType.Absolute,26));','root.RowStyles.Add(new RowStyle(SizeType.Absolute,40));')
$footer = @'
            footer = new DbPanel(); footer.Dock=DockStyle.Fill; footer.Margin=new Padding(0); footer.BackColor=Color.FromArgb(12,16,25); root.Controls.Add(footer,1,2);
            footerLabel = new Label(); footerLabel.Visible=false; footer.Controls.Add(footerLabel);
            clubTaskStrip=new FlowLayoutPanel();clubTaskStrip.Dock=DockStyle.Fill;clubTaskStrip.WrapContents=false;clubTaskStrip.AutoScroll=true;clubTaskStrip.Padding=new Padding(8,4,8,2);clubTaskStrip.Margin=new Padding(0);clubTaskStrip.BackColor=Color.FromArgb(10,14,22);footer.Controls.Add(clubTaskStrip);
            clubWindowTimer=new System.Windows.Forms.Timer();clubWindowTimer.Interval=750;clubWindowTimer.Tick+=delegate{RefreshClubTaskStrip();};clubWindowTimer.Start();RefreshClubTaskStrip();
'@
Replace-One '            footer = new DbPanel\(\);.*?footer\.Controls\.Add\(footerLabel\);' $footer 'club task strip footer'

$taskMethods = @'
        private bool ClubEnumWindow(IntPtr hWnd,IntPtr lParam)
        {
            try
            {
                if(hWnd==Handle||!IsWindowVisible(hWnd))return true;
                int len=GetWindowTextLength(hWnd);if(len<=0)return true;
                System.Text.StringBuilder sb=new System.Text.StringBuilder(Math.Min(1024,len+2));GetWindowText(hWnd,sb,sb.Capacity);
                string title=sb.ToString().Trim();if(title.Length==0||title=="Program Manager")return true;
                clubWindowBuffer.Add(hWnd);
            }catch{}
            return true;
        }

        private string ClubWindowTitle(IntPtr hWnd)
        {
            try{int len=GetWindowTextLength(hWnd);System.Text.StringBuilder sb=new System.Text.StringBuilder(Math.Max(8,Math.Min(1024,len+2)));GetWindowText(hWnd,sb,sb.Capacity);return sb.ToString().Trim();}catch{return "";}
        }

        private Button ClubTaskButton(string text)
        {
            Button b=new Button();b.Height=29;b.Width=145;b.Margin=new Padding(3,1,3,1);b.FlatStyle=FlatStyle.Flat;b.FlatAppearance.BorderSize=1;b.FlatAppearance.BorderColor=Color.FromArgb(65,80,112);b.BackColor=Color.FromArgb(23,29,42);b.ForeColor=Color.White;b.Font=F(7.5f,FontStyle.Bold);b.TextAlign=ContentAlignment.MiddleLeft;b.Padding=new Padding(7,0,4,0);b.Text=text;return b;
        }

        private void RefreshClubTaskStrip()
        {
            if(clubTaskStrip==null||clubTaskStrip.IsDisposed)return;
            try
            {
                clubWindowBuffer.Clear();EnumWindows(new ClubEnumWindowsProc(ClubEnumWindow),IntPtr.Zero);
                clubTaskStrip.SuspendLayout();
                foreach(Control c in clubTaskStrip.Controls)try{c.Dispose();}catch{}
                clubTaskStrip.Controls.Clear();
                Button home=ClubTaskButton("\u042D\u041F\u041E\u0425\u0410");home.Width=104;home.Click+=delegate{ActivateEpohaWindow();};clubTaskStrip.Controls.Add(home);
                int available=Math.Max(150,clubTaskStrip.ClientSize.Width-125);int count=Math.Max(1,clubWindowBuffer.Count);int width=Math.Max(105,Math.Min(190,available/count-8));
                foreach(IntPtr h in clubWindowBuffer)
                {
                    string title=ClubWindowTitle(h);if(title.Length==0)continue;
                    string show=title.Length>27?title.Substring(0,26)+"...":title;
                    Button b=ClubTaskButton(show);b.Width=width;IntPtr target=h;b.Click+=delegate{ActivateClubWindow(target);};
                    ContextMenuStrip m=new ContextMenuStrip();ToolStripMenuItem open=new ToolStripMenuItem("\u041F\u043E\u043A\u0430\u0437\u0430\u0442\u044C");open.Click+=delegate{ActivateClubWindow(target);};m.Items.Add(open);ToolStripMenuItem close=new ToolStripMenuItem("\u0417\u0430\u043A\u0440\u044B\u0442\u044C \u043E\u043A\u043D\u043E");close.Enabled=adminMode;close.Click+=delegate{if(adminMode)PostMessage(target,0x0010,IntPtr.Zero,IntPtr.Zero);};m.Items.Add(close);b.ContextMenuStrip=m;
                    clubTaskStrip.Controls.Add(b);
                }
                clubTaskStrip.ResumeLayout();
            }catch{}
        }

        private void ActivateEpohaWindow()
        {
            try{TopMost=cfg.AlwaysOnTop;WindowState=FormWindowState.Maximized;Show();BringToFront();Activate();}catch{}
        }

        private void ActivateClubWindow(IntPtr hWnd)
        {
            try
            {
                TopMost=false;
                if(IsIconic(hWnd))ShowWindow(hWnd,9);else ShowWindow(hWnd,5);
                SetForegroundWindow(hWnd);
            }catch{}
        }

'@
$src = $src.Replace('        private void Restart_Click(object sender,EventArgs e)', $taskMethods + '        private void Restart_Click(object sender,EventArgs e)')

Set-Content -Path ProgramV110Build.cs -Value $src -Encoding UTF8
