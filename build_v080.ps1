$ErrorActionPreference = "Stop"

# Build the known-good 0.7 source first, then perform the 0.8 visual refactor.
.\build_v070_fix.ps1
$src = Get-Content ProgramV070Build.cs -Raw -Encoding UTF8
$src = $src.Replace('0.7.0','0.8.0')

function Replace-Regex([string]$pattern,[string]$replacement,[string]$name) {
    $script:newSrc = [regex]::Replace($script:src,$pattern,$replacement,1,[System.Text.RegularExpressions.RegexOptions]::Singleline)
    if($script:newSrc -eq $script:src){ throw ("0.8 patch failed: " + $name) }
    $script:src = $script:newSrc
}

# One seamless dark glass surface. No internal panel lines or decorative plates.
$glassPanel = @'
    public class GlassPanel : DbPanel
    {
        public Color TopColor = Color.FromArgb(24,30,43);
        public Color BottomColor = Color.FromArgb(12,16,25);
        public int Transparency = 20;
        protected override void OnPaintBackground(PaintEventArgs e)
        {
            ThemeWallpaper.DrawBase(e.Graphics,this,TopColor,BottomColor);
            int t=Math.Max(0,Math.Min(100,Transparency));
            int alpha=160+(100-t)*75/100;
            using(SolidBrush shade=new SolidBrush(Color.FromArgb(alpha,8,12,19)))
                e.Graphics.FillRectangle(shade,ClientRectangle);
        }
    }

    public class GlassFlow
'@
Replace-Regex '    public class GlassPanel : DbPanel.*?    public class GlassFlow' $glassPanel 'GlassPanel'

$glassFlow = @'
    public class GlassFlow : FlowLayoutPanel
    {
        public int Transparency = 20;
        public Color TopColor = Color.FromArgb(24,30,43);
        public Color BottomColor = Color.FromArgb(12,16,25);
        public GlassFlow(){SetStyle(ControlStyles.AllPaintingInWmPaint|ControlStyles.UserPaint|ControlStyles.OptimizedDoubleBuffer,true);UpdateStyles();}
        protected override void OnPaintBackground(PaintEventArgs e)
        {
            ThemeWallpaper.DrawBase(e.Graphics,this,TopColor,BottomColor);
            int t=Math.Max(0,Math.Min(100,Transparency));
            int alpha=160+(100-t)*75/100;
            using(SolidBrush shade=new SolidBrush(Color.FromArgb(alpha,8,12,19)))
                e.Graphics.FillRectangle(shade,ClientRectangle);
        }
    }

    public class ClubButton
'@
Replace-Regex '    public class GlassFlow : FlowLayoutPanel.*?    public class ClubButton' $glassFlow 'GlassFlow'

$clubButton = @'
    public class ClubButton : Button
    {
        public Color Accent = Color.MediumPurple;
        private bool hover; private bool down;
        public ClubButton(){FlatStyle=FlatStyle.Flat;FlatAppearance.BorderSize=0;Cursor=Cursors.Hand;SetStyle(ControlStyles.UserPaint|ControlStyles.AllPaintingInWmPaint|ControlStyles.OptimizedDoubleBuffer,true);}
        protected override void OnMouseEnter(EventArgs e){hover=true;Invalidate();base.OnMouseEnter(e);}
        protected override void OnMouseLeave(EventArgs e){hover=false;down=false;Invalidate();base.OnMouseLeave(e);}
        protected override void OnMouseDown(MouseEventArgs e){down=true;Invalidate();base.OnMouseDown(e);}
        protected override void OnMouseUp(MouseEventArgs e){down=false;Invalidate();base.OnMouseUp(e);}
        protected override void OnPaint(PaintEventArgs e)
        {
            e.Graphics.SmoothingMode=SmoothingMode.AntiAlias;
            Rectangle r=new Rectangle(1,1,Width-3,Height-3);
            Color top=hover?Color.FromArgb(57,67,88):Color.FromArgb(39,47,64);
            Color bottom=hover?Color.FromArgb(24,30,43):Color.FromArgb(18,23,34);
            if(down){top=Color.FromArgb(24,30,43);bottom=Color.FromArgb(13,17,26);}
            using(GraphicsPath gp=UiPaint.RoundRect(r,7))
            using(LinearGradientBrush b=new LinearGradientBrush(r,top,bottom,LinearGradientMode.Vertical))e.Graphics.FillPath(b,gp);
            if(hover)using(GraphicsPath gp=UiPaint.RoundRect(r,7))using(Pen p=new Pen(Color.FromArgb(95,Accent),1f))e.Graphics.DrawPath(p,gp);
            TextRenderer.DrawText(e.Graphics,Text,Font,r,ForeColor,TextFormatFlags.HorizontalCenter|TextFormatFlags.VerticalCenter|TextFormatFlags.EndEllipsis);
        }
    }
    public class GlobalWallpaperPanel
'@
Replace-Regex '    public class ClubButton : Button.*?    public class GlobalWallpaperPanel' $clubButton 'ClubButton'

$clock = @'
    public class ClockDisplay : Control
    {
        public string TimeText="00:00:00";public string DateText="00.00.0000";public bool ShowDate=true;public Color Accent=Color.MediumPurple;
        public ClockDisplay(){Size=new Size(188,64);SetStyle(ControlStyles.UserPaint|ControlStyles.AllPaintingInWmPaint|ControlStyles.OptimizedDoubleBuffer,true);}
        protected override void OnPaintBackground(PaintEventArgs e)
        {
            ThemeWallpaper.DrawBase(e.Graphics,this,Color.FromArgb(24,30,43),Color.FromArgb(12,16,25));
            int t=Math.Max(0,Math.Min(100,ThemeWallpaper.HeaderTransparency));int alpha=160+(100-t)*75/100;
            using(SolidBrush shade=new SolidBrush(Color.FromArgb(alpha,8,12,19)))e.Graphics.FillRectangle(shade,ClientRectangle);
        }
        protected override void OnPaint(PaintEventArgs e)
        {
            Rectangle timeRect=new Rectangle(0,0,Width,39);Rectangle dateRect=new Rectangle(0,39,Width,22);
            using(Font ft=new Font("Tahoma",20.5f,FontStyle.Bold))TextRenderer.DrawText(e.Graphics,TimeText,ft,timeRect,Color.White,TextFormatFlags.Right|TextFormatFlags.VerticalCenter|TextFormatFlags.NoPadding);
            if(ShowDate)using(Font fd=new Font("Tahoma",9.5f,FontStyle.Bold))TextRenderer.DrawText(e.Graphics,DateText,fd,dateRect,Color.FromArgb(190,202,220),TextFormatFlags.Right|TextFormatFlags.VerticalCenter|TextFormatFlags.NoPadding);
        }
    }

    public class StatusStripPanel
'@
Replace-Regex '    public class ClockDisplay : Control.*?    public class StatusStripPanel' $clock 'ClockDisplay'

$status = @'
    public class StatusStripPanel : DbPanel
    {
        public string TitleText="";public string SubText="";public Color TitleColor=Color.White;public Color Accent=Color.MediumPurple;public int Transparency=100;
        public StatusStripPanel(){SetStyle(ControlStyles.UserPaint|ControlStyles.AllPaintingInWmPaint|ControlStyles.OptimizedDoubleBuffer,true);}
        protected override void OnPaintBackground(PaintEventArgs e)
        {
            ThemeWallpaper.DrawBase(e.Graphics,this,Color.FromArgb(24,30,43),Color.FromArgb(12,16,25));
            int t=Math.Max(0,Math.Min(100,ThemeWallpaper.HeaderTransparency));int alpha=160+(100-t)*75/100;
            using(SolidBrush shade=new SolidBrush(Color.FromArgb(alpha,8,12,19)))e.Graphics.FillRectangle(shade,ClientRectangle);
        }
        protected override void OnPaint(PaintEventArgs e)
        {
            e.Graphics.SmoothingMode=SmoothingMode.AntiAlias;int cy=Height/2;
            using(SolidBrush glow=new SolidBrush(Color.FromArgb(34,TitleColor)))e.Graphics.FillEllipse(glow,16,cy-7,14,14);
            using(SolidBrush dot=new SolidBrush(TitleColor))e.Graphics.FillEllipse(dot,20,cy-3,6,6);
            Rectangle a=new Rectangle(40,3,Width-54,25);Rectangle b=new Rectangle(40,28,Width-54,18);
            using(Font f1=new Font("Tahoma",10.8f,FontStyle.Bold))TextRenderer.DrawText(e.Graphics,TitleText,f1,a,TitleColor,TextFormatFlags.HorizontalCenter|TextFormatFlags.VerticalCenter|TextFormatFlags.EndEllipsis);
            using(Font f2=new Font("Tahoma",7.5f,FontStyle.Regular))TextRenderer.DrawText(e.Graphics,SubText,f2,b,Color.FromArgb(175,190,212),TextFormatFlags.HorizontalCenter|TextFormatFlags.VerticalCenter|TextFormatFlags.EndEllipsis);
        }
    }
    public class BrandMark
'@
Replace-Regex '    public class StatusStripPanel : DbPanel.*?    public class BrandMark' $status 'StatusStripPanel'

$brand = @'
    public class BrandMark : Control
    {
        public Color Accent=Color.FromArgb(120,80,230);
        public BrandMark(){Size=new Size(50,50);SetStyle(ControlStyles.UserPaint|ControlStyles.AllPaintingInWmPaint|ControlStyles.OptimizedDoubleBuffer,true);}
        protected override void OnPaintBackground(PaintEventArgs e)
        {
            ThemeWallpaper.DrawBase(e.Graphics,this,Color.FromArgb(24,30,43),Color.FromArgb(12,16,25));
            int t=Math.Max(0,Math.Min(100,ThemeWallpaper.HeaderTransparency));int alpha=160+(100-t)*75/100;
            using(SolidBrush shade=new SolidBrush(Color.FromArgb(alpha,8,12,19)))e.Graphics.FillRectangle(shade,ClientRectangle);
        }
        protected override void OnPaint(PaintEventArgs e)
        {
            e.Graphics.SmoothingMode=SmoothingMode.AntiAlias;
            using(SolidBrush a=new SolidBrush(Accent))e.Graphics.FillRectangle(a,1,10,3,30);
            Rectangle tx=new Rectangle(7,0,Width-8,Height);
            using(Font f=new Font("Tahoma",22,FontStyle.Bold))TextRenderer.DrawText(e.Graphics,"Э",f,tx,Color.White,TextFormatFlags.HorizontalCenter|TextFormatFlags.VerticalCenter|TextFormatFlags.NoPadding);
        }
    }

    public class GamesHeader
'@
Replace-Regex '    public class BrandMark : Control.*?    public class GamesHeader' $brand 'BrandMark'

$gamesHeader = @'
    public class GamesHeader : Control
    {
        public string TitleText="";public string SubText="";public Color Accent=Color.MediumPurple;
        public GamesHeader(){Height=64;SetStyle(ControlStyles.UserPaint|ControlStyles.AllPaintingInWmPaint|ControlStyles.OptimizedDoubleBuffer,true);}
        protected override void OnPaintBackground(PaintEventArgs e)
        {
            ThemeWallpaper.DrawBase(e.Graphics,this,Color.FromArgb(9,12,19),Color.FromArgb(9,12,19));
            Rectangle r=ClientRectangle;using(LinearGradientBrush g=new LinearGradientBrush(r,Color.FromArgb(90,5,8,14),Color.FromArgb(0,5,8,14),LinearGradientMode.Horizontal))e.Graphics.FillRectangle(g,r);
        }
        protected override void OnPaint(PaintEventArgs e)
        {
            e.Graphics.SmoothingMode=SmoothingMode.AntiAlias;
            using(SolidBrush a=new SolidBrush(Accent))e.Graphics.FillRectangle(a,26,17,3,30);
            Rectangle t=new Rectangle(42,7,Width-68,31);Rectangle ss=new Rectangle(43,37,Width-68,18);
            using(Font f1=new Font("Tahoma",14.5f,FontStyle.Bold))TextRenderer.DrawText(e.Graphics,TitleText,f1,t,Color.White,TextFormatFlags.Left|TextFormatFlags.VerticalCenter|TextFormatFlags.EndEllipsis);
            using(Font f2=new Font("Tahoma",7.7f,FontStyle.Regular))TextRenderer.DrawText(e.Graphics,SubText,f2,ss,Color.FromArgb(170,185,207),TextFormatFlags.Left|TextFormatFlags.VerticalCenter|TextFormatFlags.EndEllipsis);
        }
    }

    public class EpohaGamesFlow
'@
Replace-Regex '    public class GamesHeader : Control.*?    public class EpohaGamesFlow' $gamesHeader 'GamesHeader'

$nav = @'
    public class NavButton : Control
    {
        public bool Selected;public Color Accent=Color.MediumPurple;private bool hover;
        public NavButton(){Height=43;Cursor=Cursors.Hand;SetStyle(ControlStyles.UserPaint|ControlStyles.AllPaintingInWmPaint|ControlStyles.OptimizedDoubleBuffer,true);}
        protected override void OnMouseEnter(EventArgs e){hover=true;Invalidate();base.OnMouseEnter(e);}protected override void OnMouseLeave(EventArgs e){hover=false;Invalidate();base.OnMouseLeave(e);}
        protected override void OnPaintBackground(PaintEventArgs e)
        {
            ThemeWallpaper.DrawBase(e.Graphics,this,Color.FromArgb(24,30,43),Color.FromArgb(12,16,25));
            int t=Math.Max(0,Math.Min(100,ThemeWallpaper.SidebarTransparency));int alpha=160+(100-t)*75/100;
            using(SolidBrush shade=new SolidBrush(Color.FromArgb(alpha,8,12,19)))e.Graphics.FillRectangle(shade,ClientRectangle);
        }
        protected override void OnPaint(PaintEventArgs e)
        {
            e.Graphics.SmoothingMode=SmoothingMode.AntiAlias;
            if(Selected)
            {
                using(LinearGradientBrush hi=new LinearGradientBrush(ClientRectangle,Color.FromArgb(50,Accent),Color.FromArgb(0,Accent),LinearGradientMode.Horizontal))e.Graphics.FillRectangle(hi,ClientRectangle);
                using(SolidBrush a=new SolidBrush(Accent))e.Graphics.FillRectangle(a,0,8,3,Height-16);
            }
            else if(hover)using(LinearGradientBrush hi=new LinearGradientBrush(ClientRectangle,Color.FromArgb(24,255,255,255),Color.FromArgb(0,255,255,255),LinearGradientMode.Horizontal))e.Graphics.FillRectangle(hi,ClientRectangle);
            Rectangle tx=new Rectangle(20,0,Width-30,Height);
            using(Font f=new Font("Tahoma",9.2f,Selected?FontStyle.Bold:FontStyle.Regular))TextRenderer.DrawText(e.Graphics,Text,f,tx,Selected?Color.White:Color.FromArgb(218,226,239),TextFormatFlags.Left|TextFormatFlags.VerticalCenter|TextFormatFlags.EndEllipsis);
        }
    }
    public class IconButton
'@
Replace-Regex '    public class NavButton : Control.*?    public class IconButton' $nav 'NavButton'

$icons = @'
    public class IconButton : Control
    {
        public enum IconKind{Admin,Restart,Power}public IconKind Kind;public Color Accent=Color.MediumPurple;private bool hover;private bool down;
        public IconButton(IconKind kind){Kind=kind;Size=new Size(38,38);Cursor=Cursors.Hand;SetStyle(ControlStyles.UserPaint|ControlStyles.OptimizedDoubleBuffer|ControlStyles.AllPaintingInWmPaint,true);}
        protected override void OnMouseEnter(EventArgs e){hover=true;Invalidate();base.OnMouseEnter(e);}protected override void OnMouseLeave(EventArgs e){hover=false;down=false;Invalidate();base.OnMouseLeave(e);}protected override void OnMouseDown(MouseEventArgs e){down=true;Invalidate();base.OnMouseDown(e);}protected override void OnMouseUp(MouseEventArgs e){down=false;Invalidate();base.OnMouseUp(e);}
        protected override void OnPaintBackground(PaintEventArgs e)
        {
            ThemeWallpaper.DrawBase(e.Graphics,this,Color.FromArgb(24,30,43),Color.FromArgb(12,16,25));
            int t=Math.Max(0,Math.Min(100,ThemeWallpaper.HeaderTransparency));int alpha=160+(100-t)*75/100;
            using(SolidBrush shade=new SolidBrush(Color.FromArgb(alpha,8,12,19)))e.Graphics.FillRectangle(shade,ClientRectangle);
        }
        protected override void OnPaint(PaintEventArgs e)
        {
            e.Graphics.SmoothingMode=SmoothingMode.AntiAlias;
            if(hover)using(SolidBrush halo=new SolidBrush(Color.FromArgb(down?42:28,Accent)))e.Graphics.FillEllipse(halo,2,2,Width-5,Height-5);
            Color ic=hover?Color.White:Color.FromArgb(210,221,238);if(down)ic=Color.FromArgb(170,185,205);
            using(Pen p=new Pen(ic,2f))
            {
                if(Kind==IconKind.Power){e.Graphics.DrawArc(p,9,9,20,20,-55,290);e.Graphics.DrawLine(p,19,6,19,20);}
                else if(Kind==IconKind.Restart){e.Graphics.DrawArc(p,7,8,23,23,28,292);Point[]q={new Point(29,7),new Point(30,15),new Point(22,12)};using(SolidBrush ss=new SolidBrush(ic))e.Graphics.FillPolygon(ss,q);}
                else{e.Graphics.DrawEllipse(p,14,8,10,10);e.Graphics.DrawArc(p,9,18,20,15,195,150);}
            }
        }
    }
    public class GameCard
'@
Replace-Regex '    public class IconButton : Control.*?    public class GameCard' $icons 'IconButton'

# Fallback visual: clean play symbol instead of giant monogram letters.
$src = [regex]::Replace($src,'string monogram=String\.IsNullOrEmpty\(Game\.Name\)\?"\?":Game\.Name\.Substring\(0,1\)\.ToUpper\(\);\s*using\(SolidBrush glow=.*?TextRenderer\.DrawText\(e\.Graphics,monogram,mf,mr,Color\.FromArgb\(205,220,228,240\),TextFormatFlags\.HorizontalCenter\|TextFormatFlags\.VerticalCenter\|TextFormatFlags\.NoPadding\);',@'
using(SolidBrush glow=new SolidBrush(Color.FromArgb(30,Accent)))e.Graphics.FillEllipse(glow,art.X+art.Width/2-35,art.Y+art.Height/2-35,70,70);
                    Point[] tri={new Point(art.X+art.Width/2-8,art.Y+art.Height/2-15),new Point(art.X+art.Width/2-8,art.Y+art.Height/2+15),new Point(art.X+art.Width/2+16,art.Y+art.Height/2)};
                    using(SolidBrush pb=new SolidBrush(Color.FromArgb(215,230,237,247)))e.Graphics.FillPolygon(pb,tri);
'@,1,[System.Text.RegularExpressions.RegexOptions]::Singleline)

# Remove the constant card border; hover gets only a soft glow and top accent.
$src = $src.Replace('using(GraphicsPath gp=UiPaint.RoundRect(r,9))using(Pen border=new Pen(hover?Color.FromArgb(180,Accent):Color.FromArgb(60,71,92),hover?1.4f:1f))e.Graphics.DrawPath(border,gp);' + "`r`n" + '            if(hover)using(Pen top=new Pen(Color.FromArgb(160,Accent),1.6f))e.Graphics.DrawLine(top,r.X+13,r.Y+2,r.Right-13,r.Y+2);',@'
if(hover)
            {
                using(GraphicsPath gp=UiPaint.RoundRect(r,9))using(Pen glow=new Pen(Color.FromArgb(70,Accent),2.2f))e.Graphics.DrawPath(glow,gp);
                using(Pen top=new Pen(Color.FromArgb(210,Accent),1.7f))e.Graphics.DrawLine(top,r.X+15,r.Y+2,r.Right-15,r.Y+2);
            }
'@)

# Chrome geometry/hierarchy.
$src = $src.Replace('root.RowCount=3; root.RowStyles.Add(new RowStyle(SizeType.Absolute,86));','root.RowCount=3; root.RowStyles.Add(new RowStyle(SizeType.Absolute,82));')
$src = $src.Replace('brandHeader = new GlassPanel(); brandHeader.Dock=DockStyle.Fill; brandHeader.Margin=new Padding(0); brandHeader.TopColor=Color.FromArgb(25,30,43); brandHeader.BottomColor=Color.FromArgb(11,15,24);','brandHeader = new GlassPanel(); brandHeader.Dock=DockStyle.Fill; brandHeader.Margin=new Padding(0); brandHeader.TopColor=Color.FromArgb(24,30,43); brandHeader.BottomColor=Color.FromArgb(12,16,25);')
$src = $src.Replace('BrandMark logo = new BrandMark(); logo.Accent=Accent; logo.SetBounds(14,15,50,50); brandHeader.Controls.Add(logo);','BrandMark logo = new BrandMark(); logo.Accent=Accent; logo.SetBounds(13,16,48,48); brandHeader.Controls.Add(logo);')
$src = $src.Replace('brandTitle.SetBounds(76,7,172,29); brandTitle.Font=F(18,FontStyle.Bold); brandTitle.ForeColor=Accent;','brandTitle.SetBounds(72,8,176,27); brandTitle.Font=F(17,FontStyle.Bold); brandTitle.ForeColor=Color.White;')
$src = $src.Replace('brandSub.SetBounds(77,37,180,15);','brandSub.SetBounds(73,34,185,15);')
$src = $src.Replace('eraLabel.SetBounds(77,53,92,18);','eraLabel.SetBounds(73,51,92,18);')
$src = [regex]::Replace($src,'pcBadge = new Label\(\); pcBadge\.AutoSize=false; pcBadge\.SetBounds\(170,54,88,21\);.*?brandHeader\.Controls\.Add\(pcBadge\);','pcBadge = new Label(); pcBadge.AutoSize=false; pcBadge.SetBounds(164,51,94,18); pcBadge.TextAlign=ContentAlignment.MiddleRight; pcBadge.Font=F(7.8f,FontStyle.Bold); pcBadge.ForeColor=Color.FromArgb(205,216,233); pcBadge.BackColor=Color.Transparent; brandHeader.Controls.Add(pcBadge);',1,[System.Text.RegularExpressions.RegexOptions]::Singleline)
$src = $src.Replace('topHeader = new GlassPanel(); topHeader.Dock=DockStyle.Fill; topHeader.Margin=new Padding(0); topHeader.TopColor=Color.FromArgb(29,35,49); topHeader.BottomColor=Color.FromArgb(14,18,28);','topHeader = new GlassPanel(); topHeader.Dock=DockStyle.Fill; topHeader.Margin=new Padding(0); topHeader.TopColor=Color.FromArgb(24,30,43); topHeader.BottomColor=Color.FromArgb(12,16,25);')
$src = $src.Replace('statusBox = new StatusStripPanel(); statusBox.Transparency=100; statusBox.Accent=Accent; statusBox.Height=58;','statusBox = new StatusStripPanel(); statusBox.Transparency=100; statusBox.Accent=Accent; statusBox.Height=52;')
$src = $src.Replace('navList = new GlassFlow(); navList.FlowDirection=FlowDirection.TopDown; navList.WrapContents=false; navList.AutoScroll=true; navList.Transparency=cfg.HeaderTransparency; navList.SetBounds(10,12,265,ClientSize.Height-112);','navList = new GlassFlow(); navList.FlowDirection=FlowDirection.TopDown; navList.WrapContents=false; navList.AutoScroll=true; navList.Transparency=cfg.HeaderTransparency; navList.SetBounds(12,14,261,ClientSize.Height-112);')
$src = $src.Replace('footerLabel.ForeColor=Color.FromArgb(115,129,153);','footerLabel.ForeColor=Color.FromArgb(95,110,134);')

# One shared transparency value for header + left menu.
$src = $src.Replace('ThemeWallpaper.SidebarTransparency=cfg.SidebarTransparency;','ThemeWallpaper.SidebarTransparency=cfg.HeaderTransparency;')
$src = $src.Replace('brandTitle.ForeColor=Accent; adminButton.Accent=Accent;','brandTitle.ForeColor=Color.White; adminButton.Accent=Accent;')
$src = $src.Replace('navHost.Transparency=cfg.SidebarTransparency; navList.Transparency=cfg.HeaderTransparency; statusBox.Transparency=cfg.HeaderTransparency;','navHost.Transparency=cfg.HeaderTransparency; navList.Transparency=cfg.HeaderTransparency; statusBox.Transparency=cfg.HeaderTransparency;')

$src = $src.Replace('NavButton b=new NavButton(); b.Text=name; b.Width=245; b.Accent=Accent;','NavButton b=new NavButton(); b.Text=name; b.Width=Math.Max(180,navList.ClientSize.Width-6); b.Margin=new Padding(0,1,0,1); b.Accent=Accent;')
$src = $src.Replace('gh.Dock=DockStyle.Top;gh.Height=72;','gh.Dock=DockStyle.Top;gh.Height=64;')
$src = $src.Replace('grid.Padding=new Padding(24,14,24,26);','grid.Padding=new Padding(24,12,24,26);')

$layoutHeader = @'
        private void LayoutHeader()
        {
            int w=topHeader.ClientSize.Width;if(w<480)return;
            int btn=38;int gap=7;int right=12;
            int x=w-right-btn;powerButton.SetBounds(x,22,btn,btn);x-=btn+gap;restartButton.SetBounds(x,22,btn,btn);x-=btn+gap;adminButton.SetBounds(x,22,btn,btn);
            int clockW=176;clockDisplay.SetBounds(x-clockW-20,9,clockW,64);
            int statusLeft=42;int statusRight=w-(x-clockW-42);int statusW=Math.Max(300,w-statusLeft-statusRight);
            statusBox.SetBounds(statusLeft,15,statusW,52);statusBox.Visible=cfg.ShowStatusPanel;
        }

        private void StatusBox_Paint
'@
Replace-Regex '        private void LayoutHeader\(\).*?        private void StatusBox_Paint' $layoutHeader 'LayoutHeader'

# Admin is one clean sheet. Remove title/caption rectangles.
$src = $src.Replace('shell.BackColor=Color.FromArgb(12,16,25);','shell.BackColor=Color.FromArgb(8,12,19);')
$src = $src.Replace('menu.Transparency=Math.Max(0,Math.Min(75,cfg.SidebarTransparency+8));','menu.Transparency=cfg.HeaderTransparency;')
$src = $src.Replace('cap.BackColor=Color.FromArgb(22,29,43);','cap.BackColor=Color.Transparent;')
$src = $src.Replace('private Label Title(DbPanel p,string text){Label l=new Label();l.Text=text.ToUpper();l.SetBounds(28,22,650,36);l.Font=F(16,FontStyle.Bold);l.ForeColor=Color.White;l.BackColor=p.BackColor;p.Controls.Add(l);return l;}','private Label Title(DbPanel p,string text){Label l=new Label();l.Text=text.ToUpper();l.SetBounds(28,22,650,36);l.Font=F(16,FontStyle.Bold);l.ForeColor=Color.White;l.BackColor=Color.Transparent;p.Controls.Add(l);return l;}')
$src = $src.Replace('private Label FieldLabel(DbPanel p,string text,int y){Label l=new Label();l.Text=text;l.SetBounds(30,y,220,20);l.Font=F(8,FontStyle.Regular);l.ForeColor=Color.FromArgb(165,177,198);l.BackColor=p.BackColor;p.Controls.Add(l);return l;}','private Label FieldLabel(DbPanel p,string text,int y){Label l=new Label();l.Text=text;l.SetBounds(30,y,260,20);l.Font=F(8,FontStyle.Regular);l.ForeColor=Color.FromArgb(165,177,198);l.BackColor=Color.Transparent;p.Controls.Add(l);return l;}')
$src = $src.Replace('Label l=new Label();l.Text=text;l.SetBounds(x,y,w,24);l.Font=F(8,FontStyle.Bold);l.ForeColor=Accent;l.BackColor=Color.FromArgb(18,24,37);p.Controls.Add(l);return l;','Label l=new Label();l.Text=text;l.SetBounds(x,y,w,24);l.Font=F(8,FontStyle.Bold);l.ForeColor=Accent;l.BackColor=Color.Transparent;p.Controls.Add(l);return l;')

Set-Content -Path ProgramV080Build.cs -Value $src -Encoding UTF8
