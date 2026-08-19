$ErrorActionPreference = "Stop"

function Replace-Exact([string]$text, [string]$old, [string]$new, [string]$name) {
    if (-not $text.Contains($old)) { throw ("Patch target not found: " + $name) }
    return $text.Replace($old, $new)
}

.\build_v061.ps1
$src = Get-Content ProgramV061Build.cs -Raw -Encoding UTF8
$src = $src.Replace('0.6.1', '0.7.0')

# Darker unified glass. Even at 100% the UI stays readable over bright wallpaper.
$src = $src.Replace('int alpha = 105 + (100 - t) * 130 / 100;', 'int alpha = 155 + (100 - t) * 80 / 100;')
$src = $src.Replace('int alpha=105+(100-t)*130/100;', 'int alpha=155+(100-t)*80/100;')
$src = $src.Replace('int a=105+(100-t)*130/100;', 'int a=155+(100-t)*80/100;')

$extraUi = @'
    public class BrandMark : Control
    {
        public Color Accent = Color.FromArgb(120,80,230);
        public BrandMark(){Size=new Size(50,50);SetStyle(ControlStyles.UserPaint|ControlStyles.AllPaintingInWmPaint|ControlStyles.OptimizedDoubleBuffer,true);}
        protected override void OnPaint(PaintEventArgs e)
        {
            e.Graphics.SmoothingMode=SmoothingMode.AntiAlias;
            Rectangle r=new Rectangle(1,1,Width-3,Height-3);
            using(GraphicsPath gp=UiPaint.RoundRect(r,9))
            using(LinearGradientBrush b=new LinearGradientBrush(r,Color.FromArgb(42,49,66),Color.FromArgb(12,16,26),LinearGradientMode.Vertical))e.Graphics.FillPath(b,gp);
            using(GraphicsPath gp=UiPaint.RoundRect(r,9))using(Pen p=new Pen(Color.FromArgb(120,Accent),1.2f))e.Graphics.DrawPath(p,gp);
            using(SolidBrush a=new SolidBrush(Accent))e.Graphics.FillRectangle(a,5,5,4,Height-10);
            Rectangle tx=new Rectangle(8,2,Width-10,Height-4);
            using(Font f=new Font("Tahoma",22,FontStyle.Bold))TextRenderer.DrawText(e.Graphics,"Э",f,tx,Color.White,TextFormatFlags.HorizontalCenter|TextFormatFlags.VerticalCenter|TextFormatFlags.NoPadding);
        }
    }

    public class GamesHeader : Control
    {
        public string TitleText="";
        public string SubText="";
        public Color Accent=Color.MediumPurple;
        public GamesHeader(){Height=72;SetStyle(ControlStyles.UserPaint|ControlStyles.AllPaintingInWmPaint|ControlStyles.OptimizedDoubleBuffer,true);}
        protected override void OnPaintBackground(PaintEventArgs e)
        {
            ThemeWallpaper.DrawBase(e.Graphics,this,Color.FromArgb(9,12,19),Color.FromArgb(9,12,19));
            using(LinearGradientBrush g=new LinearGradientBrush(ClientRectangle,Color.FromArgb(155,5,8,14),Color.FromArgb(30,5,8,14),LinearGradientMode.Horizontal))e.Graphics.FillRectangle(g,ClientRectangle);
        }
        protected override void OnPaint(PaintEventArgs e)
        {
            e.Graphics.SmoothingMode=SmoothingMode.AntiAlias;
            using(SolidBrush a=new SolidBrush(Accent))e.Graphics.FillRectangle(a,26,20,4,34);
            Rectangle t=new Rectangle(44,10,Width-70,34);
            Rectangle s=new Rectangle(45,42,Width-70,20);
            using(Font f1=new Font("Tahoma",15.5f,FontStyle.Bold))TextRenderer.DrawText(e.Graphics,TitleText,f1,t,Color.White,TextFormatFlags.Left|TextFormatFlags.VerticalCenter|TextFormatFlags.EndEllipsis);
            using(Font f2=new Font("Tahoma",8.2f,FontStyle.Regular))TextRenderer.DrawText(e.Graphics,SubText,f2,s,Color.FromArgb(177,191,211),TextFormatFlags.Left|TextFormatFlags.VerticalCenter|TextFormatFlags.EndEllipsis);
        }
    }

    public class WallpaperFlow : FlowLayoutPanel
    {
        public WallpaperFlow(){DoubleBuffered=true;ResizeRedraw=true;SetStyle(ControlStyles.UserPaint|ControlStyles.AllPaintingInWmPaint|ControlStyles.OptimizedDoubleBuffer,true);}
        protected override void OnPaintBackground(PaintEventArgs e)
        {
            ThemeWallpaper.DrawBase(e.Graphics,this,Color.FromArgb(8,11,18),Color.FromArgb(8,11,18));
            Rectangle r=ClientRectangle;
            if(r.Width>0&&r.Height>0)
            {
                using(LinearGradientBrush left=new LinearGradientBrush(r,Color.FromArgb(58,0,0,0),Color.FromArgb(0,0,0,0),LinearGradientMode.Horizontal))e.Graphics.FillRectangle(left,r);
                using(LinearGradientBrush top=new LinearGradientBrush(r,Color.FromArgb(26,0,0,0),Color.FromArgb(0,0,0,0),LinearGradientMode.Vertical))e.Graphics.FillRectangle(top,r);
            }
        }
    }

'@
$src = Replace-Exact $src '    public class NavButton : Control' ($extraUi + '    public class NavButton : Control') 'insert 070 ui classes'

# Navigation: one calm sidebar, no boxed rows. Only hover/selected state gets a soft surface.
$navClass = @'
    public class NavButton : Control
    {
        public bool Selected;
        public Color Accent=Color.MediumPurple;
        private bool hover;
        public NavButton(){Height=46;Cursor=Cursors.Hand;SetStyle(ControlStyles.UserPaint|ControlStyles.AllPaintingInWmPaint|ControlStyles.OptimizedDoubleBuffer,true);}
        protected override void OnMouseEnter(EventArgs e){hover=true;Invalidate();base.OnMouseEnter(e);}
        protected override void OnMouseLeave(EventArgs e){hover=false;Invalidate();base.OnMouseLeave(e);}
        protected override void OnPaintBackground(PaintEventArgs e)
        {
            ThemeWallpaper.DrawBase(e.Graphics,this,Color.FromArgb(10,14,22),Color.FromArgb(10,14,22));
            int t=Math.Max(0,Math.Min(100,ThemeWallpaper.SidebarTransparency));
            int alpha=155+(100-t)*80/100;
            using(SolidBrush shade=new SolidBrush(Color.FromArgb(alpha,7,10,17)))e.Graphics.FillRectangle(shade,ClientRectangle);
        }
        protected override void OnPaint(PaintEventArgs e)
        {
            e.Graphics.SmoothingMode=SmoothingMode.AntiAlias;
            Rectangle r=new Rectangle(7,4,Width-15,Height-8);
            if(Selected||hover)
            {
                Color top=Selected?Color.FromArgb(78,88,112):Color.FromArgb(47,57,76);
                Color bottom=Color.FromArgb(19,25,38);
                using(GraphicsPath gp=UiPaint.RoundRect(r,7))
                using(LinearGradientBrush b=new LinearGradientBrush(r,Color.FromArgb(Selected?195:125,top),Color.FromArgb(Selected?205:145,bottom),LinearGradientMode.Vertical))e.Graphics.FillPath(b,gp);
                if(Selected)using(GraphicsPath gp=UiPaint.RoundRect(r,7))using(Pen p=new Pen(Color.FromArgb(105,Accent),1f))e.Graphics.DrawPath(p,gp);
            }
            if(Selected)
            {
                using(SolidBrush a=new SolidBrush(Accent))e.Graphics.FillRectangle(a,8,11,3,Height-22);
                using(SolidBrush d=new SolidBrush(Color.White))e.Graphics.FillEllipse(d,20,Height/2-2,4,4);
            }
            Rectangle tx=new Rectangle(Selected?32:26,0,Width-54,Height);
            using(Font f=new Font("Tahoma",9.4f,FontStyle.Bold))TextRenderer.DrawText(e.Graphics,Text,f,tx,Color.FromArgb(Selected?255:232,Selected?255:237,Selected?255:245),TextFormatFlags.Left|TextFormatFlags.VerticalCenter|TextFormatFlags.EndEllipsis);
            if(Selected)using(Pen p=new Pen(Color.FromArgb(190,Accent),1.2f)){e.Graphics.DrawLine(p,Width-27,Height/2-4,Width-22,Height/2);e.Graphics.DrawLine(p,Width-22,Height/2,Width-27,Height/2+4);}
        }
    }

'@
$navPattern='(?s)    public class NavButton : Control.*?    public class IconButton : Control'
$newSrc=[regex]::Replace($src,$navPattern,$navClass+'    public class IconButton : Control',1)
if($newSrc -eq $src){throw 'Nav 070 patch failed'}
$src=$newSrc

# Cards: remove the white/cheap frame and make the surface look like a single club theme.
$cardClass = @'
    public class GameCard : Control
    {
        public GameItem Game;public Color Accent;public Image Cover;public Image ExeIcon;private bool hover;private bool down;
        public GameCard(GameItem g,Color a){Game=g;Accent=a;Cursor=Cursors.Hand;BackColor=Color.FromArgb(8,11,18);SetStyle(ControlStyles.UserPaint|ControlStyles.OptimizedDoubleBuffer|ControlStyles.AllPaintingInWmPaint,true);TryLoadVisual();}
        private void TryLoadVisual(){try{if(!String.IsNullOrEmpty(Game.ImagePath)&&File.Exists(Game.ImagePath))using(Image i=Image.FromFile(Game.ImagePath))Cover=new Bitmap(i);else if(ThemeWallpaper.UseExeIcons&&!String.IsNullOrEmpty(Game.Exe)&&File.Exists(Game.Exe)){Icon ic=Icon.ExtractAssociatedIcon(Game.Exe);if(ic!=null){ExeIcon=ic.ToBitmap();ic.Dispose();}}}catch{}}
        protected override void Dispose(bool disposing){if(disposing){if(Cover!=null)Cover.Dispose();if(ExeIcon!=null)ExeIcon.Dispose();}base.Dispose(disposing);}
        protected override void OnMouseEnter(EventArgs e){hover=true;Invalidate();base.OnMouseEnter(e);}protected override void OnMouseLeave(EventArgs e){hover=false;down=false;Invalidate();base.OnMouseLeave(e);}protected override void OnMouseDown(MouseEventArgs e){down=true;Invalidate();base.OnMouseDown(e);}protected override void OnMouseUp(MouseEventArgs e){down=false;Invalidate();base.OnMouseUp(e);}
        protected override void OnPaintBackground(PaintEventArgs e){ThemeWallpaper.DrawBase(e.Graphics,this,Color.FromArgb(8,11,18),Color.FromArgb(8,11,18));}
        protected override void OnPaint(PaintEventArgs e)
        {
            e.Graphics.SmoothingMode=SmoothingMode.AntiAlias;
            Rectangle shadow=new Rectangle(5,7,Width-10,Height-11);Rectangle r=new Rectangle(3,3,Width-9,Height-10);
            using(GraphicsPath sp=UiPaint.RoundRect(shadow,10))using(SolidBrush sb=new SolidBrush(Color.FromArgb(78,0,0,0)))e.Graphics.FillPath(sb,sp);
            using(GraphicsPath gp=UiPaint.RoundRect(r,9))
            {
                GraphicsState st=e.Graphics.Save();e.Graphics.SetClip(gp);
                using(LinearGradientBrush surface=new LinearGradientBrush(r,Color.FromArgb(225,38,46,62),Color.FromArgb(238,8,12,20),LinearGradientMode.Vertical))e.Graphics.FillRectangle(surface,r);
                int footerH=ThemeWallpaper.ShowCardCategory?50:42;Rectangle art=new Rectangle(r.X,r.Y,r.Width,r.Height-footerH);
                if(Cover!=null)
                {
                    e.Graphics.InterpolationMode=InterpolationMode.HighQualityBicubic;e.Graphics.DrawImage(Cover,art);
                    using(LinearGradientBrush shade=new LinearGradientBrush(art,Color.FromArgb(hover?18:32,0,0,0),Color.FromArgb(hover?70:100,0,0,0),LinearGradientMode.Vertical))e.Graphics.FillRectangle(shade,art);
                }
                else if(ExeIcon!=null)
                {
                    using(SolidBrush glow=new SolidBrush(Color.FromArgb(35,Accent)))e.Graphics.FillEllipse(glow,art.X+art.Width/2-47,art.Y+art.Height/2-47,94,94);
                    int s=Math.Min(62,Math.Min(art.Width-26,art.Height-26));Rectangle ir=new Rectangle(art.X+(art.Width-s)/2,art.Y+(art.Height-s)/2,s,s);e.Graphics.InterpolationMode=InterpolationMode.HighQualityBicubic;e.Graphics.DrawImage(ExeIcon,ir);
                }
                else
                {
                    string monogram=String.IsNullOrEmpty(Game.Name)?"?":Game.Name.Substring(0,1).ToUpper();
                    using(SolidBrush glow=new SolidBrush(Color.FromArgb(36,Accent)))e.Graphics.FillEllipse(glow,art.X+art.Width/2-45,art.Y+art.Height/2-45,90,90);
                    Rectangle mr=new Rectangle(art.X,art.Y,art.Width,art.Height);
                    using(Font mf=new Font("Tahoma",31,FontStyle.Bold))TextRenderer.DrawText(e.Graphics,monogram,mf,mr,Color.FromArgb(205,220,228,240),TextFormatFlags.HorizontalCenter|TextFormatFlags.VerticalCenter|TextFormatFlags.NoPadding);
                }
                Rectangle footer=new Rectangle(r.X,r.Bottom-footerH,r.Width,footerH);
                using(LinearGradientBrush fb=new LinearGradientBrush(footer,Color.FromArgb(238,15,20,31),Color.FromArgb(248,5,8,14),LinearGradientMode.Vertical))e.Graphics.FillRectangle(fb,footer);
                Rectangle titleR=new Rectangle(r.X+11,r.Bottom-footerH+3,r.Width-22,ThemeWallpaper.ShowCardCategory?27:35);
                using(Font f=new Font("Tahoma",9.2f,FontStyle.Bold))TextRenderer.DrawText(e.Graphics,Game.Name,f,titleR,Color.White,TextFormatFlags.HorizontalCenter|TextFormatFlags.VerticalCenter|TextFormatFlags.EndEllipsis);
                if(ThemeWallpaper.ShowCardCategory){Rectangle catR=new Rectangle(r.X+11,r.Bottom-20,r.Width-22,15);using(Font f2=new Font("Tahoma",6.9f,FontStyle.Regular))TextRenderer.DrawText(e.Graphics,Game.Category,f2,catR,Color.FromArgb(145,164,190),TextFormatFlags.HorizontalCenter|TextFormatFlags.VerticalCenter|TextFormatFlags.EndEllipsis);}
                e.Graphics.Restore(st);
            }
            using(GraphicsPath gp=UiPaint.RoundRect(r,9))using(Pen border=new Pen(hover?Color.FromArgb(180,Accent):Color.FromArgb(60,71,92),hover?1.4f:1f))e.Graphics.DrawPath(border,gp);
            if(hover)using(Pen top=new Pen(Color.FromArgb(160,Accent),1.6f))e.Graphics.DrawLine(top,r.X+13,r.Y+2,r.Right-13,r.Y+2);
            if(down)using(GraphicsPath gp=UiPaint.RoundRect(r,9))using(SolidBrush b=new SolidBrush(Color.FromArgb(45,0,0,0)))e.Graphics.FillPath(b,gp);
        }
    }

'@
$cardPattern='(?s)    public class GameCard : Control.*?    public class MainForm : Form'
$newSrc=[regex]::Replace($src,$cardPattern,$cardClass+'    public class MainForm : Form',1)
if($newSrc -eq $src){throw 'Card 070 patch failed'}
$src=$newSrc

# Calm center status: no long decorative line.
$statusClass = @'
    public class StatusStripPanel : DbPanel
    {
        public string TitleText="";public string SubText="";public Color TitleColor=Color.White;public Color Accent=Color.MediumPurple;public int Transparency=100;
        public StatusStripPanel(){SetStyle(ControlStyles.UserPaint|ControlStyles.AllPaintingInWmPaint|ControlStyles.OptimizedDoubleBuffer,true);}
        protected override void OnPaintBackground(PaintEventArgs e){ThemeWallpaper.DrawBase(e.Graphics,this,Color.FromArgb(16,21,31),Color.FromArgb(10,14,22));int t=Math.Max(0,Math.Min(100,ThemeWallpaper.HeaderTransparency));int alpha=155+(100-t)*80/100;using(SolidBrush b=new SolidBrush(Color.FromArgb(alpha,8,12,19)))e.Graphics.FillRectangle(b,ClientRectangle);}
        protected override void OnPaint(PaintEventArgs e)
        {
            e.Graphics.SmoothingMode=SmoothingMode.AntiAlias;
            int cy=Height/2;
            using(SolidBrush glow=new SolidBrush(Color.FromArgb(48,Accent)))e.Graphics.FillEllipse(glow,18,cy-7,14,14);
            using(SolidBrush dot=new SolidBrush(TitleColor))e.Graphics.FillEllipse(dot,22,cy-3,6,6);
            Rectangle a=new Rectangle(42,5,Width-58,24);Rectangle b=new Rectangle(42,29,Width-58,19);
            using(Font f1=new Font("Tahoma",10.5f,FontStyle.Bold))TextRenderer.DrawText(e.Graphics,TitleText,f1,a,TitleColor,TextFormatFlags.HorizontalCenter|TextFormatFlags.VerticalCenter|TextFormatFlags.EndEllipsis);
            using(Font f2=new Font("Tahoma",7.7f,FontStyle.Regular))TextRenderer.DrawText(e.Graphics,SubText,f2,b,Color.FromArgb(181,194,214),TextFormatFlags.HorizontalCenter|TextFormatFlags.VerticalCenter|TextFormatFlags.EndEllipsis);
        }
    }

'@
$statusPattern='(?s)    public class StatusStripPanel : DbPanel.*?    public class BrandMark : Control'
$newSrc=[regex]::Replace($src,$statusPattern,$statusClass+'    public class BrandMark : Control',1)
if($newSrc -eq $src){throw 'Status 070 patch failed'}
$src=$newSrc

# Replace the old square logo label with the owner-drawn brand mark.
$logoPattern='Label logo = new Label\(\); logo\.Text="Э"; logo\.TextAlign=ContentAlignment\.MiddleCenter; logo\.SetBounds\(14,15,50,50\); logo\.Font=F\(24,FontStyle\.Bold\); logo\.ForeColor=Color\.FromArgb\(20,16,28\); logo\.BackColor=Accent; brandHeader\.Controls\.Add\(logo\);'
$logoReplacement='BrandMark logo = new BrandMark(); logo.Accent=Accent; logo.SetBounds(14,15,50,50); brandHeader.Controls.Add(logo);'
$newSrc=[regex]::Replace($src,$logoPattern,$logoReplacement,1)
if($newSrc -eq $src){throw 'Brand mark 070 patch failed'}
$src=$newSrc

# Slightly stronger brand typography and cleaner PC badge.
$src=$src.Replace('brandTitle.SetBounds(76,5,165,27); brandTitle.Font=F(17,FontStyle.Bold);','brandTitle.SetBounds(76,7,172,29); brandTitle.Font=F(18,FontStyle.Bold);')
$src=$src.Replace('brandSub.SetBounds(77,34,180,16); brandSub.Font=F(7.1f,FontStyle.Bold);','brandSub.SetBounds(77,37,180,15); brandSub.Font=F(7.2f,FontStyle.Bold);')
$src=$src.Replace('pcBadge.SetBounds(177,50,82,23);','pcBadge.SetBounds(170,54,88,21);')
$src=$src.Replace('pcBadge.BackColor=Color.FromArgb(120,38,46,64);','pcBadge.BackColor=Color.FromArgb(175,23,29,42);')

# Games page gets hierarchy: category title + count, then the clean adaptive grid.
$showGamesPattern='(?s)        private void ShowGames\(\)\s*\{.*?\r?\n        \}\r?\n\r?\n        private void LayoutCards'
$showGamesReplacement=@'
        private void ShowGames()
        {
            adminView=false;work.SuspendLayout();DisposeChildren(work);work.Controls.Clear();
            int count=0;foreach(GameItem gi in cfg.Games)if(selectedCategory=="ВСЕ ИГРЫ"||gi.Category==selectedCategory)count++;
            GamesHeader gh=new GamesHeader();gh.Name="gamesHeader";gh.Dock=DockStyle.Top;gh.Height=72;gh.Accent=Accent;gh.TitleText=selectedCategory;gh.SubText=count+" "+(count==1?"ИГРА":"ИГР");work.Controls.Add(gh);
            WallpaperFlow grid=new WallpaperFlow();grid.Name="gamesGrid";grid.Dock=DockStyle.Fill;grid.Padding=new Padding(24,14,24,26);grid.WrapContents=true;grid.AutoScroll=true;work.Controls.Add(grid);grid.BringToFront();gh.BringToFront();
            foreach(GameItem g in cfg.Games){if(selectedCategory!="ВСЕ ИГРЫ"&&g.Category!=selectedCategory)continue;GameCard c=new GameCard(g,Accent);c.Click+=delegate(object s,EventArgs e){LaunchGame(((GameCard)s).Game);};grid.Controls.Add(c);}
            work.ResumeLayout();LayoutCards();
        }

        private void LayoutCards
'@
$newSrc=[regex]::Replace($src,$showGamesPattern,$showGamesReplacement,1)
if($newSrc -eq $src){throw 'ShowGames 070 patch failed'}
$src=$newSrc

$layoutCardsPattern='(?s)        private void LayoutCards\(\)\s*\{.*?\r?\n        \}\r?\n\r?\n        private void LayoutHeader'
$layoutCardsReplacement=@'
        private void LayoutCards()
        {
            Control[] arr=work.Controls.Find("gamesGrid",true);if(arr.Length==0)return;FlowLayoutPanel grid=arr[0] as FlowLayoutPanel;if(grid==null)return;
            int available=Math.Max(360,grid.ClientSize.Width-52);int preferred=cardBase+20;int cols=Math.Max(2,available/(preferred+24));int w=Math.Max(138,Math.Min(cardBase+28,(available-cols*24)/cols));int h=(int)(w*0.66)+50;
            foreach(Control c in grid.Controls){c.Size=new Size(w,h);c.Margin=new Padding(10,8,10,12);}
        }

        private void LayoutHeader
'@
$newSrc=[regex]::Replace($src,$layoutCardsPattern,$layoutCardsReplacement,1)
if($newSrc -eq $src){throw 'LayoutCards 070 patch failed'}
$src=$newSrc

# Keep the sidebar itself consistently dark, but still show wallpaper through it.
$src=$src.Replace('navHost.Transparency=cfg.HeaderTransparency;', 'navHost.Transparency=cfg.HeaderTransparency;')

Set-Content -Path ProgramV070Build.cs -Value $src -Encoding UTF8
