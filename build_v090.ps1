$ErrorActionPreference = "Stop"

.\build_v081.ps1
$src = Get-Content ProgramV081Build.cs -Raw -Encoding UTF8
$src = $src.Replace('0.8.1','0.9.0')

function Replace-One([string]$pattern,[string]$replacement,[string]$name) {
    $rx = New-Object System.Text.RegularExpressions.Regex($pattern,[System.Text.RegularExpressions.RegexOptions]::Singleline)
    $newSrc = $rx.Replace($script:src,$replacement,1)
    if($newSrc -eq $script:src){ throw ("0.9.0 patch failed: " + $name) }
    $script:src = $newSrc
}

$brand = @'
    public class BrandMark : Control
    {
        public Color Accent=Color.FromArgb(120,80,230);
        public BrandMark(){Size=new Size(40,44);SetStyle(ControlStyles.UserPaint|ControlStyles.AllPaintingInWmPaint|ControlStyles.OptimizedDoubleBuffer,true);}
        protected override void OnPaintBackground(PaintEventArgs e)
        {
            ThemeWallpaper.DrawBase(e.Graphics,this,Color.FromArgb(24,30,43),Color.FromArgb(12,16,25));
            int t=Math.Max(0,Math.Min(100,ThemeWallpaper.HeaderTransparency));int alpha=172+(100-t)*72/100;
            using(SolidBrush shade=new SolidBrush(Color.FromArgb(alpha,7,11,18)))e.Graphics.FillRectangle(shade,ClientRectangle);
        }
        protected override void OnPaint(PaintEventArgs e)
        {
            Rectangle tx=new Rectangle(0,0,Width,Height);
            using(Font f=new Font("Tahoma",20.5f,FontStyle.Bold))TextRenderer.DrawText(e.Graphics,"Э",f,tx,Color.White,TextFormatFlags.HorizontalCenter|TextFormatFlags.VerticalCenter|TextFormatFlags.NoPadding);
        }
    }
'@
Replace-One '    public class BrandMark : Control.*?(?=    public class GamesHeader)' $brand 'BrandMark'

$gamesHeader = @'
    public class GamesHeader : Control
    {
        public string TitleText="";public string SubText="";public Color Accent=Color.MediumPurple;
        public GamesHeader(){Height=50;SetStyle(ControlStyles.UserPaint|ControlStyles.AllPaintingInWmPaint|ControlStyles.OptimizedDoubleBuffer,true);}
        protected override void OnPaintBackground(PaintEventArgs e)
        {
            ThemeWallpaper.DrawBase(e.Graphics,this,Color.FromArgb(9,12,19),Color.FromArgb(9,12,19));
        }
        protected override void OnPaint(PaintEventArgs e)
        {
            e.Graphics.SmoothingMode=SmoothingMode.AntiAlias;
            using(SolidBrush a=new SolidBrush(Accent))e.Graphics.FillRectangle(a,22,11,2,28);
            Rectangle t=new Rectangle(35,1,Width-55,29);Rectangle ss=new Rectangle(36,29,Width-56,16);
            using(Font tf=new Font("Tahoma",13.6f,FontStyle.Bold))
            {
                Rectangle sh=new Rectangle(t.X+1,t.Y+1,t.Width,t.Height);
                TextRenderer.DrawText(e.Graphics,TitleText,tf,sh,Color.FromArgb(150,0,0,0),TextFormatFlags.Left|TextFormatFlags.VerticalCenter|TextFormatFlags.EndEllipsis);
                TextRenderer.DrawText(e.Graphics,TitleText,tf,t,Color.White,TextFormatFlags.Left|TextFormatFlags.VerticalCenter|TextFormatFlags.EndEllipsis);
            }
            using(Font f2=new Font("Tahoma",7.3f,FontStyle.Regular))TextRenderer.DrawText(e.Graphics,SubText,f2,ss,Color.FromArgb(178,194,217),TextFormatFlags.Left|TextFormatFlags.VerticalCenter|TextFormatFlags.EndEllipsis);
        }
    }
'@
Replace-One '    public class GamesHeader : Control.*?(?=    public class EpohaGamesFlow)' $gamesHeader 'GamesHeader'

$gameCard = @'
    public class GameCard : Control
    {
        public GameItem Game;public Color Accent;public Image Cover;public Image ExeIcon;private bool hover;private bool down;
        public GameCard(GameItem g,Color a){Game=g;Accent=a;Cursor=Cursors.Hand;SetStyle(ControlStyles.UserPaint|ControlStyles.OptimizedDoubleBuffer|ControlStyles.AllPaintingInWmPaint,true);TryLoadVisual();}
        private void TryLoadVisual()
        {
            try
            {
                if(!String.IsNullOrEmpty(Game.ImagePath)&&File.Exists(Game.ImagePath))using(Image i=Image.FromFile(Game.ImagePath))Cover=new Bitmap(i);
                else if(ThemeWallpaper.UseExeIcons&&!String.IsNullOrEmpty(Game.Exe)&&File.Exists(Game.Exe))
                {
                    Icon ic=Icon.ExtractAssociatedIcon(Game.Exe);if(ic!=null){ExeIcon=ic.ToBitmap();ic.Dispose();}
                }
            }catch{}
        }
        protected override void Dispose(bool disposing){if(disposing){if(Cover!=null)Cover.Dispose();if(ExeIcon!=null)ExeIcon.Dispose();}base.Dispose(disposing);}
        protected override void OnMouseEnter(EventArgs e){hover=true;Invalidate();base.OnMouseEnter(e);}protected override void OnMouseLeave(EventArgs e){hover=false;down=false;Invalidate();base.OnMouseLeave(e);}protected override void OnMouseDown(MouseEventArgs e){down=true;Invalidate();base.OnMouseDown(e);}protected override void OnMouseUp(MouseEventArgs e){down=false;Invalidate();base.OnMouseUp(e);}
        protected override void OnPaintBackground(PaintEventArgs e){ThemeWallpaper.DrawBase(e.Graphics,this,Color.FromArgb(8,11,18),Color.FromArgb(8,11,18));}
        private void DrawImageFit(Graphics g,Image img,Rectangle area)
        {
            if(img==null||area.Width<2||area.Height<2)return;float sx=(float)area.Width/img.Width;float sy=(float)area.Height/img.Height;float s=Math.Min(sx,sy);
            int w=Math.Max(1,(int)(img.Width*s));int h=Math.Max(1,(int)(img.Height*s));Rectangle d=new Rectangle(area.X+(area.Width-w)/2,area.Y+(area.Height-h)/2,w,h);
            g.InterpolationMode=InterpolationMode.HighQualityBicubic;g.DrawImage(img,d);
        }
        private string Initials()
        {
            if(String.IsNullOrEmpty(Game.Name))return "?";string[] p=Game.Name.Trim().Split(new char[]{' ','-','_','.'},StringSplitOptions.RemoveEmptyEntries);
            if(p.Length>=2)return (p[0].Substring(0,1)+p[1].Substring(0,1)).ToUpper();return Game.Name.Substring(0,Math.Min(2,Game.Name.Length)).ToUpper();
        }
        protected override void OnPaint(PaintEventArgs e)
        {
            e.Graphics.SmoothingMode=SmoothingMode.AntiAlias;Rectangle r=new Rectangle(1,1,Math.Max(1,Width-3),Math.Max(1,Height-3));
            int footerH=ThemeWallpaper.ShowCardCategory?45:38;int artH=Math.Max(40,r.Height-footerH);Rectangle art=new Rectangle(r.X,r.Y,r.Width,artH);Rectangle footer=new Rectangle(r.X,r.Y+artH,r.Width,Math.Max(1,r.Height-artH));
            using(GraphicsPath gp=UiPaint.RoundRect(r,8))
            {
                GraphicsState st=e.Graphics.Save();e.Graphics.SetClip(gp);
                using(LinearGradientBrush surface=new LinearGradientBrush(r,Color.FromArgb(232,39,47,62),Color.FromArgb(242,8,12,20),LinearGradientMode.Vertical))e.Graphics.FillRectangle(surface,r);
                if(Cover!=null)
                {
                    DrawImageFit(e.Graphics,Cover,new Rectangle(art.X+6,art.Y+6,art.Width-12,art.Height-12));
                    using(LinearGradientBrush shade=new LinearGradientBrush(art,Color.FromArgb(hover?8:18,0,0,0),Color.FromArgb(hover?50:72,0,0,0),LinearGradientMode.Vertical))e.Graphics.FillRectangle(shade,art);
                }
                else if(ExeIcon!=null)
                {
                    int s=Math.Min(48,Math.Min(art.Width-26,art.Height-22));Rectangle ir=new Rectangle(art.X+(art.Width-s)/2,art.Y+(art.Height-s)/2,s,s);DrawImageFit(e.Graphics,ExeIcon,ir);
                }
                else
                {
                    Rectangle ir=new Rectangle(art.X+10,art.Y+8,art.Width-20,art.Height-16);
                    using(Font mf=new Font("Tahoma",20f,FontStyle.Bold))TextRenderer.DrawText(e.Graphics,Initials(),mf,ir,Color.FromArgb(150,198,208,225),TextFormatFlags.HorizontalCenter|TextFormatFlags.VerticalCenter|TextFormatFlags.NoPadding);
                }
                using(LinearGradientBrush fb=new LinearGradientBrush(footer,Color.FromArgb(236,17,22,33),Color.FromArgb(249,6,9,15),LinearGradientMode.Vertical))e.Graphics.FillRectangle(fb,footer);
                Rectangle titleR=new Rectangle(r.X+9,footer.Y+2,r.Width-18,ThemeWallpaper.ShowCardCategory?25:footer.Height-4);
                using(Font f=new Font("Tahoma",8.8f,FontStyle.Bold))TextRenderer.DrawText(e.Graphics,Game.Name,f,titleR,Color.White,TextFormatFlags.HorizontalCenter|TextFormatFlags.VerticalCenter|TextFormatFlags.EndEllipsis|TextFormatFlags.NoPadding);
                if(ThemeWallpaper.ShowCardCategory){Rectangle catR=new Rectangle(r.X+9,r.Bottom-17,r.Width-18,13);using(Font f2=new Font("Tahoma",6.7f,FontStyle.Regular))TextRenderer.DrawText(e.Graphics,Game.Category,f2,catR,Color.FromArgb(145,164,190),TextFormatFlags.HorizontalCenter|TextFormatFlags.VerticalCenter|TextFormatFlags.EndEllipsis|TextFormatFlags.NoPadding);}
                e.Graphics.Restore(st);
            }
            if(hover){using(GraphicsPath gp=UiPaint.RoundRect(r,8))using(Pen p=new Pen(Color.FromArgb(105,Accent),1.2f))e.Graphics.DrawPath(p,gp);using(Pen top=new Pen(Color.FromArgb(210,Accent),1.5f))e.Graphics.DrawLine(top,r.X+14,r.Y+1,r.Right-14,r.Y+1);}
            if(down)using(GraphicsPath gp=UiPaint.RoundRect(r,8))using(SolidBrush b=new SolidBrush(Color.FromArgb(38,0,0,0)))e.Graphics.FillPath(b,gp);
        }
    }
'@
Replace-One '    public class GameCard : Control.*?(?=    public class MainForm)' $gameCard 'GameCard'

$showGames = @'
        private void ShowGames()
        {
            adminView=false;work.SuspendLayout();DisposeChildren(work);work.Controls.Clear();
            int count=0;foreach(GameItem gi in cfg.Games)if(selectedCategory=="ВСЕ ИГРЫ"||gi.Category==selectedCategory)count++;
            TableLayoutPanel gamesLayout=new TableLayoutPanel();gamesLayout.Name="gamesLayout";gamesLayout.Dock=DockStyle.Fill;gamesLayout.Margin=new Padding(0);gamesLayout.Padding=new Padding(0);gamesLayout.BackColor=Color.Transparent;
            gamesLayout.ColumnCount=1;gamesLayout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent,100));gamesLayout.RowCount=2;gamesLayout.RowStyles.Add(new RowStyle(SizeType.Absolute,50));gamesLayout.RowStyles.Add(new RowStyle(SizeType.Percent,100));work.Controls.Add(gamesLayout);
            GamesHeader gh=new GamesHeader();gh.Name="gamesHeader";gh.Dock=DockStyle.Fill;gh.Margin=new Padding(0);gh.Height=50;gh.Accent=Accent;gh.TitleText=selectedCategory;gh.SubText=count+" "+(count==1?"ИГРА":"ИГР");gamesLayout.Controls.Add(gh,0,0);
            EpohaGamesFlow grid=new EpohaGamesFlow();grid.Name="gamesGrid";grid.Dock=DockStyle.Fill;grid.Margin=new Padding(0);grid.Padding=new Padding(22,14,22,24);grid.WrapContents=true;grid.AutoScroll=true;gamesLayout.Controls.Add(grid,0,1);
            foreach(GameItem g in cfg.Games){if(selectedCategory!="ВСЕ ИГРЫ"&&g.Category!=selectedCategory)continue;GameCard c=new GameCard(g,Accent);c.Click+=delegate(object s,EventArgs e){LaunchGame(((GameCard)s).Game);};grid.Controls.Add(c);}
            work.ResumeLayout();LayoutCards();
        }
'@
Replace-One '        private void ShowGames\(\).*?(?=        private void LayoutCards\(\))' $showGames 'ShowGames'

$layoutCards = @'
        private void LayoutCards()
        {
            Control[] arr=work.Controls.Find("gamesGrid",true);if(arr.Length==0)return;FlowLayoutPanel grid=arr[0] as FlowLayoutPanel;if(grid==null)return;
            int available=Math.Max(320,grid.ClientSize.Width-grid.Padding.Horizontal-6);int target=Math.Max(150,cardBase+8);int gap=14;
            int cols=Math.Max(2,Math.Min(10,(available+gap)/(target+gap)));int w=Math.Max(145,Math.Min(220,(available-(cols-1)*gap)/cols-2));int h=Math.Max(128,(int)(w*0.57)+48);
            foreach(Control c in grid.Controls){c.Size=new Size(w,h);c.Margin=new Padding(gap/2,6,gap/2,10);}
        }
'@
Replace-One '        private void LayoutCards\(\).*?(?=        private void LayoutHeader\(\))' $layoutCards 'LayoutCards'

$src = $src.Replace('CheckBox ck=c as CheckBox;if(ck!=null){ck.BackColor=Color.FromArgb(18,24,37);ck.ForeColor=Color.White;}','CheckBox ck=c as CheckBox;if(ck!=null){ck.BackColor=Color.Transparent;ck.ForeColor=Color.White;}')
$src = $src.Replace('Label info=new Label();info.Text="Ctrl + Alt + E  -  admin login. Ctrl+Alt+Del itself is a protected Windows sequence; EPOHA restricts the available actions through user policies.";','Label info=new Label();info.Text="Ctrl + Alt + E — вход администратора. Системные ограничения применяются только в клубном режиме.";')

Set-Content -Path ProgramV090Build.cs -Value $src -Encoding UTF8
