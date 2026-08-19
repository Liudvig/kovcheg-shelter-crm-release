$ErrorActionPreference = "Stop"

function Replace-Exact([string]$text, [string]$old, [string]$new, [string]$name) {
    if (-not $text.Contains($old)) { throw ("Patch target not found: " + $name) }
    return $text.Replace($old, $new)
}

.\build_v050.ps1
$src = Get-Content ProgramV050Build.cs -Raw -Encoding UTF8
$src = $src.Replace('0.5.0', '0.5.1')

$src = Replace-Exact $src `
'        public bool ShowFooter = true;' `
'        public bool ShowFooter = true;
        public int CardTransparency = 18;
        public bool AlwaysOnTop = false;
        public bool SingleGameMode = true;
        public bool StartExplorerOnShellExit = true;' `
'config extra fields'

$src = Replace-Exact $src `
'                c.ShowFooter = BoolAttr(root, "showFooter", true);' `
'                c.ShowFooter = BoolAttr(root, "showFooter", true);
                c.CardTransparency = IntAttr(root, "cardTransparency", 18);
                c.AlwaysOnTop = BoolAttr(root, "alwaysOnTop", false);
                c.SingleGameMode = BoolAttr(root, "singleGameMode", true);
                c.StartExplorerOnShellExit = BoolAttr(root, "startExplorerOnShellExit", true);' `
'config extra load'

$src = Replace-Exact $src `
'            root.SetAttribute("sidebarWidth", SidebarWidth.ToString()); root.SetAttribute("showDate", ShowDate.ToString()); root.SetAttribute("showFooter", ShowFooter.ToString());' `
'            root.SetAttribute("sidebarWidth", SidebarWidth.ToString()); root.SetAttribute("showDate", ShowDate.ToString()); root.SetAttribute("showFooter", ShowFooter.ToString());
            root.SetAttribute("cardTransparency", CardTransparency.ToString()); root.SetAttribute("alwaysOnTop", AlwaysOnTop.ToString());
            root.SetAttribute("singleGameMode", SingleGameMode.ToString()); root.SetAttribute("startExplorerOnShellExit", StartExplorerOnShellExit.ToString());' `
'config extra save'

$src = Replace-Exact $src `
'        public static string Mode { get { return currentMode; } }' `
'        public static string Mode { get { return currentMode; } }
        public static int SidebarTransparency = 16;
        public static int CardTransparency = 18;' `
'theme global settings'

$glassClasses = @'
    public class GlassPanel : DbPanel
    {
        public Color TopColor = Color.FromArgb(29,35,49);
        public Color BottomColor = Color.FromArgb(14,18,28);
        public int Transparency = 20;

        protected override void OnPaintBackground(PaintEventArgs e)
        {
            ThemeWallpaper.DrawBase(e.Graphics, this, TopColor, BottomColor);
            int t = Math.Max(0, Math.Min(100, Transparency));
            int alpha = (100 - t) * 235 / 100;
            if (alpha > 0)
            {
                using (LinearGradientBrush b = new LinearGradientBrush(ClientRectangle,
                    Color.FromArgb(alpha, TopColor), Color.FromArgb(alpha, BottomColor), LinearGradientMode.Vertical))
                    e.Graphics.FillRectangle(b, ClientRectangle);
            }
            using (Pen line = new Pen(Color.FromArgb(55, 130, 150, 200)))
                e.Graphics.DrawLine(line, 0, Height-1, Width, Height-1);
        }
    }

    public class GlassFlow : FlowLayoutPanel
    {
        public int Transparency = 20;
        public Color TopColor = Color.FromArgb(18,24,37);
        public Color BottomColor = Color.FromArgb(8,12,21);
        public GlassFlow()
        {
            SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.UserPaint | ControlStyles.OptimizedDoubleBuffer, true);
            UpdateStyles();
        }
        protected override void OnPaintBackground(PaintEventArgs e)
        {
            ThemeWallpaper.DrawBase(e.Graphics, this, TopColor, BottomColor);
            int t = Math.Max(0, Math.Min(100, Transparency));
            int alpha = (100 - t) * 235 / 100;
            if (alpha > 0)
            {
                using (LinearGradientBrush b = new LinearGradientBrush(ClientRectangle,
                    Color.FromArgb(alpha, TopColor), Color.FromArgb(alpha, BottomColor), LinearGradientMode.Vertical))
                    e.Graphics.FillRectangle(b, ClientRectangle);
            }
        }
    }

    public class ClubButton : Button
    {
        public Color Accent = Color.MediumPurple;
        private bool hover;
        public ClubButton()
        {
            FlatStyle = FlatStyle.Flat;
            FlatAppearance.BorderSize = 0;
            Cursor = Cursors.Hand;
            SetStyle(ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer, true);
        }
        protected override void OnMouseEnter(EventArgs e){hover=true;Invalidate();base.OnMouseEnter(e);}
        protected override void OnMouseLeave(EventArgs e){hover=false;Invalidate();base.OnMouseLeave(e);}
        protected override void OnPaint(PaintEventArgs e)
        {
            e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
            Rectangle r = new Rectangle(0,0,Width-1,Height-1);
            Color top = hover ? Color.FromArgb(72,82,112) : Color.FromArgb(42,52,74);
            Color bottom = hover ? Color.FromArgb(29,36,55) : Color.FromArgb(18,24,38);
            using(LinearGradientBrush b = new LinearGradientBrush(r, top, bottom, LinearGradientMode.Vertical)) e.Graphics.FillRectangle(b,r);
            using(Pen p = new Pen(hover ? Accent : Color.FromArgb(92,105,140))) e.Graphics.DrawRectangle(p,r);
            if(hover) using(SolidBrush g = new SolidBrush(Color.FromArgb(35,Accent))) e.Graphics.FillRectangle(g,1,1,Width-2,Height-2);
            TextRenderer.DrawText(e.Graphics, Text, Font, r, ForeColor, TextFormatFlags.HorizontalCenter|TextFormatFlags.VerticalCenter|TextFormatFlags.EndEllipsis);
        }
    }

'@
$glassPattern = '(?s)    public class GlassPanel : DbPanel.*?    public class GlobalWallpaperPanel'
$newSrc = [regex]::Replace($src, $glassPattern, $glassClasses + '    public class GlobalWallpaperPanel', 1)
if ($newSrc -eq $src) { throw "Glass class patch failed" }
$src = $newSrc

$navClass = @'
    public class NavButton : Control
    {
        public bool Selected;
        public Color Accent = Color.MediumPurple;
        private bool hover;
        public NavButton() { Height = 46; Cursor = Cursors.Hand; SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.UserPaint | ControlStyles.OptimizedDoubleBuffer, true); }
        protected override void OnMouseEnter(EventArgs e) { hover = true; Invalidate(); base.OnMouseEnter(e); }
        protected override void OnMouseLeave(EventArgs e) { hover = false; Invalidate(); base.OnMouseLeave(e); }
        protected override void OnPaint(PaintEventArgs e)
        {
            ThemeWallpaper.DrawBase(e.Graphics, this, Color.FromArgb(19,25,38), Color.FromArgb(9,13,22));
            int t = Math.Max(0, Math.Min(100, ThemeWallpaper.SidebarTransparency));
            int alpha = (100 - t) * 220 / 100;
            Color c1 = Selected ? Color.FromArgb(58,68,94) : (hover ? Color.FromArgb(42,52,74) : Color.FromArgb(19,25,38));
            Color c2 = Selected ? Color.FromArgb(27,34,52) : Color.FromArgb(10,14,23);
            if(alpha>0) using (LinearGradientBrush b = new LinearGradientBrush(ClientRectangle, Color.FromArgb(alpha,c1), Color.FromArgb(alpha,c2), LinearGradientMode.Vertical)) e.Graphics.FillRectangle(b, ClientRectangle);
            if (Selected) using (SolidBrush a = new SolidBrush(Accent)) e.Graphics.FillRectangle(a, 0, 0, 4, Height);
            using (Pen p = new Pen(Color.FromArgb(72, 80, 100, 138))) e.Graphics.DrawLine(p, 0, Height-1, Width, Height-1);
            using (Font f = new Font("Tahoma", 9.5f, FontStyle.Bold))
            using (SolidBrush tx = new SolidBrush(Selected ? Accent : Color.FromArgb(240,243,248)))
                e.Graphics.DrawString(Text, f, tx, new RectangleF(20, 0, Width-25, Height), new StringFormat { LineAlignment = StringAlignment.Center });
        }
    }

'@
$navPattern = '(?s)    public class NavButton : Control.*?    public class IconButton : Control'
$newSrc = [regex]::Replace($src, $navPattern, $navClass + '    public class IconButton : Control', 1)
if ($newSrc -eq $src) { throw "Nav class patch failed" }
$src = $newSrc

$cardClass = @'
    public class GameCard : Control
    {
        public GameItem Game;
        public Color Accent;
        public Image Cover;
        private bool hover;
        public GameCard(GameItem g, Color a) { Game = g; Accent = a; Cursor = Cursors.Hand; SetStyle(ControlStyles.UserPaint | ControlStyles.OptimizedDoubleBuffer | ControlStyles.AllPaintingInWmPaint, true); TryLoadCover(); }
        private void TryLoadCover() { try { if (!String.IsNullOrEmpty(Game.ImagePath) && File.Exists(Game.ImagePath)) using (Image i = Image.FromFile(Game.ImagePath)) Cover = new Bitmap(i); } catch { } }
        protected override void Dispose(bool disposing) { if (disposing && Cover != null) Cover.Dispose(); base.Dispose(disposing); }
        protected override void OnMouseEnter(EventArgs e) { hover = true; Invalidate(); base.OnMouseEnter(e); }
        protected override void OnMouseLeave(EventArgs e) { hover = false; Invalidate(); base.OnMouseLeave(e); }
        protected override void OnPaint(PaintEventArgs e)
        {
            e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
            Rectangle r = new Rectangle(0,0,Width-1,Height-1);
            ThemeWallpaper.DrawBase(e.Graphics, this, Color.FromArgb(28,35,52), Color.FromArgb(8,12,21));
            int t=Math.Max(0,Math.Min(100,ThemeWallpaper.CardTransparency));
            int alpha=(100-t)*230/100;
            if(alpha>0)
            {
                Color c1=hover?Color.FromArgb(70,82,112):Color.FromArgb(38,47,68);
                Color c2=Color.FromArgb(8,12,21);
                using(LinearGradientBrush b=new LinearGradientBrush(r,Color.FromArgb(alpha,c1),Color.FromArgb(alpha,c2),LinearGradientMode.Vertical))e.Graphics.FillRectangle(b,r);
            }
            if (Cover != null)
            {
                Rectangle img = new Rectangle(1,1,Width-2,Height-44); e.Graphics.DrawImage(Cover,img);
                using (SolidBrush shade = new SolidBrush(Color.FromArgb(55,0,0,0))) e.Graphics.FillRectangle(shade,img);
            }
            else
            {
                using (SolidBrush glow = new SolidBrush(Color.FromArgb(hover?82:50, Accent))) e.Graphics.FillEllipse(glow, Width/2-25, Height/2-48, 50,50);
                Point[] tri = { new Point(Width/2-7,Height/2-39), new Point(Width/2-7,Height/2-18), new Point(Width/2+13,Height/2-28) };
                using (SolidBrush a = new SolidBrush(Color.White)) e.Graphics.FillPolygon(a, tri);
            }
            using (SolidBrush footer = new SolidBrush(Color.FromArgb(190,7,10,18))) e.Graphics.FillRectangle(footer,0,Height-44,Width,44);
            using (SolidBrush a = new SolidBrush(Accent)) e.Graphics.FillRectangle(a,0,0,Width,3);
            using (Pen border = new Pen(hover ? Accent : Color.FromArgb(72,84,112))) e.Graphics.DrawRectangle(border,r);
            using (Font f = new Font("Tahoma",9,FontStyle.Bold)) using (SolidBrush tx = new SolidBrush(Color.White))
                e.Graphics.DrawString(Game.Name,f,tx,new RectangleF(8,Height-39,Width-16,32),new StringFormat { Alignment=StringAlignment.Center, LineAlignment=StringAlignment.Center });
        }
    }

'@
$cardPattern = '(?s)    public class GameCard : Control.*?    public class MainForm : Form'
$newSrc = [regex]::Replace($src, $cardPattern, $cardClass + '    public class MainForm : Form', 1)
if ($newSrc -eq $src) { throw "Card class patch failed" }
$src = $newSrc

$src = $src.Replace('private FlowLayoutPanel navList;', 'private GlassFlow navList;')
$src = $src.Replace('private DbPanel statusBox;', 'private GlassPanel statusBox;')

$brandPattern = '(?s)            brandTitle = new Label\(\);.*?brandHeader\.Controls\.Add\(pcBadge\);'
$brandReplacement = @'
            brandTitle = new Label(); brandTitle.Text="\u042D\u041F\u041E\u0425\u0410"; brandTitle.AutoSize=false; brandTitle.SetBounds(76,5,165,27); brandTitle.Font=F(17,FontStyle.Bold); brandTitle.ForeColor=Accent; brandTitle.BackColor=Color.Transparent; brandHeader.Controls.Add(brandTitle);
            brandSub = new Label(); brandSub.Text="\u041A\u041E\u041C\u041F\u042C\u042E\u0422\u0415\u0420\u041D\u042B\u0419 \u041A\u041B\u0423\u0411"; brandSub.AutoSize=false; brandSub.SetBounds(77,34,180,16); brandSub.Font=F(7.1f,FontStyle.Bold); brandSub.ForeColor=Color.FromArgb(220,226,238); brandSub.BackColor=Color.Transparent; brandHeader.Controls.Add(brandSub);
            Label eraLabel=new Label();eraLabel.Text="2000\u20142015";eraLabel.AutoSize=false;eraLabel.SetBounds(77,53,92,18);eraLabel.Font=F(7.5f,FontStyle.Bold);eraLabel.ForeColor=Color.FromArgb(175,188,210);eraLabel.BackColor=Color.Transparent;brandHeader.Controls.Add(eraLabel);
            pcBadge = new Label(); pcBadge.AutoSize=false; pcBadge.SetBounds(177,50,82,23); pcBadge.TextAlign=ContentAlignment.MiddleCenter; pcBadge.Font=F(8,FontStyle.Bold); pcBadge.ForeColor=Color.White; pcBadge.BackColor=Color.FromArgb(120,38,46,64); brandHeader.Controls.Add(pcBadge);
'@
$newSrc = [regex]::Replace($src, $brandPattern, $brandReplacement, 1)
if ($newSrc -eq $src) { throw "Brand 0.5.1 patch failed" }
$src = $newSrc

$src = Replace-Exact $src `
'            statusBox = new DbPanel(); statusBox.BackColor=Color.FromArgb(21,27,39); statusBox.Height=58; topHeader.Controls.Add(statusBox); statusBox.Paint += StatusBox_Paint;' `
'            statusBox = new GlassPanel(); statusBox.Transparency=cfg.HeaderTransparency; statusBox.TopColor=Color.FromArgb(24,31,45); statusBox.BottomColor=Color.FromArgb(11,16,26); statusBox.Height=58; topHeader.Controls.Add(statusBox); statusBox.Paint += StatusBox_Paint;' `
'status glass'
$src = $src.Replace('statusTitle.BackColor=Color.FromArgb(21,27,39);', 'statusTitle.BackColor=Color.Transparent;')
$src = $src.Replace('statusSub.BackColor=Color.FromArgb(21,27,39);', 'statusSub.BackColor=Color.Transparent;')
$src = $src.Replace('dateLabel.Font=F(7.5f,FontStyle.Regular);', 'dateLabel.Font=F(10.5f,FontStyle.Bold);')
$src = $src.Replace('dateLabel.ForeColor=Color.FromArgb(155,166,187);', 'dateLabel.ForeColor=Color.FromArgb(220,226,238);')
$src = $src.Replace('footerLabel.BackColor=Color.FromArgb(12,16,25);', 'footerLabel.BackColor=Color.Transparent;')

$navSetupPattern = '(?s)            Label navCaption = new Label\(\);.*?navHost\.Controls\.Add\(navList\);'
$navSetupReplacement = @'
            navList = new GlassFlow(); navList.FlowDirection=FlowDirection.TopDown; navList.WrapContents=false; navList.AutoScroll=true; navList.Transparency=cfg.SidebarTransparency; navList.SetBounds(10,12,265,ClientSize.Height-112); navList.Anchor=AnchorStyles.Top|AnchorStyles.Bottom|AnchorStyles.Left|AnchorStyles.Right; navHost.Controls.Add(navList);
'@
$newSrc = [regex]::Replace($src, $navSetupPattern, $navSetupReplacement, 1)
if ($newSrc -eq $src) { throw "Nav setup patch failed" }
$src = $newSrc

$src = Replace-Exact $src `
'            ThemeWallpaper.Load(cfg.WallpaperPath, cfg.WallpaperMode);' `
'            ThemeWallpaper.Load(cfg.WallpaperPath, cfg.WallpaperMode);
            ThemeWallpaper.SidebarTransparency=cfg.SidebarTransparency;
            ThemeWallpaper.CardTransparency=cfg.CardTransparency;
            TopMost=cfg.AlwaysOnTop;' `
'apply theme globals'
$src = $src.Replace('navHost.Transparency=cfg.SidebarTransparency;', 'navHost.Transparency=cfg.SidebarTransparency; navList.Transparency=cfg.SidebarTransparency; statusBox.Transparency=cfg.HeaderTransparency;')
$src = $src.Replace('brandHeader.Invalidate(); topHeader.Invalidate(); navHost.Invalidate(); footer.Invalidate(); work.Invalidate();', 'brandHeader.Invalidate(true); topHeader.Invalidate(true); navHost.Invalidate(true); navList.Invalidate(true); statusBox.Invalidate(true); footer.Invalidate(true); work.Invalidate(true);')

$appearancePattern = '(?s)        private void BuildAdminAppearance\(DbPanel p\)\s*\{.*?\r?\n        \}\r?\n\r?\n        private void ChooseWallpaper\(\)'
$appearanceReplacement = @'
        private void BuildAdminAppearance(DbPanel p)
        {
            Title(p,"\u0412\u043D\u0435\u0448\u043D\u0438\u0439 \u0432\u0438\u0434");
            FieldLabel(p,"\u0426\u0432\u0435\u0442 \u0438\u043D\u0442\u0435\u0440\u0444\u0435\u0439\u0441\u0430",76);Panel swatch=new Panel();swatch.BackColor=Accent;swatch.SetBounds(30,99,42,26);p.Controls.Add(swatch);
            ActionButton(p,"\u0412\u042B\u0411\u0420\u0410\u0422\u042C \u0426\u0412\u0415\u0422",82,96,150,32,delegate{using(ColorDialog d=new ColorDialog()){d.Color=Accent;if(d.ShowDialog()==DialogResult.OK){cfg.AccentArgb=d.Color.ToArgb();cfg.Save();ApplyConfigToUi();BuildNav();ShowAdmin("\u0412\u043D\u0435\u0448\u043D\u0438\u0439 \u0432\u0438\u0434");}}});
            FieldLabel(p,"\u041E\u0431\u043E\u0438 \u0432\u0441\u0435\u0433\u043E \u044D\u043A\u0440\u0430\u043D\u0430",142);TextBox wall=new TextBox();wall.ReadOnly=true;wall.Text=String.IsNullOrEmpty(cfg.WallpaperPath)?"\u041D\u0435 \u0432\u044B\u0431\u0440\u0430\u043D\u044B":cfg.WallpaperPath;wall.SetBounds(30,164,530,24);p.Controls.Add(wall);
            ActionButton(p,"\u0412\u042B\u0411\u0420\u0410\u0422\u042C \u041E\u0411\u041E\u0418",30,198,150,32,delegate{ChooseWallpaper();ShowAdmin("\u0412\u043D\u0435\u0448\u043D\u0438\u0439 \u0432\u0438\u0434");});
            ActionButton(p,"\u0423\u0411\u0420\u0410\u0422\u042C \u041E\u0411\u041E\u0418",190,198,150,32,delegate{cfg.WallpaperPath="";cfg.Save();ApplyConfigToUi();ShowAdmin("\u0412\u043D\u0435\u0448\u043D\u0438\u0439 \u0432\u0438\u0434");});
            WallpaperPanel preview=new WallpaperPanel();preview.SetBounds(590,76,310,174);preview.Mode=cfg.WallpaperMode;preview.Dim=cfg.WallpaperDim;preview.LoadWallpaper(cfg.WallpaperPath);p.Controls.Add(preview);
            FieldLabel(p,"\u0420\u0435\u0436\u0438\u043C \u043E\u0431\u043E\u0435\u0432",252);ComboBox wm=new ComboBox();wm.DropDownStyle=ComboBoxStyle.DropDownList;wm.Items.AddRange(new object[]{"Fill","Stretch","Center"});wm.SelectedItem=cfg.WallpaperMode;wm.SetBounds(30,274,180,24);p.Controls.Add(wm);
            FieldLabel(p,"\u0417\u0430\u0442\u0435\u043C\u043D\u0435\u043D\u0438\u0435 \u0440\u0430\u0431\u043E\u0447\u0435\u0439 \u043E\u0431\u043B\u0430\u0441\u0442\u0438",310);TrackBar dim=new TrackBar();dim.Minimum=0;dim.Maximum=90;dim.TickFrequency=10;dim.Value=Math.Max(0,Math.Min(90,cfg.WallpaperDim));dim.SetBounds(24,332,330,42);p.Controls.Add(dim);Label dimVal=ValueLabel(p,dim.Value+"%",365,340,70);
            FieldLabel(p,"\u041F\u0440\u043E\u0437\u0440\u0430\u0447\u043D\u043E\u0441\u0442\u044C \u0448\u0430\u043F\u043A\u0438",382);TrackBar ht=new TrackBar();ht.Minimum=0;ht.Maximum=100;ht.TickFrequency=10;ht.Value=Math.Max(0,Math.Min(100,cfg.HeaderTransparency));ht.SetBounds(24,404,330,42);p.Controls.Add(ht);Label htVal=ValueLabel(p,ht.Value+"%",365,412,70);
            FieldLabel(p,"\u041F\u0440\u043E\u0437\u0440\u0430\u0447\u043D\u043E\u0441\u0442\u044C \u043B\u0435\u0432\u043E\u0439 \u043F\u0430\u043D\u0435\u043B\u0438",454);TrackBar st=new TrackBar();st.Minimum=0;st.Maximum=100;st.TickFrequency=10;st.Value=Math.Max(0,Math.Min(100,cfg.SidebarTransparency));st.SetBounds(24,476,330,42);p.Controls.Add(st);Label stVal=ValueLabel(p,st.Value+"%",365,484,70);
            FieldLabel(p,"\u041F\u0440\u043E\u0437\u0440\u0430\u0447\u043D\u043E\u0441\u0442\u044C \u043A\u0430\u0440\u0442\u043E\u0447\u0435\u043A \u0438\u0433\u0440",526);TrackBar ct=new TrackBar();ct.Minimum=0;ct.Maximum=100;ct.TickFrequency=10;ct.Value=Math.Max(0,Math.Min(100,cfg.CardTransparency));ct.SetBounds(24,548,330,42);p.Controls.Add(ct);Label ctVal=ValueLabel(p,ct.Value+"%",365,556,70);
            FieldLabel(p,"\u0428\u0438\u0440\u0438\u043D\u0430 \u043B\u0435\u0432\u043E\u0439 \u043F\u0430\u043D\u0435\u043B\u0438",598);NumericUpDown sw=new NumericUpDown();sw.Minimum=220;sw.Maximum=360;sw.Increment=5;sw.Value=Math.Max(220,Math.Min(360,cfg.SidebarWidth));sw.SetBounds(30,620,120,24);p.Controls.Add(sw);
            FieldLabel(p,"\u0420\u0430\u0437\u043C\u0435\u0440 \u043A\u0430\u0440\u0442\u043E\u0447\u0435\u043A",658);ComboBox cs=new ComboBox();cs.DropDownStyle=ComboBoxStyle.DropDownList;cs.Items.AddRange(new object[]{"\u041C\u0430\u043B\u0435\u043D\u044C\u043A\u0438\u0435","\u0421\u0440\u0435\u0434\u043D\u0438\u0435","\u0411\u043E\u043B\u044C\u0448\u0438\u0435"});cs.SelectedItem=cfg.CardSize;cs.SetBounds(30,680,180,24);p.Controls.Add(cs);
            CheckBox showDate=new CheckBox();showDate.Text="\u041F\u043E\u043A\u0430\u0437\u044B\u0432\u0430\u0442\u044C \u0434\u0430\u0442\u0443";showDate.Checked=cfg.ShowDate;showDate.SetBounds(245,678,210,24);p.Controls.Add(showDate);
            CheckBox showFooter=new CheckBox();showFooter.Text="\u041F\u043E\u043A\u0430\u0437\u044B\u0432\u0430\u0442\u044C \u043D\u0438\u0436\u043D\u044E\u044E \u0441\u0442\u0440\u043E\u043A\u0443";showFooter.Checked=cfg.ShowFooter;showFooter.SetBounds(470,678,260,24);p.Controls.Add(showFooter);
            dim.Scroll+=delegate{dimVal.Text=dim.Value+"%";preview.Dim=dim.Value;preview.Invalidate();};
            ht.Scroll+=delegate{htVal.Text=ht.Value+"%";brandHeader.Transparency=ht.Value;topHeader.Transparency=ht.Value;statusBox.Transparency=ht.Value;footer.Transparency=ht.Value;brandHeader.Invalidate(true);topHeader.Invalidate(true);statusBox.Invalidate(true);footer.Invalidate(true);};
            st.Scroll+=delegate{stVal.Text=st.Value+"%";ThemeWallpaper.SidebarTransparency=st.Value;navHost.Transparency=st.Value;navList.Transparency=st.Value;navHost.Invalidate(true);navList.Invalidate(true);};
            ct.Scroll+=delegate{ctVal.Text=ct.Value+"%";ThemeWallpaper.CardTransparency=ct.Value;work.Invalidate(true);};
            ActionButton(p,"\u0421\u041E\u0425\u0420\u0410\u041D\u0418\u0422\u042C \u0412\u041D\u0415\u0428\u041D\u0418\u0419 \u0412\u0418\u0414",30,728,220,36,delegate{cfg.WallpaperMode=wm.SelectedItem==null?"Fill":wm.SelectedItem.ToString();cfg.WallpaperDim=dim.Value;cfg.HeaderTransparency=ht.Value;cfg.SidebarTransparency=st.Value;cfg.CardTransparency=ct.Value;cfg.SidebarWidth=(int)sw.Value;cfg.CardSize=cs.SelectedItem==null?"\u0421\u0440\u0435\u0434\u043D\u0438\u0435":cs.SelectedItem.ToString();cfg.ShowDate=showDate.Checked;cfg.ShowFooter=showFooter.Checked;cfg.Save();ApplyConfigToUi();BuildNav();ShowAdmin("\u0412\u043D\u0435\u0448\u043D\u0438\u0439 \u0432\u0438\u0434");});
        }

        private void ChooseWallpaper()
'@
$newSrc = [regex]::Replace($src, $appearancePattern, $appearanceReplacement, 1)
if ($newSrc -eq $src) { throw "Appearance 0.5.1 patch failed" }
$src = $newSrc

$systemPattern = '(?s)        private void BuildAdminSystem\(DbPanel p\)\s*\{.*?\r?\n        \}\r?\n\r?\n        private string InputBox'
$systemReplacement = @'
        private void BuildAdminSystem(DbPanel p)
        {
            Title(p,"\u0421\u0438\u0441\u0442\u0435\u043C\u0430");
            CheckBox auto=new CheckBox();auto.Text="\u0417\u0430\u043F\u0443\u0441\u043A\u0430\u0442\u044C \u042D\u041F\u041E\u0425\u0423 \u043F\u0440\u0438 \u0432\u0445\u043E\u0434\u0435 Windows";auto.Checked=cfg.AutoStart;auto.SetBounds(30,88,390,25);p.Controls.Add(auto);
            CheckBox top=new CheckBox();top.Text="\u0414\u0435\u0440\u0436\u0430\u0442\u044C Shell \u043F\u043E\u0432\u0435\u0440\u0445 \u0434\u0440\u0443\u0433\u0438\u0445 \u043E\u043A\u043E\u043D";top.Checked=cfg.AlwaysOnTop;top.SetBounds(30,124,390,25);p.Controls.Add(top);
            CheckBox single=new CheckBox();single.Text="\u041D\u0435 \u0437\u0430\u043F\u0443\u0441\u043A\u0430\u0442\u044C \u0432\u0442\u043E\u0440\u0443\u044E \u0438\u0433\u0440\u0443, \u043F\u043E\u043A\u0430 \u043F\u0435\u0440\u0432\u0430\u044F \u0440\u0430\u0431\u043E\u0442\u0430\u0435\u0442";single.Checked=cfg.SingleGameMode;single.SetBounds(30,160,520,25);p.Controls.Add(single);
            CheckBox explorer=new CheckBox();explorer.Text="\u0417\u0430\u043F\u0443\u0441\u043A\u0430\u0442\u044C Explorer \u043F\u0440\u0438 \u0432\u044B\u043A\u043B\u044E\u0447\u0435\u043D\u0438\u0438 Shell";explorer.Checked=cfg.StartExplorerOnShellExit;explorer.SetBounds(30,196,460,25);p.Controls.Add(explorer);
            CheckBox confirm=new CheckBox();confirm.Text="\u0421\u043F\u0440\u0430\u0448\u0438\u0432\u0430\u0442\u044C \u043F\u043E\u0434\u0442\u0432\u0435\u0440\u0436\u0434\u0435\u043D\u0438\u0435 \u043F\u0435\u0440\u0435\u0434 \u0432\u044B\u043A\u043B\u044E\u0447\u0435\u043D\u0438\u0435\u043C/\u043F\u0435\u0440\u0435\u0437\u0430\u0433\u0440\u0443\u0437\u043A\u043E\u0439";confirm.Checked=cfg.ConfirmPower;confirm.SetBounds(30,232,570,25);p.Controls.Add(confirm);
            ActionButton(p,"\u0421\u041E\u0425\u0420\u0410\u041D\u0418\u0422\u042C",30,282,140,36,delegate{cfg.AutoStart=auto.Checked;cfg.AlwaysOnTop=top.Checked;cfg.SingleGameMode=single.Checked;cfg.StartExplorerOnShellExit=explorer.Checked;cfg.ConfirmPower=confirm.Checked;cfg.Save();ApplyConfigToUi();ApplyAutoStart();MessageBox.Show("\u0421\u0438\u0441\u0442\u0435\u043C\u043D\u044B\u0435 \u043D\u0430\u0441\u0442\u0440\u043E\u0439\u043A\u0438 \u0441\u043E\u0445\u0440\u0430\u043D\u0435\u043D\u044B.","\u042D\u041F\u041E\u0425\u0410");});
            Label service=new Label();service.Text="\u0420\u0415\u0416\u0418\u041C \u041E\u0411\u0421\u041B\u0423\u0416\u0418\u0412\u0410\u041D\u0418\u042F";service.SetBounds(30,352,440,26);service.Font=F(11,FontStyle.Bold);service.ForeColor=Accent;service.BackColor=Color.Transparent;p.Controls.Add(service);
            ActionButton(p,"\u0412\u042B\u041A\u041B\u042E\u0427\u0418\u0422\u042C SHELL",30,392,190,40,delegate{ExitShellToExplorer();});
            ActionButton(p,"\u041E\u0422\u041A\u0420\u042B\u0422\u042C EXPLORER",232,392,190,40,delegate{OpenExplorer();});
            ActionButton(p,"\u041F\u0415\u0420\u0415\u0417\u0410\u041F\u0423\u0421\u0422\u0418\u0422\u042C SHELL",434,392,210,40,delegate{RestartShell();});
            Label info=new Label();info.Text="Ctrl + Alt + E  -  admin login\r\nShell exit does not remove Windows or Explorer. It only closes EPOHA for maintenance.";info.SetBounds(30,462,700,70);info.ForeColor=Color.FromArgb(180,194,216);info.BackColor=Color.Transparent;p.Controls.Add(info);
        }

        private string InputBox
'@
$newSrc = [regex]::Replace($src, $systemPattern, $systemReplacement, 1)
if ($newSrc -eq $src) { throw "System 0.5.1 patch failed" }
$src = $newSrc

$methodsAnchor = '        private void Restart_Click(object sender,EventArgs e)'
$serviceMethods = @'
        private void OpenExplorer()
        {
            try { Process.Start("explorer.exe"); }
            catch(Exception ex){MessageBox.Show("Explorer: "+ex.Message,"EPOHA",MessageBoxButtons.OK,MessageBoxIcon.Error);}
        }

        private void ExitShellToExplorer()
        {
            if(MessageBox.Show("\u0412\u044B\u043A\u043B\u044E\u0447\u0438\u0442\u044C Shell \u0438 \u043F\u0435\u0440\u0435\u0439\u0442\u0438 \u0432 \u043E\u0431\u044B\u0447\u043D\u0443\u044E Windows?","\u042D\u041F\u041E\u0425\u0410",MessageBoxButtons.YesNo,MessageBoxIcon.Question)!=DialogResult.Yes)return;
            if(cfg.StartExplorerOnShellExit) OpenExplorer();
            Application.Exit();
        }

        private void RestartShell()
        {
            try { Process.Start(Application.ExecutablePath); Application.Exit(); }
            catch(Exception ex){MessageBox.Show("Shell: "+ex.Message,"EPOHA",MessageBoxButtons.OK,MessageBoxIcon.Error);}
        }

'@
$src = Replace-Exact $src $methodsAnchor ($serviceMethods + $methodsAnchor) 'service methods'

$src = $src.Replace('        private void LaunchGame(GameItem g)\r\n        {\r\n            if(SessionLocked())', '        private void LaunchGame(GameItem g)\r\n        {\r\n            if(cfg.SingleGameMode && runningGame!=null){try{if(!runningGame.HasExited){MessageBox.Show("\u0421\u043D\u0430\u0447\u0430\u043B\u0430 \u0437\u0430\u043A\u0440\u043E\u0439\u0442\u0435 \u0442\u0435\u043A\u0443\u0449\u0443\u044E \u0438\u0433\u0440\u0443.","\u042D\u041F\u041E\u0425\u0410",MessageBoxButtons.OK,MessageBoxIcon.Information);return;}}catch{}}\r\n            if(SessionLocked())')

$src = $src.Replace('Button b=new Button();b.Text=text;b.SetBounds(x,y,w,32);', 'ClubButton b=new ClubButton();b.Accent=Accent;b.Text=text;b.SetBounds(x,y,w,32);')
$src = $src.Replace('Button b=new Button();b.Text=text;b.SetBounds(x,y,w,h);', 'ClubButton b=new ClubButton();b.Accent=Accent;b.Text=text;b.SetBounds(x,y,w,h);')

Set-Content -Path ProgramV051Build.cs -Value $src -Encoding UTF8
