$ErrorActionPreference = "Stop"

function Replace-Exact([string]$text, [string]$old, [string]$new, [string]$name) {
    if (-not $text.Contains($old)) { throw ("Patch target not found: " + $name) }
    return $text.Replace($old, $new)
}

.\build_v051.ps1
$src = Get-Content ProgramV051Build.cs -Raw -Encoding UTF8
$src = $src.Replace('0.5.1', '0.6.0')

# New visual and club-mode settings.
$src = Replace-Exact $src `
'        public bool StartExplorerOnShellExit = true;' `
'        public bool StartExplorerOnShellExit = true;
        public bool UseExeIcons = true;
        public bool ShowCardCategory = true;
        public bool ShowSeconds = true;
        public bool ShowStatusPanel = true;
        public bool BlockTaskManager = false;
        public bool BlockSystemKeys = false;
        public bool CloseExplorerInClubMode = false;
        public bool ClubModeEnabled = false;' `
'config 060 fields'

$src = Replace-Exact $src `
'                c.StartExplorerOnShellExit = BoolAttr(root, "startExplorerOnShellExit", true);' `
'                c.StartExplorerOnShellExit = BoolAttr(root, "startExplorerOnShellExit", true);
                c.UseExeIcons = BoolAttr(root, "useExeIcons", true);
                c.ShowCardCategory = BoolAttr(root, "showCardCategory", true);
                c.ShowSeconds = BoolAttr(root, "showSeconds", true);
                c.ShowStatusPanel = BoolAttr(root, "showStatusPanel", true);
                c.BlockTaskManager = BoolAttr(root, "blockTaskManager", false);
                c.BlockSystemKeys = BoolAttr(root, "blockSystemKeys", false);
                c.CloseExplorerInClubMode = BoolAttr(root, "closeExplorerInClubMode", false);
                c.ClubModeEnabled = BoolAttr(root, "clubModeEnabled", false);' `
'config 060 load'

$src = Replace-Exact $src `
'            root.SetAttribute("singleGameMode", SingleGameMode.ToString()); root.SetAttribute("startExplorerOnShellExit", StartExplorerOnShellExit.ToString());' `
'            root.SetAttribute("singleGameMode", SingleGameMode.ToString()); root.SetAttribute("startExplorerOnShellExit", StartExplorerOnShellExit.ToString());
            root.SetAttribute("useExeIcons", UseExeIcons.ToString()); root.SetAttribute("showCardCategory", ShowCardCategory.ToString());
            root.SetAttribute("showSeconds", ShowSeconds.ToString()); root.SetAttribute("showStatusPanel", ShowStatusPanel.ToString());
            root.SetAttribute("blockTaskManager", BlockTaskManager.ToString()); root.SetAttribute("blockSystemKeys", BlockSystemKeys.ToString());
            root.SetAttribute("closeExplorerInClubMode", CloseExplorerInClubMode.ToString()); root.SetAttribute("clubModeEnabled", ClubModeEnabled.ToString());' `
'config 060 save'

$src = Replace-Exact $src `
'        public static int CardTransparency = 18;' `
'        public static int CardTransparency = 18;
        public static int HeaderTransparency = 26;
        public static bool UseExeIcons = true;
        public static bool ShowCardCategory = true;' `
'theme 060 flags'

$uiClasses = @'
    public static class UiPaint
    {
        public static GraphicsPath RoundRect(Rectangle r, int radius)
        {
            GraphicsPath p = new GraphicsPath();
            int d = Math.Max(2, radius * 2);
            p.AddArc(r.X, r.Y, d, d, 180, 90);
            p.AddArc(r.Right-d, r.Y, d, d, 270, 90);
            p.AddArc(r.Right-d, r.Bottom-d, d, d, 0, 90);
            p.AddArc(r.X, r.Bottom-d, d, d, 90, 90);
            p.CloseFigure();
            return p;
        }

        public static Color Blend(Color a, Color b, float p)
        {
            return Color.FromArgb((int)(a.R+(b.R-a.R)*p),(int)(a.G+(b.G-a.G)*p),(int)(a.B+(b.B-a.B)*p));
        }
    }

    public class ClockDisplay : Control
    {
        public string TimeText = "00:00:00";
        public string DateText = "00.00.0000";
        public bool ShowDate = true;
        public Color Accent = Color.MediumPurple;
        public ClockDisplay()
        {
            Size = new Size(188,64);
            SetStyle(ControlStyles.UserPaint|ControlStyles.AllPaintingInWmPaint|ControlStyles.OptimizedDoubleBuffer,true);
        }
        protected override void OnPaintBackground(PaintEventArgs e)
        {
            ThemeWallpaper.DrawBase(e.Graphics,this,Color.FromArgb(22,28,40),Color.FromArgb(10,14,23));
            int t=Math.Max(0,Math.Min(100,ThemeWallpaper.HeaderTransparency));
            int alpha=(100-t)*235/100;
            if(alpha>0)using(SolidBrush b=new SolidBrush(Color.FromArgb(alpha,15,19,29)))e.Graphics.FillRectangle(b,ClientRectangle);
        }
        protected override void OnPaint(PaintEventArgs e)
        {
            e.Graphics.SmoothingMode=SmoothingMode.AntiAlias;
            Rectangle timeRect=new Rectangle(0,1,Width,39);
            Rectangle dateRect=new Rectangle(0,40,Width,22);
            using(Font ft=new Font("Tahoma",19.5f,FontStyle.Bold))
            TextRenderer.DrawText(e.Graphics,TimeText,ft,timeRect,Color.White,TextFormatFlags.Right|TextFormatFlags.VerticalCenter|TextFormatFlags.NoPadding);
            if(ShowDate)
            {
                using(Font fd=new Font("Tahoma",10.5f,FontStyle.Bold))
                TextRenderer.DrawText(e.Graphics,DateText,fd,dateRect,Color.FromArgb(225,232,242),TextFormatFlags.Right|TextFormatFlags.VerticalCenter|TextFormatFlags.NoPadding);
            }
        }
    }

    public class StatusStripPanel : DbPanel
    {
        public string TitleText = "";
        public string SubText = "";
        public Color TitleColor = Color.White;
        public Color Accent = Color.MediumPurple;
        public int Transparency = 100;
        public StatusStripPanel()
        {
            SetStyle(ControlStyles.UserPaint|ControlStyles.AllPaintingInWmPaint|ControlStyles.OptimizedDoubleBuffer,true);
        }
        protected override void OnPaintBackground(PaintEventArgs e)
        {
            ThemeWallpaper.DrawBase(e.Graphics,this,Color.FromArgb(22,28,40),Color.FromArgb(10,14,23));
            int t=Math.Max(0,Math.Min(100,ThemeWallpaper.HeaderTransparency));
            int alpha=(100-t)*235/100;
            if(alpha>0)using(SolidBrush b=new SolidBrush(Color.FromArgb(alpha,15,19,29)))e.Graphics.FillRectangle(b,ClientRectangle);
        }
        protected override void OnPaint(PaintEventArgs e)
        {
            e.Graphics.SmoothingMode=SmoothingMode.AntiAlias;
            using(SolidBrush glow=new SolidBrush(Color.FromArgb(95,Accent)))e.Graphics.FillEllipse(glow,12,Height/2-4,8,8);
            using(Pen line=new Pen(Color.FromArgb(100,Accent),1f))e.Graphics.DrawLine(line,28,Height-6,Width-18,Height-6);
            Rectangle a=new Rectangle(32,5,Width-48,24);Rectangle b=new Rectangle(32,29,Width-48,20);
            using(Font f1=new Font("Tahoma",10.5f,FontStyle.Bold))TextRenderer.DrawText(e.Graphics,TitleText,f1,a,TitleColor,TextFormatFlags.HorizontalCenter|TextFormatFlags.VerticalCenter|TextFormatFlags.EndEllipsis);
            using(Font f2=new Font("Tahoma",7.8f,FontStyle.Regular))TextRenderer.DrawText(e.Graphics,SubText,f2,b,Color.FromArgb(188,201,220),TextFormatFlags.HorizontalCenter|TextFormatFlags.VerticalCenter|TextFormatFlags.EndEllipsis);
        }
    }

'@
$src = Replace-Exact $src '    public class NavButton : Control' ($uiClasses + '    public class NavButton : Control') 'ui classes 060'

$navClass = @'
    public class NavButton : Control
    {
        public bool Selected;
        public Color Accent = Color.MediumPurple;
        private bool hover;
        public NavButton(){Height=44;Cursor=Cursors.Hand;SetStyle(ControlStyles.AllPaintingInWmPaint|ControlStyles.UserPaint|ControlStyles.OptimizedDoubleBuffer,true);}
        protected override void OnMouseEnter(EventArgs e){hover=true;Invalidate();base.OnMouseEnter(e);}
        protected override void OnMouseLeave(EventArgs e){hover=false;Invalidate();base.OnMouseLeave(e);}
        protected override void OnPaint(PaintEventArgs e)
        {
            e.Graphics.SmoothingMode=SmoothingMode.AntiAlias;
            ThemeWallpaper.DrawBase(e.Graphics,this,Color.FromArgb(18,24,37),Color.FromArgb(8,12,21));
            Rectangle r=new Rectangle(5,3,Width-11,Height-7);
            int t=Math.Max(0,Math.Min(100,ThemeWallpaper.SidebarTransparency));
            int baseAlpha=(100-t)*185/100;
            if(Selected||hover)
            {
                int a=Math.Max(35,baseAlpha);
                Color c1=Selected?UiPaint.Blend(Accent,Color.FromArgb(40,48,70),0.72f):Color.FromArgb(50,60,84);
                Color c2=Color.FromArgb(14,19,31);
                using(GraphicsPath gp=UiPaint.RoundRect(r,8))
                using(LinearGradientBrush br=new LinearGradientBrush(r,Color.FromArgb(a,c1),Color.FromArgb(a,c2),LinearGradientMode.Vertical))e.Graphics.FillPath(br,gp);
                using(GraphicsPath gp=UiPaint.RoundRect(r,8))using(Pen p=new Pen(Color.FromArgb(Selected?145:70,Accent)))e.Graphics.DrawPath(p,gp);
            }
            if(Selected)using(SolidBrush b=new SolidBrush(Accent))e.Graphics.FillEllipse(b,13,Height/2-3,6,6);
            Rectangle tx=new Rectangle(28,0,Width-44,Height);
            using(Font f=new Font("Tahoma",9.5f,FontStyle.Bold))TextRenderer.DrawText(e.Graphics,Text,f,tx,Selected?Color.White:Color.FromArgb(232,237,245),TextFormatFlags.Left|TextFormatFlags.VerticalCenter|TextFormatFlags.EndEllipsis);
            if(hover||Selected)
            {
                using(Pen p=new Pen(Color.FromArgb(Selected?210:120,Accent),1.4f)){e.Graphics.DrawLine(p,Width-24,Height/2-4,Width-19,Height/2);e.Graphics.DrawLine(p,Width-19,Height/2,Width-24,Height/2+4);}
            }
        }
    }

'@
$navPattern='(?s)    public class NavButton : Control.*?    public class IconButton : Control'
$newSrc=[regex]::Replace($src,$navPattern,$navClass+'    public class IconButton : Control',1)
if($newSrc -eq $src){throw "nav 060 patch failed"};$src=$newSrc

$iconClass = @'
    public class IconButton : Control
    {
        public enum IconKind { Admin, Restart, Power }
        public IconKind Kind;
        public Color Accent=Color.MediumPurple;
        private bool hover;private bool down;
        public IconButton(IconKind kind){Kind=kind;Size=new Size(42,42);Cursor=Cursors.Hand;SetStyle(ControlStyles.UserPaint|ControlStyles.OptimizedDoubleBuffer|ControlStyles.AllPaintingInWmPaint,true);}
        protected override void OnMouseEnter(EventArgs e){hover=true;Invalidate();base.OnMouseEnter(e);}protected override void OnMouseLeave(EventArgs e){hover=false;down=false;Invalidate();base.OnMouseLeave(e);}protected override void OnMouseDown(MouseEventArgs e){down=true;Invalidate();base.OnMouseDown(e);}protected override void OnMouseUp(MouseEventArgs e){down=false;Invalidate();base.OnMouseUp(e);}
        protected override void OnPaintBackground(PaintEventArgs e){ThemeWallpaper.DrawBase(e.Graphics,this,Color.FromArgb(22,28,40),Color.FromArgb(10,14,23));int t=Math.Max(0,Math.Min(100,ThemeWallpaper.HeaderTransparency));int a=(100-t)*235/100;if(a>0)using(SolidBrush b=new SolidBrush(Color.FromArgb(a,15,19,29)))e.Graphics.FillRectangle(b,ClientRectangle);}
        protected override void OnPaint(PaintEventArgs e)
        {
            e.Graphics.SmoothingMode=SmoothingMode.AntiAlias;Rectangle r=new Rectangle(2,2,Width-5,Height-5);
            Color top=hover?UiPaint.Blend(Accent,Color.White,0.16f):Color.FromArgb(53,63,84);Color bot=hover?UiPaint.Blend(Accent,Color.Black,0.54f):Color.FromArgb(18,24,38);if(down){top=bot;bot=Color.FromArgb(9,13,22);}
            using(GraphicsPath gp=UiPaint.RoundRect(r,9))using(LinearGradientBrush b=new LinearGradientBrush(r,Color.FromArgb(hover?210:155,top),Color.FromArgb(hover?220:175,bot),LinearGradientMode.Vertical))e.Graphics.FillPath(b,gp);
            using(GraphicsPath gp=UiPaint.RoundRect(r,9))using(Pen border=new Pen(hover?Accent:Color.FromArgb(95,112,146),1f))e.Graphics.DrawPath(border,gp);
            using(Pen p=new Pen(Color.FromArgb(hover?255:225,Color.White),2f))
            {
                if(Kind==IconKind.Power){e.Graphics.DrawArc(p,11,11,19,19,-55,290);e.Graphics.DrawLine(p,20,8,20,21);}
                else if(Kind==IconKind.Restart){e.Graphics.DrawArc(p,9,10,23,23,30,290);Point[]q={new Point(31,9),new Point(32,18),new Point(24,14)};using(SolidBrush s=new SolidBrush(p.Color))e.Graphics.FillPolygon(s,q);}
                else{e.Graphics.DrawEllipse(p,15,10,10,10);e.Graphics.DrawArc(p,10,20,20,15,195,150);}
            }
        }
    }

'@
$iconPattern='(?s)    public class IconButton : Control.*?    public class GameCard : Control'
$newSrc=[regex]::Replace($src,$iconPattern,$iconClass+'    public class GameCard : Control',1)
if($newSrc -eq $src){throw "icon 060 patch failed"};$src=$newSrc

$cardClass = @'
    public class GameCard : Control
    {
        public GameItem Game;public Color Accent;public Image Cover;public Image ExeIcon;private bool hover;private bool down;
        public GameCard(GameItem g,Color a){Game=g;Accent=a;Cursor=Cursors.Hand;SetStyle(ControlStyles.UserPaint|ControlStyles.OptimizedDoubleBuffer|ControlStyles.AllPaintingInWmPaint,true);TryLoadVisual();}
        private void TryLoadVisual(){try{if(!String.IsNullOrEmpty(Game.ImagePath)&&File.Exists(Game.ImagePath))using(Image i=Image.FromFile(Game.ImagePath))Cover=new Bitmap(i);else if(ThemeWallpaper.UseExeIcons&&!String.IsNullOrEmpty(Game.Exe)&&File.Exists(Game.Exe)){Icon ic=Icon.ExtractAssociatedIcon(Game.Exe);if(ic!=null){ExeIcon=ic.ToBitmap();ic.Dispose();}}}catch{}}
        protected override void Dispose(bool disposing){if(disposing){if(Cover!=null)Cover.Dispose();if(ExeIcon!=null)ExeIcon.Dispose();}base.Dispose(disposing);}protected override void OnMouseEnter(EventArgs e){hover=true;Invalidate();base.OnMouseEnter(e);}protected override void OnMouseLeave(EventArgs e){hover=false;down=false;Invalidate();base.OnMouseLeave(e);}protected override void OnMouseDown(MouseEventArgs e){down=true;Invalidate();base.OnMouseDown(e);}protected override void OnMouseUp(MouseEventArgs e){down=false;Invalidate();base.OnMouseUp(e);}
        protected override void OnPaint(PaintEventArgs e)
        {
            e.Graphics.SmoothingMode=SmoothingMode.AntiAlias;ThemeWallpaper.DrawBase(e.Graphics,this,Color.FromArgb(28,35,52),Color.FromArgb(8,12,21));Rectangle shadow=new Rectangle(5,6,Width-10,Height-10);Rectangle r=new Rectangle(2,2,Width-8,Height-9);
            using(GraphicsPath sp=UiPaint.RoundRect(shadow,11))using(SolidBrush sb=new SolidBrush(Color.FromArgb(80,0,0,0)))e.Graphics.FillPath(sb,sp);
            int t=Math.Max(0,Math.Min(100,ThemeWallpaper.CardTransparency));int alpha=(100-t)*225/100;Color c1=hover?UiPaint.Blend(Accent,Color.FromArgb(52,62,86),0.72f):Color.FromArgb(38,47,68);Color c2=Color.FromArgb(8,12,21);
            using(GraphicsPath gp=UiPaint.RoundRect(r,10)){GraphicsState st=e.Graphics.Save();e.Graphics.SetClip(gp);if(alpha>0)using(LinearGradientBrush br=new LinearGradientBrush(r,Color.FromArgb(alpha,c1),Color.FromArgb(alpha,c2),LinearGradientMode.Vertical))e.Graphics.FillRectangle(br,r);
                int footerH=ThemeWallpaper.ShowCardCategory?52:43;Rectangle art=new Rectangle(r.X+1,r.Y+1,r.Width-2,r.Height-footerH-1);
                if(Cover!=null){e.Graphics.InterpolationMode=InterpolationMode.HighQualityBicubic;e.Graphics.DrawImage(Cover,art);using(SolidBrush shade=new SolidBrush(Color.FromArgb(hover?35:62,0,0,0)))e.Graphics.FillRectangle(shade,art);}else if(ExeIcon!=null){int s=Math.Min(68,Math.Min(art.Width-20,art.Height-20));Rectangle ir=new Rectangle(art.X+(art.Width-s)/2,art.Y+(art.Height-s)/2,s,s);e.Graphics.InterpolationMode=InterpolationMode.HighQualityBicubic;e.Graphics.DrawImage(ExeIcon,ir);}else{using(SolidBrush glow=new SolidBrush(Color.FromArgb(hover?100:58,Accent)))e.Graphics.FillEllipse(glow,art.X+art.Width/2-31,art.Y+art.Height/2-31,62,62);Point[]tri={new Point(art.X+art.Width/2-8,art.Y+art.Height/2-13),new Point(art.X+art.Width/2-8,art.Y+art.Height/2+13),new Point(art.X+art.Width/2+14,art.Y+art.Height/2)};using(SolidBrush wb=new SolidBrush(Color.White))e.Graphics.FillPolygon(wb,tri);}
                using(LinearGradientBrush fb=new LinearGradientBrush(new Rectangle(r.X,r.Bottom-footerH,r.Width,footerH),Color.FromArgb(220,13,18,30),Color.FromArgb(240,6,9,17),LinearGradientMode.Vertical))e.Graphics.FillRectangle(fb,r.X,r.Bottom-footerH,r.Width,footerH);
                Rectangle titleR=new Rectangle(r.X+12,r.Bottom-footerH+4,r.Width-24,ThemeWallpaper.ShowCardCategory?26:35);using(Font f=new Font("Tahoma",9.2f,FontStyle.Bold))TextRenderer.DrawText(e.Graphics,Game.Name,f,titleR,Color.White,TextFormatFlags.HorizontalCenter|TextFormatFlags.VerticalCenter|TextFormatFlags.EndEllipsis);
                if(ThemeWallpaper.ShowCardCategory){Rectangle catR=new Rectangle(r.X+12,r.Bottom-22,r.Width-24,16);using(Font f2=new Font("Tahoma",7f,FontStyle.Regular))TextRenderer.DrawText(e.Graphics,Game.Category,f2,catR,Color.FromArgb(166,181,204),TextFormatFlags.HorizontalCenter|TextFormatFlags.VerticalCenter|TextFormatFlags.EndEllipsis);}
                e.Graphics.Restore(st);}
            using(GraphicsPath gp=UiPaint.RoundRect(r,10))using(Pen p=new Pen(hover?Accent:Color.FromArgb(78,92,122),hover?1.6f:1f))e.Graphics.DrawPath(p,gp);if(hover)using(Pen p2=new Pen(Color.FromArgb(150,Accent),2f))e.Graphics.DrawLine(p2,r.X+10,r.Y+2,r.Right-10,r.Y+2);
            if(down)using(GraphicsPath gp=UiPaint.RoundRect(r,10))using(SolidBrush b=new SolidBrush(Color.FromArgb(35,0,0,0)))e.Graphics.FillPath(b,gp);
        }
    }

'@
$cardPattern='(?s)    public class GameCard : Control.*?    public class MainForm : Form'
$newSrc=[regex]::Replace($src,$cardPattern,$cardClass+'    public class MainForm : Form',1)
if($newSrc -eq $src){throw "card 060 patch failed"};$src=$newSrc

# Main form field changes and low-level keyboard hook declarations.
$src=$src.Replace('private GlassPanel statusBox;','private StatusStripPanel statusBox;')
$src=$src.Replace('private Label brandTitle, brandSub, pcBadge, clockLabel, dateLabel, statusTitle, statusSub, footerLabel;','private Label brandTitle, brandSub, pcBadge, clockLabel, dateLabel, statusTitle, statusSub, footerLabel;
        private ClockDisplay clockDisplay;')

$hookAnchor='        private int cardBase = 170;'
$hookFields=@'
        private IntPtr keyboardHook = IntPtr.Zero;
        private LowLevelKeyboardProc keyboardProc;
        private delegate IntPtr LowLevelKeyboardProc(int nCode, IntPtr wParam, IntPtr lParam);
        private const int WH_KEYBOARD_LL=13;
        [System.Runtime.InteropServices.DllImport("user32.dll",CharSet=System.Runtime.InteropServices.CharSet.Auto,SetLastError=true)] private static extern IntPtr SetWindowsHookEx(int idHook,LowLevelKeyboardProc lpfn,IntPtr hMod,uint dwThreadId);
        [System.Runtime.InteropServices.DllImport("user32.dll",CharSet=System.Runtime.InteropServices.CharSet.Auto,SetLastError=true)] private static extern bool UnhookWindowsHookEx(IntPtr hhk);
        [System.Runtime.InteropServices.DllImport("user32.dll",CharSet=System.Runtime.InteropServices.CharSet.Auto,SetLastError=true)] private static extern IntPtr CallNextHookEx(IntPtr hhk,int nCode,IntPtr wParam,IntPtr lParam);
        [System.Runtime.InteropServices.DllImport("kernel32.dll",CharSet=System.Runtime.InteropServices.CharSet.Auto,SetLastError=true)] private static extern IntPtr GetModuleHandle(string lpModuleName);
'@
$src=Replace-Exact $src $hookAnchor ($hookAnchor+"`r`n"+$hookFields) 'hook fields 060'

# Replace status panel and clock labels with owner-drawn controls.
$src=$src.Replace('statusBox = new GlassPanel(); statusBox.Transparency=cfg.HeaderTransparency; statusBox.TopColor=Color.FromArgb(24,31,45); statusBox.BottomColor=Color.FromArgb(11,16,26); statusBox.Height=58; topHeader.Controls.Add(statusBox); statusBox.Paint += StatusBox_Paint;','statusBox = new StatusStripPanel(); statusBox.Transparency=100; statusBox.Accent=Accent; statusBox.Height=58; topHeader.Controls.Add(statusBox);')
$src=$src.Replace('statusTitle = new Label(); statusTitle.AutoSize=false; statusTitle.TextAlign=ContentAlignment.BottomCenter; statusTitle.Font=F(11,FontStyle.Bold); statusTitle.ForeColor=Color.White; statusTitle.BackColor=Color.Transparent; statusBox.Controls.Add(statusTitle);','statusTitle = new Label(); statusTitle.Visible=false; statusBox.Controls.Add(statusTitle);')
$src=$src.Replace('statusSub = new Label(); statusSub.AutoSize=false; statusSub.TextAlign=ContentAlignment.TopCenter; statusSub.Font=F(7.8f,FontStyle.Regular); statusSub.ForeColor=Color.FromArgb(170,183,205); statusSub.BackColor=Color.Transparent; statusBox.Controls.Add(statusSub);','statusSub = new Label(); statusSub.Visible=false; statusBox.Controls.Add(statusSub);')

$clockPattern='(?s)            clockLabel = new Label\(\);.*?topHeader\.Controls\.Add\(dateLabel\);'
$clockReplacement=@'
            clockLabel = new Label(); clockLabel.Visible=false; topHeader.Controls.Add(clockLabel);
            dateLabel = new Label(); dateLabel.Visible=false; topHeader.Controls.Add(dateLabel);
            clockDisplay = new ClockDisplay(); clockDisplay.Accent=Accent; topHeader.Controls.Add(clockDisplay);
'@
$newSrc=[regex]::Replace($src,$clockPattern,$clockReplacement,1)
if($newSrc -eq $src){throw "clock control 060 patch failed"};$src=$newSrc

$layoutPattern='(?s)        private void LayoutHeader\(\)\s*\{.*?\r?\n        \}\r?\n\r?\n        private void StatusBox_Paint'
$layoutReplacement=@'
        private void LayoutHeader()
        {
            int w=topHeader.ClientSize.Width;if(w<480)return;
            int btn=42;int gap=8;int right=14;
            int x=w-right-btn;powerButton.SetBounds(x,21,btn,btn);x-=btn+gap;restartButton.SetBounds(x,21,btn,btn);x-=btn+gap;adminButton.SetBounds(x,21,btn,btn);
            int clockW=190;clockDisplay.SetBounds(x-clockW-18,10,clockW,66);
            int statusLeft=30;int statusRight=w-(x-clockW-36);int statusW=Math.Max(280,w-statusLeft-statusRight);
            statusBox.SetBounds(statusLeft,14,statusW,58);statusBox.Visible=cfg.ShowStatusPanel;
        }

        private void StatusBox_Paint
'@
$newSrc=[regex]::Replace($src,$layoutPattern,$layoutReplacement,1)
if($newSrc -eq $src){throw "layout 060 patch failed"};$src=$newSrc

# Apply settings to visual globals and shell behavior.
$applyMarker='            ThemeWallpaper.CardTransparency=cfg.CardTransparency;'
$src=Replace-Exact $src $applyMarker ($applyMarker+' ThemeWallpaper.HeaderTransparency=cfg.HeaderTransparency; ThemeWallpaper.UseExeIcons=cfg.UseExeIcons; ThemeWallpaper.ShowCardCategory=cfg.ShowCardCategory;') 'apply visual flags'
$src=$src.Replace('            dateLabel.Visible=cfg.ShowDate;','            dateLabel.Visible=false; clockDisplay.ShowDate=cfg.ShowDate; clockDisplay.Accent=Accent; statusBox.Visible=cfg.ShowStatusPanel; statusBox.Accent=Accent; TopMost=cfg.AlwaysOnTop;')
$src=$src.Replace('            ApplyAutoStart();','            ApplyAutoStart(); ApplyClubMode();')

# Owner-drawn clock/status update.
$updatePattern='(?s)        private void UpdateClockAndStatus\(\)\s*\{.*?\r?\n        \}\r?\n\r?\n        private bool SessionLocked'
$updateReplacement=@'
        private void UpdateClockAndStatus()
        {
            string fmt=cfg.ShowSeconds?"HH:mm:ss":"HH:mm";clockDisplay.TimeText=DateTime.Now.ToString(fmt);clockDisplay.DateText=DateTime.Now.ToString("dd.MM.yyyy");clockDisplay.ShowDate=cfg.ShowDate;clockDisplay.Invalidate();
            bool locked=false;string session;
            if(cfg.SessionMode=="\u041F\u043E \u0432\u0440\u0435\u043C\u0435\u043D\u0438")
            {
                TimeSpan left=TimeSpan.FromMinutes(cfg.SessionMinutes)-(DateTime.Now-sessionStart);if(left.TotalSeconds<=0){locked=true;left=TimeSpan.Zero;}session="\u041E\u0421\u0422\u0410\u041B\u041E\u0421\u042C: "+String.Format("{0:00}:{1:00}:{2:00}",(int)left.TotalHours,left.Minutes,left.Seconds);
            }else session="\u0421\u0415\u0410\u041D\u0421: \u0411\u0415\u0421\u0421\u0420\u041E\u0427\u041D\u041E";
            if(locked){statusBox.TitleText="\u0421\u0415\u0410\u041D\u0421 \u0417\u0410\u0412\u0415\u0420\u0428\u0415\u041D";statusBox.TitleColor=Color.FromArgb(255,115,115);statusBox.SubText="\u0414\u041E\u0421\u0422\u0423\u041F \u041A \u0418\u0413\u0420\u0410\u041C \u0417\u0410\u0411\u041B\u041E\u041A\u0418\u0420\u041E\u0412\u0410\u041D";}
            else if(runningGame!=null&&!runningGame.HasExited){statusBox.TitleText="\u0418\u0413\u0420\u0410: "+runningGameName.ToUpper();statusBox.TitleColor=Accent;statusBox.SubText=session;}
            else{statusBox.TitleText="\u0421\u0418\u0421\u0422\u0415\u041C\u0410 \u0413\u041E\u0422\u041E\u0412\u0410";statusBox.TitleColor=Color.FromArgb(126,235,165);statusBox.SubText=session;runningGame=null;runningGameName="";}
            statusBox.Accent=Accent;statusBox.Invalidate();footerLabel.Text="\u042D\u041F\u041E\u0425\u0410 0.6.0  \u2022  \u041F\u041A \u2116"+cfg.PcNumber+"  \u2022  "+Environment.MachineName+"  \u2022  WINDOWS 7 CLUB SHELL";LayoutHeader();
        }

        private bool SessionLocked
'@
$newSrc=[regex]::Replace($src,$updatePattern,$updateReplacement,1)
if($newSrc -eq $src){throw "status update 060 patch failed"};$src=$newSrc

# Admin content scrolls on 1024x768 as well.
$src=$src.Replace('content.Dock=DockStyle.Fill;content.Transparency=12;','content.Dock=DockStyle.Fill;content.AutoScroll=true;content.Transparency=12;')

# Add visual options to Appearance page.
$appearanceInsert='            dim.Scroll+=delegate{dimVal.Text=dim.Value+"%";preview.Dim=dim.Value;preview.Invalidate();};'
$appearanceExtra=@'
            CheckBox exeIcons=new CheckBox();exeIcons.Text="\u0418\u0441\u043F\u043E\u043B\u044C\u0437\u043E\u0432\u0430\u0442\u044C \u0438\u043A\u043E\u043D\u043A\u0443 EXE, \u0435\u0441\u043B\u0438 \u043D\u0435\u0442 \u043E\u0431\u043B\u043E\u0436\u043A\u0438";exeIcons.Checked=cfg.UseExeIcons;exeIcons.SetBounds(30,714,360,24);p.Controls.Add(exeIcons);
            CheckBox showCat=new CheckBox();showCat.Text="\u041F\u043E\u043A\u0430\u0437\u044B\u0432\u0430\u0442\u044C \u0432\u043A\u043B\u0430\u0434\u043A\u0443 \u043D\u0430 \u043A\u0430\u0440\u0442\u043E\u0447\u043A\u0435";showCat.Checked=cfg.ShowCardCategory;showCat.SetBounds(410,714,300,24);p.Controls.Add(showCat);
            CheckBox showSec=new CheckBox();showSec.Text="\u041F\u043E\u043A\u0430\u0437\u044B\u0432\u0430\u0442\u044C \u0441\u0435\u043A\u0443\u043D\u0434\u044B \u0432 \u0447\u0430\u0441\u0430\u0445";showSec.Checked=cfg.ShowSeconds;showSec.SetBounds(30,744,300,24);p.Controls.Add(showSec);
            CheckBox showStatus=new CheckBox();showStatus.Text="\u041F\u043E\u043A\u0430\u0437\u044B\u0432\u0430\u0442\u044C \u0441\u0442\u0430\u0442\u0443\u0441 \u0441\u0435\u0430\u043D\u0441\u0430 \u0432 \u0446\u0435\u043D\u0442\u0440\u0435";showStatus.Checked=cfg.ShowStatusPanel;showStatus.SetBounds(410,744,320,24);p.Controls.Add(showStatus);
'@
$src=Replace-Exact $src $appearanceInsert ($appearanceExtra+$appearanceInsert) 'appearance options 060'
$src=$src.Replace('ActionButton(p,"\u0421\u041E\u0425\u0420\u0410\u041D\u0418\u0422\u042C \u0412\u041D\u0415\u0428\u041D\u0418\u0419 \u0412\u0418\u0414",30,728,220,36,delegate{','ActionButton(p,"\u0421\u041E\u0425\u0420\u0410\u041D\u0418\u0422\u042C \u0412\u041D\u0415\u0428\u041D\u0418\u0419 \u0412\u0418\u0414",30,790,220,36,delegate{')
$saveVisual='cfg.ShowDate=showDate.Checked;cfg.ShowFooter=showFooter.Checked;cfg.Save();'
$src=Replace-Exact $src $saveVisual 'cfg.ShowDate=showDate.Checked;cfg.ShowFooter=showFooter.Checked;cfg.UseExeIcons=exeIcons.Checked;cfg.ShowCardCategory=showCat.Checked;cfg.ShowSeconds=showSec.Checked;cfg.ShowStatusPanel=showStatus.Checked;cfg.Save();' 'save appearance 060'

# Replace System page with expanded service and club-mode settings.
$systemPattern='(?s)        private void BuildAdminSystem\(DbPanel p\)\s*\{.*?\r?\n        \}\r?\n\r?\n        private string InputBox'
$systemReplacement=@'
        private void BuildAdminSystem(DbPanel p)
        {
            Title(p,"\u0421\u0438\u0441\u0442\u0435\u043C\u0430");
            CheckBox auto=new CheckBox();auto.Text="\u0417\u0430\u043F\u0443\u0441\u043A\u0430\u0442\u044C \u042D\u041F\u041E\u0425\u0423 \u043F\u0440\u0438 \u0432\u0445\u043E\u0434\u0435 Windows";auto.Checked=cfg.AutoStart;auto.SetBounds(30,82,390,25);p.Controls.Add(auto);
            CheckBox top=new CheckBox();top.Text="\u0414\u0435\u0440\u0436\u0430\u0442\u044C Shell \u043F\u043E\u0432\u0435\u0440\u0445 \u0434\u0440\u0443\u0433\u0438\u0445 \u043E\u043A\u043E\u043D";top.Checked=cfg.AlwaysOnTop;top.SetBounds(30,116,390,25);p.Controls.Add(top);
            CheckBox single=new CheckBox();single.Text="\u041D\u0435 \u0437\u0430\u043F\u0443\u0441\u043A\u0430\u0442\u044C \u0432\u0442\u043E\u0440\u0443\u044E \u0438\u0433\u0440\u0443, \u043F\u043E\u043A\u0430 \u043F\u0435\u0440\u0432\u0430\u044F \u0440\u0430\u0431\u043E\u0442\u0430\u0435\u0442";single.Checked=cfg.SingleGameMode;single.SetBounds(30,150,520,25);p.Controls.Add(single);
            CheckBox explorer=new CheckBox();explorer.Text="\u0417\u0430\u043F\u0443\u0441\u043A\u0430\u0442\u044C Explorer \u043F\u0440\u0438 \u0432\u044B\u0445\u043E\u0434\u0435 \u0438\u0437 Shell";explorer.Checked=cfg.StartExplorerOnShellExit;explorer.SetBounds(30,184,460,25);p.Controls.Add(explorer);
            CheckBox confirm=new CheckBox();confirm.Text="\u041F\u043E\u0434\u0442\u0432\u0435\u0440\u0436\u0434\u0430\u0442\u044C \u0432\u044B\u043A\u043B\u044E\u0447\u0435\u043D\u0438\u0435 \u0438 \u043F\u0435\u0440\u0435\u0437\u0430\u0433\u0440\u0443\u0437\u043A\u0443 \u041F\u041A";confirm.Checked=cfg.ConfirmPower;confirm.SetBounds(30,218,510,25);p.Controls.Add(confirm);
            CheckBox task=new CheckBox();task.Text="\u0411\u043B\u043E\u043A\u0438\u0440\u043E\u0432\u0430\u0442\u044C \u0414\u0438\u0441\u043F\u0435\u0442\u0447\u0435\u0440 \u0437\u0430\u0434\u0430\u0447 \u0438 \u043B\u0438\u0448\u043D\u0438\u0435 \u043F\u0443\u043D\u043A\u0442\u044B Ctrl+Alt+Del";task.Checked=cfg.BlockTaskManager;task.SetBounds(30,252,570,25);p.Controls.Add(task);
            CheckBox keys=new CheckBox();keys.Text="\u0411\u043B\u043E\u043A\u0438\u0440\u043E\u0432\u0430\u0442\u044C Win, Alt+Tab, Alt+Esc, Alt+F4 \u0432 \u043A\u043B\u0438\u0435\u043D\u0442\u0441\u043A\u043E\u043C \u0440\u0435\u0436\u0438\u043C\u0435";keys.Checked=cfg.BlockSystemKeys;keys.SetBounds(30,286,590,25);p.Controls.Add(keys);
            CheckBox closeExp=new CheckBox();closeExp.Text="\u0417\u0430\u043A\u0440\u044B\u0432\u0430\u0442\u044C Explorer \u043F\u0440\u0438 \u0432\u043A\u043B\u044E\u0447\u0435\u043D\u0438\u0438 \u043A\u043B\u0443\u0431\u043D\u043E\u0433\u043E \u0440\u0435\u0436\u0438\u043C\u0430";closeExp.Checked=cfg.CloseExplorerInClubMode;closeExp.SetBounds(30,320,520,25);p.Controls.Add(closeExp);
            ActionButton(p,"\u0421\u041E\u0425\u0420\u0410\u041D\u0418\u0422\u042C",30,360,140,36,delegate{cfg.AutoStart=auto.Checked;cfg.AlwaysOnTop=top.Checked;cfg.SingleGameMode=single.Checked;cfg.StartExplorerOnShellExit=explorer.Checked;cfg.ConfirmPower=confirm.Checked;cfg.BlockTaskManager=task.Checked;cfg.BlockSystemKeys=keys.Checked;cfg.CloseExplorerInClubMode=closeExp.Checked;cfg.Save();ApplyConfigToUi();MessageBox.Show("\u041D\u0430\u0441\u0442\u0440\u043E\u0439\u043A\u0438 \u0441\u043E\u0445\u0440\u0430\u043D\u0435\u043D\u044B.","\u042D\u041F\u041E\u0425\u0410");});
            Label club=new Label();club.Text="\u041A\u041B\u0423\u0411\u041D\u042B\u0419 \u0420\u0415\u0416\u0418\u041C";club.SetBounds(30,420,350,28);club.Font=F(11,FontStyle.Bold);club.ForeColor=Accent;club.BackColor=Color.Transparent;p.Controls.Add(club);
            Label state=new Label();state.Text=cfg.ClubModeEnabled?"\u0421\u0422\u0410\u0422\u0423\u0421: \u0412\u041A\u041B\u042E\u0427\u0415\u041D":"\u0421\u0422\u0410\u0422\u0423\u0421: \u0412\u042B\u041A\u041B\u042E\u0427\u0415\u041D";state.SetBounds(360,424,280,24);state.Font=F(9,FontStyle.Bold);state.ForeColor=cfg.ClubModeEnabled?Color.FromArgb(126,235,165):Color.FromArgb(210,185,120);state.BackColor=Color.Transparent;p.Controls.Add(state);
            ActionButton(p,"\u0412\u041A\u041B\u042E\u0427\u0418\u0422\u042C \u041A\u041B\u0423\u0411\u041D\u042B\u0419 \u0420\u0415\u0416\u0418\u041C",30,462,230,40,delegate{SetClubMode(true);ShowAdmin("\u0421\u0438\u0441\u0442\u0435\u043C\u0430");});
            ActionButton(p,"\u0412\u042B\u041A\u041B\u042E\u0427\u0418\u0422\u042C \u041A\u041B\u0423\u0411\u041D\u042B\u0419 \u0420\u0415\u0416\u0418\u041C",272,462,240,40,delegate{SetClubMode(false);ShowAdmin("\u0421\u0438\u0441\u0442\u0435\u043C\u0430");});
            Label service=new Label();service.Text="\u041E\u0411\u0421\u041B\u0423\u0416\u0418\u0412\u0410\u041D\u0418\u0415";service.SetBounds(30,536,350,28);service.Font=F(11,FontStyle.Bold);service.ForeColor=Accent;service.BackColor=Color.Transparent;p.Controls.Add(service);
            ActionButton(p,"\u0412\u042B\u041A\u041B\u042E\u0427\u0418\u0422\u042C SHELL",30,574,180,40,delegate{ExitShellToExplorer();});ActionButton(p,"\u041E\u0422\u041A\u0420\u042B\u0422\u042C EXPLORER",222,574,180,40,delegate{OpenExplorer();});ActionButton(p,"\u041F\u0415\u0420\u0415\u0417\u0410\u041F\u0423\u0421\u0422\u0418\u0422\u042C SHELL",414,574,205,40,delegate{RestartShell();});
            ActionButton(p,"\u042D\u041A\u0421\u041F\u041E\u0420\u0422 \u041D\u0410\u0421\u0422\u0420\u041E\u0415\u041A",30,638,190,38,delegate{ExportConfig();});ActionButton(p,"\u0418\u041C\u041F\u041E\u0420\u0422 \u041D\u0410\u0421\u0422\u0420\u041E\u0415\u041A",232,638,190,38,delegate{ImportConfig();});
            Label info=new Label();info.Text="Ctrl + Alt + E  -  admin login. Ctrl+Alt+Del itself is a protected Windows sequence; EPOHA restricts the available actions through user policies.";info.SetBounds(30,700,760,50);info.ForeColor=Color.FromArgb(180,194,216);info.BackColor=Color.Transparent;p.Controls.Add(info);
        }

        private string InputBox
'@
$newSrc=[regex]::Replace($src,$systemPattern,$systemReplacement,1)
if($newSrc -eq $src){throw "system page 060 patch failed"};$src=$newSrc

$methodsAnchor='        private void OpenExplorer()'
$clubMethods=@'
        private void SetClubMode(bool enabled)
        {
            if(enabled&&MessageBox.Show("\u0412\u043A\u043B\u044E\u0447\u0438\u0442\u044C \u043A\u043B\u0443\u0431\u043D\u044B\u0439 \u0440\u0435\u0436\u0438\u043C? \u041E\u0433\u0440\u0430\u043D\u0438\u0447\u0435\u043D\u0438\u044F \u043F\u0440\u0438\u043C\u0435\u043D\u044F\u044E\u0442\u0441\u044F \u0442\u043E\u043B\u044C\u043A\u043E \u043A \u0442\u0435\u043A\u0443\u0449\u0435\u043C\u0443 \u043F\u043E\u043B\u044C\u0437\u043E\u0432\u0430\u0442\u0435\u043B\u044E.","\u042D\u041F\u041E\u0425\u0410",MessageBoxButtons.YesNo,MessageBoxIcon.Question)!=DialogResult.Yes)return;
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
                if(cfg.ClubModeEnabled&&cfg.CloseExplorerInClubMode)CloseExplorer();
            }
            catch(Exception ex){File.AppendAllText(Program.LogPath,"ClubMode: "+ex+"\r\n");}
        }

        private void SetTaskManagerPolicy(bool enabled)
        {
            using(RegistryKey k=Registry.CurrentUser.CreateSubKey(@"Software\Microsoft\Windows\CurrentVersion\Policies\System"))
            {
                if(enabled){k.SetValue("DisableTaskMgr",1,RegistryValueKind.DWord);k.SetValue("DisableLockWorkstation",1,RegistryValueKind.DWord);k.SetValue("DisableChangePassword",1,RegistryValueKind.DWord);}else{k.DeleteValue("DisableTaskMgr",false);k.DeleteValue("DisableLockWorkstation",false);k.DeleteValue("DisableChangePassword",false);}
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

        private void ExportConfig()
        {
            try{using(SaveFileDialog d=new SaveFileDialog()){d.Filter="EPOHA config|*.xml";d.FileName="epoha-config-PC"+cfg.PcNumber+".xml";if(d.ShowDialog()!=DialogResult.OK)return;cfg.Save();File.Copy(Program.ConfigPath,d.FileName,true);MessageBox.Show("\u041D\u0430\u0441\u0442\u0440\u043E\u0439\u043A\u0438 \u044D\u043A\u0441\u043F\u043E\u0440\u0442\u0438\u0440\u043E\u0432\u0430\u043D\u044B.","\u042D\u041F\u041E\u0425\u0410");}}catch(Exception ex){MessageBox.Show(ex.Message,"EPOHA",MessageBoxButtons.OK,MessageBoxIcon.Error);}
        }

        private void ImportConfig()
        {
            try{using(OpenFileDialog d=new OpenFileDialog()){d.Filter="EPOHA config|*.xml|All files|*.*";if(d.ShowDialog()!=DialogResult.OK)return;File.Copy(d.FileName,Program.ConfigPath,true);MessageBox.Show("\u041D\u0430\u0441\u0442\u0440\u043E\u0439\u043A\u0438 \u0438\u043C\u043F\u043E\u0440\u0442\u0438\u0440\u043E\u0432\u0430\u043D\u044B. Shell \u0431\u0443\u0434\u0435\u0442 \u043F\u0435\u0440\u0435\u0437\u0430\u043F\u0443\u0449\u0435\u043D.","\u042D\u041F\u041E\u0425\u0410");RestartShell();}}catch(Exception ex){MessageBox.Show(ex.Message,"EPOHA",MessageBoxButtons.OK,MessageBoxIcon.Error);}
        }

'@
$src=Replace-Exact $src $methodsAnchor ($clubMethods+$methodsAnchor) 'club methods 060'

# Deliberate Shell exit always restores the user policies first.
$exitPattern='(?s)        private void ExitShellToExplorer\(\)\s*\{.*?\r?\n        \}'
$exitReplacement=@'
        private void ExitShellToExplorer()
        {
            if(MessageBox.Show("\u0412\u044B\u043A\u043B\u044E\u0447\u0438\u0442\u044C Shell \u0438 \u043F\u0435\u0440\u0435\u0439\u0442\u0438 \u0432 \u043E\u0431\u044B\u0447\u043D\u0443\u044E Windows?","\u042D\u041F\u041E\u0425\u0410",MessageBoxButtons.YesNo,MessageBoxIcon.Question)!=DialogResult.Yes)return;
            cfg.ClubModeEnabled=false;cfg.Save();SetTaskManagerPolicy(false);SetKeyboardHook(false);if(cfg.StartExplorerOnShellExit)OpenExplorer();Application.Exit();
        }
'@
$newSrc=[regex]::Replace($src,$exitPattern,$exitReplacement,1)
if($newSrc -eq $src){throw "exit shell 060 patch failed"};$src=$newSrc

Set-Content -Path ProgramV060Build.cs -Value $src -Encoding UTF8
