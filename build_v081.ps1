$ErrorActionPreference = "Stop"

.\build_v070_fix.ps1
$src = Get-Content ProgramV070Build.cs -Raw -Encoding UTF8
$src = $src.Replace('0.7.0','0.8.1')

function Replace-One([string]$pattern,[string]$replacement,[string]$name) {
    $rx = New-Object System.Text.RegularExpressions.Regex($pattern,[System.Text.RegularExpressions.RegexOptions]::Singleline)
    $newSrc = $rx.Replace($script:src,$replacement,1)
    if($newSrc -eq $script:src){ throw ("0.8.1 patch failed: " + $name) }
    $script:src = $newSrc
}

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
            int alpha=158+(100-t)*77/100;
            using(SolidBrush shade=new SolidBrush(Color.FromArgb(alpha,8,12,19)))e.Graphics.FillRectangle(shade,ClientRectangle);
        }
    }

    public class GlassFlow
'@
Replace-One '    public class GlassPanel : DbPanel.*?    public class GlassFlow' $glassPanel 'GlassPanel'

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
            int alpha=158+(100-t)*77/100;
            using(SolidBrush shade=new SolidBrush(Color.FromArgb(alpha,8,12,19)))e.Graphics.FillRectangle(shade,ClientRectangle);
        }
    }

    public class ClubButton
'@
Replace-One '    public class GlassFlow : FlowLayoutPanel.*?    public class ClubButton' $glassFlow 'GlassFlow'

$clubButton = @'
    public class ClubButton : Button
    {
        public Color Accent = Color.MediumPurple;
        private bool hover;private bool down;
        public ClubButton(){FlatStyle=FlatStyle.Flat;FlatAppearance.BorderSize=0;Cursor=Cursors.Hand;SetStyle(ControlStyles.UserPaint|ControlStyles.AllPaintingInWmPaint|ControlStyles.OptimizedDoubleBuffer,true);}
        protected override void OnMouseEnter(EventArgs e){hover=true;Invalidate();base.OnMouseEnter(e);}
        protected override void OnMouseLeave(EventArgs e){hover=false;down=false;Invalidate();base.OnMouseLeave(e);}
        protected override void OnMouseDown(MouseEventArgs e){down=true;Invalidate();base.OnMouseDown(e);}
        protected override void OnMouseUp(MouseEventArgs e){down=false;Invalidate();base.OnMouseUp(e);}
        protected override void OnPaint(PaintEventArgs e)
        {
            e.Graphics.SmoothingMode=SmoothingMode.AntiAlias;
            Rectangle r=new Rectangle(1,1,Width-3,Height-3);
            Color top=hover?Color.FromArgb(53,63,82):Color.FromArgb(34,41,56);
            Color bottom=hover?Color.FromArgb(24,30,43):Color.FromArgb(16,21,31);
            if(down){top=Color.FromArgb(22,28,39);bottom=Color.FromArgb(11,15,23);}
            using(GraphicsPath gp=UiPaint.RoundRect(r,6))using(LinearGradientBrush b=new LinearGradientBrush(r,top,bottom,LinearGradientMode.Vertical))e.Graphics.FillPath(b,gp);
            if(hover)using(GraphicsPath gp=UiPaint.RoundRect(r,6))using(Pen p=new Pen(Color.FromArgb(85,Accent),1f))e.Graphics.DrawPath(p,gp);
            TextRenderer.DrawText(e.Graphics,Text,Font,r,ForeColor,TextFormatFlags.HorizontalCenter|TextFormatFlags.VerticalCenter|TextFormatFlags.EndEllipsis);
        }
    }
    public class GlobalWallpaperPanel
'@
Replace-One '    public class ClubButton : Button.*?    public class GlobalWallpaperPanel' $clubButton 'ClubButton'

$clock = @'
    public class ClockDisplay : Control
    {
        public string TimeText="00:00:00";public string DateText="00.00.0000";public bool ShowDate=true;public Color Accent=Color.MediumPurple;
        public ClockDisplay(){Size=new Size(188,64);SetStyle(ControlStyles.UserPaint|ControlStyles.AllPaintingInWmPaint|ControlStyles.OptimizedDoubleBuffer,true);}
        protected override void OnPaintBackground(PaintEventArgs e)
        {
            ThemeWallpaper.DrawBase(e.Graphics,this,Color.FromArgb(24,30,43),Color.FromArgb(12,16,25));
            int t=Math.Max(0,Math.Min(100,ThemeWallpaper.HeaderTransparency));int alpha=158+(100-t)*77/100;
            using(SolidBrush shade=new SolidBrush(Color.FromArgb(alpha,8,12,19)))e.Graphics.FillRectangle(shade,ClientRectangle);
        }
        protected override void OnPaint(PaintEventArgs e)
        {
            Rectangle timeRect=new Rectangle(0,0,Width,39);Rectangle dateRect=new Rectangle(0,39,Width,22);
            using(Font ft=new Font("Tahoma",20.5f,FontStyle.Bold))TextRenderer.DrawText(e.Graphics,TimeText,ft,timeRect,Color.White,TextFormatFlags.Right|TextFormatFlags.VerticalCenter|TextFormatFlags.NoPadding);
            if(ShowDate)using(Font fd=new Font("Tahoma",9.5f,FontStyle.Bold))TextRenderer.DrawText(e.Graphics,DateText,fd,dateRect,Color.FromArgb(196,208,226),TextFormatFlags.Right|TextFormatFlags.VerticalCenter|TextFormatFlags.NoPadding);
        }
    }

    public class StatusStripPanel
'@
Replace-One '    public class ClockDisplay : Control.*?    public class StatusStripPanel' $clock 'ClockDisplay'

$status = @'
    public class StatusStripPanel : DbPanel
    {
        public string TitleText="";public string SubText="";public Color TitleColor=Color.White;public Color Accent=Color.MediumPurple;public int Transparency=100;
        public StatusStripPanel(){SetStyle(ControlStyles.UserPaint|ControlStyles.AllPaintingInWmPaint|ControlStyles.OptimizedDoubleBuffer,true);}
        protected override void OnPaintBackground(PaintEventArgs e)
        {
            ThemeWallpaper.DrawBase(e.Graphics,this,Color.FromArgb(24,30,43),Color.FromArgb(12,16,25));
            int t=Math.Max(0,Math.Min(100,ThemeWallpaper.HeaderTransparency));int alpha=158+(100-t)*77/100;
            using(SolidBrush shade=new SolidBrush(Color.FromArgb(alpha,8,12,19)))e.Graphics.FillRectangle(shade,ClientRectangle);
        }
        protected override void OnPaint(PaintEventArgs e)
        {
            e.Graphics.SmoothingMode=SmoothingMode.AntiAlias;
            Rectangle a=new Rectangle(0,3,Width,25);Rectangle b=new Rectangle(0,28,Width,18);
            using(Font f1=new Font("Tahoma",10.7f,FontStyle.Bold))TextRenderer.DrawText(e.Graphics,TitleText,f1,a,TitleColor,TextFormatFlags.HorizontalCenter|TextFormatFlags.VerticalCenter|TextFormatFlags.EndEllipsis);
            using(Font f2=new Font("Tahoma",7.4f,FontStyle.Regular))TextRenderer.DrawText(e.Graphics,SubText,f2,b,Color.FromArgb(174,190,214),TextFormatFlags.HorizontalCenter|TextFormatFlags.VerticalCenter|TextFormatFlags.EndEllipsis);
        }
    }
    public class BrandMark
'@
Replace-One '    public class StatusStripPanel : DbPanel.*?    public class BrandMark' $status 'StatusStripPanel'

$brand = @'
    public class BrandMark : Control
    {
        public Color Accent=Color.FromArgb(120,80,230);
        public BrandMark(){Size=new Size(48,48);SetStyle(ControlStyles.UserPaint|ControlStyles.AllPaintingInWmPaint|ControlStyles.OptimizedDoubleBuffer,true);}
        protected override void OnPaintBackground(PaintEventArgs e)
        {
            ThemeWallpaper.DrawBase(e.Graphics,this,Color.FromArgb(24,30,43),Color.FromArgb(12,16,25));
            int t=Math.Max(0,Math.Min(100,ThemeWallpaper.HeaderTransparency));int alpha=158+(100-t)*77/100;
            using(SolidBrush shade=new SolidBrush(Color.FromArgb(alpha,8,12,19)))e.Graphics.FillRectangle(shade,ClientRectangle);
        }
        protected override void OnPaint(PaintEventArgs e)
        {
            e.Graphics.SmoothingMode=SmoothingMode.AntiAlias;
            using(SolidBrush a=new SolidBrush(Accent))e.Graphics.FillRectangle(a,1,8,3,32);
            Rectangle tx=new Rectangle(6,0,Width-7,Height);
            using(Font f=new Font("Tahoma",21,FontStyle.Bold))TextRenderer.DrawText(e.Graphics,"Э",f,tx,Color.White,TextFormatFlags.HorizontalCenter|TextFormatFlags.VerticalCenter|TextFormatFlags.NoPadding);
        }
    }

    public class GamesHeader
'@
Replace-One '    public class BrandMark : Control.*?    public class GamesHeader' $brand 'BrandMark'

$gamesHeader = @'
    public class GamesHeader : Control
    {
        public string TitleText="";public string SubText="";public Color Accent=Color.MediumPurple;
        public GamesHeader(){Height=54;SetStyle(ControlStyles.UserPaint|ControlStyles.AllPaintingInWmPaint|ControlStyles.OptimizedDoubleBuffer,true);}
        protected override void OnPaintBackground(PaintEventArgs e)
        {
            ThemeWallpaper.DrawBase(e.Graphics,this,Color.FromArgb(9,12,19),Color.FromArgb(9,12,19));
            using(SolidBrush shade=new SolidBrush(Color.FromArgb(72,6,9,15)))e.Graphics.FillRectangle(shade,ClientRectangle);
        }
        protected override void OnPaint(PaintEventArgs e)
        {
            e.Graphics.SmoothingMode=SmoothingMode.AntiAlias;
            using(SolidBrush a=new SolidBrush(Accent))e.Graphics.FillRectangle(a,24,12,3,30);
            Rectangle t=new Rectangle(39,3,Width-64,30);Rectangle ss=new Rectangle(40,31,Width-64,17);
            using(Font f1=new Font("Tahoma",14.0f,FontStyle.Bold))TextRenderer.DrawText(e.Graphics,TitleText,f1,t,Color.White,TextFormatFlags.Left|TextFormatFlags.VerticalCenter|TextFormatFlags.EndEllipsis);
            using(Font f2=new Font("Tahoma",7.5f,FontStyle.Regular))TextRenderer.DrawText(e.Graphics,SubText,f2,ss,Color.FromArgb(165,182,207),TextFormatFlags.Left|TextFormatFlags.VerticalCenter|TextFormatFlags.EndEllipsis);
        }
    }

    public class EpohaGamesFlow
'@
Replace-One '    public class GamesHeader : Control.*?    public class EpohaGamesFlow' $gamesHeader 'GamesHeader'

$nav = @'
    public class NavButton : Control
    {
        public bool Selected;public Color Accent=Color.MediumPurple;private bool hover;
        public NavButton(){Height=42;Cursor=Cursors.Hand;SetStyle(ControlStyles.UserPaint|ControlStyles.AllPaintingInWmPaint|ControlStyles.OptimizedDoubleBuffer,true);}
        protected override void OnMouseEnter(EventArgs e){hover=true;Invalidate();base.OnMouseEnter(e);}protected override void OnMouseLeave(EventArgs e){hover=false;Invalidate();base.OnMouseLeave(e);}
        protected override void OnPaintBackground(PaintEventArgs e)
        {
            ThemeWallpaper.DrawBase(e.Graphics,this,Color.FromArgb(24,30,43),Color.FromArgb(12,16,25));
            int t=Math.Max(0,Math.Min(100,ThemeWallpaper.SidebarTransparency));int alpha=158+(100-t)*77/100;
            using(SolidBrush shade=new SolidBrush(Color.FromArgb(alpha,8,12,19)))e.Graphics.FillRectangle(shade,ClientRectangle);
        }
        protected override void OnPaint(PaintEventArgs e)
        {
            e.Graphics.SmoothingMode=SmoothingMode.AntiAlias;
            if(Selected){using(LinearGradientBrush hi=new LinearGradientBrush(ClientRectangle,Color.FromArgb(42,Accent),Color.FromArgb(0,Accent),LinearGradientMode.Horizontal))e.Graphics.FillRectangle(hi,ClientRectangle);using(SolidBrush a=new SolidBrush(Accent))e.Graphics.FillRectangle(a,0,8,3,Height-16);}
            else if(hover)using(LinearGradientBrush hi=new LinearGradientBrush(ClientRectangle,Color.FromArgb(18,255,255,255),Color.FromArgb(0,255,255,255),LinearGradientMode.Horizontal))e.Graphics.FillRectangle(hi,ClientRectangle);
            Rectangle tx=new Rectangle(20,0,Width-30,Height);
            using(Font f=new Font("Tahoma",9.1f,Selected?FontStyle.Bold:FontStyle.Regular))TextRenderer.DrawText(e.Graphics,Text,f,tx,Selected?Color.White:Color.FromArgb(218,226,239),TextFormatFlags.Left|TextFormatFlags.VerticalCenter|TextFormatFlags.EndEllipsis);
        }
    }
    public class IconButton
'@
Replace-One '    public class NavButton : Control.*?    public class IconButton' $nav 'NavButton'

$icons = @'
    public class IconButton : Control
    {
        public enum IconKind{Admin,Restart,Power}public IconKind Kind;public Color Accent=Color.MediumPurple;private bool hover;private bool down;
        public IconButton(IconKind kind){Kind=kind;Size=new Size(38,38);Cursor=Cursors.Hand;SetStyle(ControlStyles.UserPaint|ControlStyles.OptimizedDoubleBuffer|ControlStyles.AllPaintingInWmPaint,true);}
        protected override void OnMouseEnter(EventArgs e){hover=true;Invalidate();base.OnMouseEnter(e);}protected override void OnMouseLeave(EventArgs e){hover=false;down=false;Invalidate();base.OnMouseLeave(e);}protected override void OnMouseDown(MouseEventArgs e){down=true;Invalidate();base.OnMouseDown(e);}protected override void OnMouseUp(MouseEventArgs e){down=false;Invalidate();base.OnMouseUp(e);}
        protected override void OnPaintBackground(PaintEventArgs e){ThemeWallpaper.DrawBase(e.Graphics,this,Color.FromArgb(24,30,43),Color.FromArgb(12,16,25));int t=Math.Max(0,Math.Min(100,ThemeWallpaper.HeaderTransparency));int alpha=158+(100-t)*77/100;using(SolidBrush shade=new SolidBrush(Color.FromArgb(alpha,8,12,19)))e.Graphics.FillRectangle(shade,ClientRectangle);}
        protected override void OnPaint(PaintEventArgs e)
        {
            e.Graphics.SmoothingMode=SmoothingMode.AntiAlias;if(hover)using(SolidBrush halo=new SolidBrush(Color.FromArgb(down?38:24,Accent)))e.Graphics.FillEllipse(halo,3,3,Width-7,Height-7);
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
Replace-One '    public class IconButton : Control.*?    public class GameCard' $icons 'IconButton'

$gameCard = @'
    public class GameCard : Control
    {
        public GameItem Game;public Color Accent;public Image Cover;public Image ExeIcon;private bool hover;private bool down;
        public GameCard(GameItem g,Color a){Game=g;Accent=a;Cursor=Cursors.Hand;SetStyle(ControlStyles.UserPaint|ControlStyles.OptimizedDoubleBuffer|ControlStyles.AllPaintingInWmPaint,true);TryLoadVisual();}
        private void TryLoadVisual(){try{if(!String.IsNullOrEmpty(Game.ImagePath)&&File.Exists(Game.ImagePath))using(Image i=Image.FromFile(Game.ImagePath))Cover=new Bitmap(i);else if(ThemeWallpaper.UseExeIcons&&!String.IsNullOrEmpty(Game.Exe)&&File.Exists(Game.Exe)){Icon ic=Icon.ExtractAssociatedIcon(Game.Exe);if(ic!=null){ExeIcon=ic.ToBitmap();ic.Dispose();}}}catch{}}
        private string Mark(){if(String.IsNullOrEmpty(Game.Name))return "?";string[] p=Game.Name.Split(new char[]{' ','-','.'},StringSplitOptions.RemoveEmptyEntries);if(p.Length>1)return (p[0].Substring(0,1)+p[1].Substring(0,1)).ToUpper();return Game.Name.Substring(0,Math.Min(2,Game.Name.Length)).ToUpper();}
        protected override void Dispose(bool disposing){if(disposing){if(Cover!=null)Cover.Dispose();if(ExeIcon!=null)ExeIcon.Dispose();}base.Dispose(disposing);}
        protected override void OnMouseEnter(EventArgs e){hover=true;Invalidate();base.OnMouseEnter(e);}protected override void OnMouseLeave(EventArgs e){hover=false;down=false;Invalidate();base.OnMouseLeave(e);}protected override void OnMouseDown(MouseEventArgs e){down=true;Invalidate();base.OnMouseDown(e);}protected override void OnMouseUp(MouseEventArgs e){down=false;Invalidate();base.OnMouseUp(e);}
        protected override void OnPaintBackground(PaintEventArgs e){ThemeWallpaper.DrawBase(e.Graphics,this,Color.FromArgb(8,11,18),Color.FromArgb(8,11,18));}
        protected override void OnPaint(PaintEventArgs e)
        {
            e.Graphics.SmoothingMode=SmoothingMode.AntiAlias;
            Rectangle r=new Rectangle(1,1,Width-3,Height-3);
            using(GraphicsPath gp=UiPaint.RoundRect(r,8))
            {
                GraphicsState st=e.Graphics.Save();e.Graphics.SetClip(gp);
                using(LinearGradientBrush surface=new LinearGradientBrush(r,Color.FromArgb(226,33,40,54),Color.FromArgb(241,7,10,17),LinearGradientMode.Vertical))e.Graphics.FillRectangle(surface,r);
                int footerH=ThemeWallpaper.ShowCardCategory?45:37;Rectangle art=new Rectangle(r.X,r.Y,r.Width,r.Height-footerH);
                if(Cover!=null){e.Graphics.InterpolationMode=InterpolationMode.HighQualityBicubic;e.Graphics.DrawImage(Cover,art);using(LinearGradientBrush shade=new LinearGradientBrush(art,Color.FromArgb(hover?12:24,0,0,0),Color.FromArgb(hover?60:86,0,0,0),LinearGradientMode.Vertical))e.Graphics.FillRectangle(shade,art);}
                else if(ExeIcon!=null){int s=Math.Min(52,Math.Min(art.Width-32,art.Height-32));Rectangle ir=new Rectangle(art.X+16,art.Y+16,s,s);e.Graphics.InterpolationMode=InterpolationMode.HighQualityBicubic;e.Graphics.DrawImage(ExeIcon,ir);}
                else{Rectangle mr=new Rectangle(art.X+16,art.Y+12,Math.Max(52,art.Width-32),34);using(Font mf=new Font("Tahoma",17.5f,FontStyle.Bold))TextRenderer.DrawText(e.Graphics,Mark(),mf,mr,Color.FromArgb(138,198,210,229),TextFormatFlags.Left|TextFormatFlags.VerticalCenter|TextFormatFlags.NoPadding);using(SolidBrush line=new SolidBrush(Color.FromArgb(80,Accent)))e.Graphics.FillRectangle(line,art.X+16,art.Y+50,34,2);}
                Rectangle fade=new Rectangle(r.X,r.Bottom-footerH-18,r.Width,footerH+18);using(LinearGradientBrush fb=new LinearGradientBrush(fade,Color.FromArgb(0,6,9,15),Color.FromArgb(246,5,8,14),LinearGradientMode.Vertical))e.Graphics.FillRectangle(fb,fade);
                Rectangle titleR=new Rectangle(r.X+11,r.Bottom-footerH+2,r.Width-22,ThemeWallpaper.ShowCardCategory?25:32);using(Font f=new Font("Tahoma",9.1f,FontStyle.Bold))TextRenderer.DrawText(e.Graphics,Game.Name,f,titleR,Color.White,TextFormatFlags.HorizontalCenter|TextFormatFlags.VerticalCenter|TextFormatFlags.EndEllipsis);
                if(ThemeWallpaper.ShowCardCategory){Rectangle catR=new Rectangle(r.X+11,r.Bottom-18,r.Width-22,13);using(Font f2=new Font("Tahoma",6.8f,FontStyle.Regular))TextRenderer.DrawText(e.Graphics,Game.Category,f2,catR,Color.FromArgb(145,164,190),TextFormatFlags.HorizontalCenter|TextFormatFlags.VerticalCenter|TextFormatFlags.EndEllipsis);}
                e.Graphics.Restore(st);
            }
            if(hover){using(GraphicsPath gp=UiPaint.RoundRect(r,8))using(Pen p=new Pen(Color.FromArgb(115,Accent),1.2f))e.Graphics.DrawPath(p,gp);using(SolidBrush a=new SolidBrush(Accent))e.Graphics.FillRectangle(a,r.X,r.Y+12,3,Math.Max(20,r.Height-24));}
            if(down)using(GraphicsPath gp=UiPaint.RoundRect(r,8))using(SolidBrush b=new SolidBrush(Color.FromArgb(35,0,0,0)))e.Graphics.FillPath(b,gp);
        }
    }
    public class MainForm
'@
Replace-One '    public class GameCard : Control.*?    public class MainForm' $gameCard 'GameCard'

$src = $src.Replace('root.RowCount=3; root.RowStyles.Add(new RowStyle(SizeType.Absolute,86));','root.RowCount=3; root.RowStyles.Add(new RowStyle(SizeType.Absolute,82));')
$src = $src.Replace('BrandMark logo = new BrandMark(); logo.Accent=Accent; logo.SetBounds(14,15,50,50); brandHeader.Controls.Add(logo);','BrandMark logo = new BrandMark(); logo.Accent=Accent; logo.SetBounds(13,16,48,48); brandHeader.Controls.Add(logo);')
$src = $src.Replace('brandTitle.SetBounds(76,7,172,29); brandTitle.Font=F(18,FontStyle.Bold); brandTitle.ForeColor=Accent;','brandTitle.SetBounds(72,8,176,27); brandTitle.Font=F(17,FontStyle.Bold); brandTitle.ForeColor=Color.White;')
$src = $src.Replace('brandSub.SetBounds(77,37,180,15);','brandSub.SetBounds(73,34,185,15);')
$src = $src.Replace('eraLabel.SetBounds(77,53,92,18);','eraLabel.SetBounds(73,51,92,18);')
$src = $src.Replace('ThemeWallpaper.SidebarTransparency=cfg.SidebarTransparency;','ThemeWallpaper.SidebarTransparency=cfg.HeaderTransparency;')
$src = $src.Replace('navHost.Transparency=cfg.SidebarTransparency; navList.Transparency=cfg.HeaderTransparency; statusBox.Transparency=cfg.HeaderTransparency;','navHost.Transparency=cfg.HeaderTransparency; navList.Transparency=cfg.HeaderTransparency; statusBox.Transparency=cfg.HeaderTransparency;')
$src = $src.Replace('NavButton b=new NavButton(); b.Text=name; b.Width=245; b.Accent=Accent;','NavButton b=new NavButton(); b.Text=name; b.Width=Math.Max(180,navList.ClientSize.Width-6); b.Margin=new Padding(0,1,0,1); b.Accent=Accent;')
$src = $src.Replace('gh.Dock=DockStyle.Top;gh.Height=72;','gh.Dock=DockStyle.Top;gh.Height=54;')
$src = $src.Replace('grid.Padding=new Padding(24,14,24,26);','grid.Padding=new Padding(18,10,18,24);')
$src = $src.Replace('int available=Math.Max(360,grid.ClientSize.Width-52);int preferred=cardBase+20;int cols=Math.Max(2,available/(preferred+24));int w=Math.Max(138,Math.Min(cardBase+28,(available-cols*24)/cols));int h=(int)(w*0.66)+50;','int available=Math.Max(360,grid.ClientSize.Width-40);int preferred=cardBase+16;int cols=Math.Max(2,available/(preferred+18));int w=Math.Max(136,Math.Min(cardBase+24,(available-cols*18)/cols));int h=(int)(w*0.58)+44;')
$src = $src.Replace('foreach(Control c in grid.Controls){c.Size=new Size(w,h);c.Margin=new Padding(10,8,10,12);}','foreach(Control c in grid.Controls){c.Size=new Size(w,h);c.Margin=new Padding(8,7,8,9);}')
$src = $src.Replace('CheckBox ck=c as CheckBox;if(ck!=null){ck.BackColor=Color.FromArgb(18,24,37);ck.ForeColor=Color.White;}','CheckBox ck=c as CheckBox;if(ck!=null){ck.BackColor=rootControl.BackColor;ck.ForeColor=Color.FromArgb(232,238,247);}')
$src = $src.Replace('TrackBar tr=c as TrackBar;if(tr!=null){tr.BackColor=Color.FromArgb(18,24,37);}','TrackBar tr=c as TrackBar;if(tr!=null){tr.BackColor=rootControl.BackColor;}')

$layoutHeader = @'
        private void LayoutHeader()
        {
            int w=topHeader.ClientSize.Width;if(w<480)return;
            int btn=38;int gap=7;int right=12;
            int x=w-right-btn;powerButton.SetBounds(x,22,btn,btn);x-=btn+gap;restartButton.SetBounds(x,22,btn,btn);x-=btn+gap;adminButton.SetBounds(x,22,btn,btn);
            int clockW=176;clockDisplay.SetBounds(x-clockW-20,9,clockW,64);
            int statusLeft=34;int statusRight=w-(x-clockW-38);int statusW=Math.Max(300,w-statusLeft-statusRight);
            statusBox.SetBounds(statusLeft,15,statusW,52);statusBox.Visible=cfg.ShowStatusPanel;
        }

        private void StatusBox_Paint
'@
Replace-One '        private void LayoutHeader\(\).*?        private void StatusBox_Paint' $layoutHeader 'LayoutHeader'

Set-Content -Path ProgramV081Build.cs -Value $src -Encoding UTF8
