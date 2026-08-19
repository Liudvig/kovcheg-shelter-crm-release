$ErrorActionPreference = "Stop"

function Replace-Exact([string]$text, [string]$old, [string]$new, [string]$name) {
    if (-not $text.Contains($old)) { throw ("Patch target not found: " + $name) }
    return $text.Replace($old, $new)
}

$src = Get-Content ProgramV04.cs -Raw -Encoding UTF8

$src = $src.Replace('config-v04.xml', 'config-v050.xml')
$src = $src.Replace('EpohaShell-0.4.0.log', 'EpohaShell-0.5.0.log')
$src = $src.Replace('EpohaShell-0.4.0', 'EpohaShell-0.5.0')
$src = $src.Replace('0.4.0', '0.5.0')

$src = Replace-Exact $src `
'        public int WallpaperDim = 48;' `
'        public int WallpaperDim = 48;
        public int HeaderTransparency = 26;
        public int SidebarTransparency = 16;
        public int SidebarWidth = 285;
        public bool ShowDate = true;
        public bool ShowFooter = true;' `
'config fields'

$src = Replace-Exact $src `
'                c.WallpaperDim = IntAttr(root, "wallpaperDim", 48);' `
'                c.WallpaperDim = IntAttr(root, "wallpaperDim", 48);
                c.HeaderTransparency = IntAttr(root, "headerTransparency", 26);
                c.SidebarTransparency = IntAttr(root, "sidebarTransparency", 16);
                c.SidebarWidth = IntAttr(root, "sidebarWidth", 285);
                c.ShowDate = BoolAttr(root, "showDate", true);
                c.ShowFooter = BoolAttr(root, "showFooter", true);' `
'config load'

$src = Replace-Exact $src `
'            root.SetAttribute("wallpaper", WallpaperPath); root.SetAttribute("wallpaperMode", WallpaperMode); root.SetAttribute("wallpaperDim", WallpaperDim.ToString());' `
'            root.SetAttribute("wallpaper", WallpaperPath); root.SetAttribute("wallpaperMode", WallpaperMode); root.SetAttribute("wallpaperDim", WallpaperDim.ToString());
            root.SetAttribute("headerTransparency", HeaderTransparency.ToString()); root.SetAttribute("sidebarTransparency", SidebarTransparency.ToString());
            root.SetAttribute("sidebarWidth", SidebarWidth.ToString()); root.SetAttribute("showDate", ShowDate.ToString()); root.SetAttribute("showFooter", ShowFooter.ToString());' `
'config save'

$themeClasses = @'
    public static class ThemeWallpaper
    {
        private static Image image;
        private static string currentPath = "";
        private static string currentMode = "Fill";

        public static string Mode { get { return currentMode; } }

        public static void Load(string path, string mode)
        {
            mode = String.IsNullOrEmpty(mode) ? "Fill" : mode;
            if (path == null) path = "";
            if (path == currentPath && mode == currentMode && (String.IsNullOrEmpty(path) || image != null)) return;
            currentMode = mode;
            currentPath = path;
            if (image != null) { image.Dispose(); image = null; }
            try
            {
                if (!String.IsNullOrEmpty(path) && File.Exists(path))
                {
                    using (FileStream fs = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
                    using (Image src = Image.FromStream(fs))
                        image = new Bitmap(src);
                }
            }
            catch { image = null; }
        }

        private static Rectangle GetDest(Size img, Size box, string mode)
        {
            if (mode == "Stretch") return new Rectangle(0, 0, box.Width, box.Height);
            if (mode == "Center") return new Rectangle((box.Width-img.Width)/2, (box.Height-img.Height)/2, img.Width, img.Height);
            double k = Math.Max((double)box.Width / img.Width, (double)box.Height / img.Height);
            int w = (int)(img.Width*k); int h = (int)(img.Height*k);
            return new Rectangle((box.Width-w)/2, (box.Height-h)/2, w, h);
        }

        public static void DrawBase(Graphics g, Control c, Color fallbackTop, Color fallbackBottom)
        {
            Form f = c.FindForm();
            if (f == null || c.ClientSize.Width <= 0 || c.ClientSize.Height <= 0)
            {
                g.Clear(fallbackBottom);
                return;
            }

            Point cp = c.PointToScreen(Point.Empty);
            Point fp = f.PointToScreen(Point.Empty);
            int ox = cp.X - fp.X;
            int oy = cp.Y - fp.Y;
            Rectangle canvas = new Rectangle(0,0,Math.Max(1,f.ClientSize.Width),Math.Max(1,f.ClientSize.Height));

            GraphicsState state = g.Save();
            g.TranslateTransform(-ox, -oy);
            if (image != null)
            {
                Rectangle dest = GetDest(image.Size, canvas.Size, currentMode);
                g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                g.DrawImage(image, dest);
            }
            else
            {
                using (LinearGradientBrush bg = new LinearGradientBrush(canvas, fallbackTop, fallbackBottom, 35f))
                    g.FillRectangle(bg, canvas);
            }
            g.Restore(state);
        }

        public static void DrawWithDim(Graphics g, Control c, int dimPercent, Color fallbackTop, Color fallbackBottom)
        {
            DrawBase(g, c, fallbackTop, fallbackBottom);
            int a = Math.Max(0, Math.Min(235, dimPercent * 255 / 100));
            using (SolidBrush shade = new SolidBrush(Color.FromArgb(a, 5, 8, 15)))
                g.FillRectangle(shade, c.ClientRectangle);
        }
    }

    public class GlassPanel : DbPanel
    {
        public Color TopColor = Color.FromArgb(29,35,49);
        public Color BottomColor = Color.FromArgb(14,18,28);
        public int Transparency = 20;

        protected override void OnPaintBackground(PaintEventArgs e)
        {
            ThemeWallpaper.DrawBase(e.Graphics, this, TopColor, BottomColor);
            int alpha = Math.Max(20, Math.Min(245, (100 - Math.Max(0, Math.Min(90, Transparency))) * 255 / 100));
            using (LinearGradientBrush b = new LinearGradientBrush(ClientRectangle,
                Color.FromArgb(alpha, TopColor), Color.FromArgb(alpha, BottomColor), LinearGradientMode.Vertical))
                e.Graphics.FillRectangle(b, ClientRectangle);
            using (Pen line = new Pen(Color.FromArgb(48, 130, 150, 200)))
                e.Graphics.DrawLine(line, 0, Height-1, Width, Height-1);
        }
    }

    public class GlobalWallpaperPanel : WallpaperPanel
    {
        public new void LoadWallpaper(string path)
        {
            ThemeWallpaper.Load(path, Mode);
            Invalidate();
        }

        protected override void OnPaintBackground(PaintEventArgs e)
        {
            ThemeWallpaper.DrawWithDim(e.Graphics, this, Dim, Color.FromArgb(18,28,46), Color.FromArgb(5,9,17));
            using (Pen p = new Pen(Color.FromArgb(22, 115, 135, 190)))
                for (int y=0; y<Height; y+=72) e.Graphics.DrawLine(p, 0, y, Width, y);
        }
    }

    public class WallpaperFlow : FlowLayoutPanel
    {
        private int dim = 48;
        public WallpaperFlow()
        {
            SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.UserPaint | ControlStyles.OptimizedDoubleBuffer, true);
            UpdateStyles();
        }
        public void Apply(string path, string mode, int darkness, Color accent)
        {
            dim = Math.Max(0, Math.Min(90, darkness));
            ThemeWallpaper.Load(path, mode);
            Invalidate();
        }
        protected override void OnPaintBackground(PaintEventArgs e)
        {
            ThemeWallpaper.DrawWithDim(e.Graphics, this, dim, Color.FromArgb(18,28,46), Color.FromArgb(5,9,17));
        }
    }

'@

$src = Replace-Exact $src `
'    public class NavButton : Control' `
($themeClasses + '    public class NavButton : Control') `
'theme classes'

$src = $src.Replace('private GradientPanel brandHeader;', 'private GlassPanel brandHeader;')
$src = $src.Replace('private GradientPanel topHeader;', 'private GlassPanel topHeader;')
$src = $src.Replace('private DbPanel navHost;', 'private GlassPanel navHost;')
$src = $src.Replace('private WallpaperPanel work;', 'private GlobalWallpaperPanel work;')
$src = $src.Replace('private DbPanel footer;', 'private GlassPanel footer;')

$src = $src.Replace('brandHeader = new GradientPanel();', 'brandHeader = new GlassPanel();')
$src = $src.Replace('topHeader = new GradientPanel();', 'topHeader = new GlassPanel();')
$src = $src.Replace('navHost = new DbPanel();', 'navHost = new GlassPanel();')
$src = $src.Replace('work = new WallpaperPanel();', 'work = new GlobalWallpaperPanel();')
$src = $src.Replace('footer = new DbPanel();', 'footer = new GlassPanel();')

$src = $src.Replace('root.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 285));', 'root.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, cfg.SidebarWidth));')

$brandPattern = '(?s)            brandTitle = new Label\(\);.*?brandHeader\.Controls\.Add\(pcBadge\);'
$brandReplacement = @'
            brandTitle = new Label(); brandTitle.Text="\u042D\u041F\u041E\u0425\u0410"; brandTitle.AutoSize=false; brandTitle.SetBounds(76,8,190,25); brandTitle.Font=F(17,FontStyle.Bold); brandTitle.ForeColor=Accent; brandHeader.Controls.Add(brandTitle);
            brandSub = new Label(); brandSub.Text="\u041A\u041E\u041C\u041F\u042C\u042E\u0422\u0415\u0420\u041D\u042B\u0419 \u041A\u041B\u0423\u0411\r\n2000\u20142015"; brandSub.AutoSize=false; brandSub.SetBounds(77,35,116,34); brandSub.Font=F(7.2f,FontStyle.Bold); brandSub.ForeColor=Color.FromArgb(195,204,220); brandSub.TextAlign=ContentAlignment.MiddleLeft; brandHeader.Controls.Add(brandSub);
            pcBadge = new Label(); pcBadge.AutoSize=false; pcBadge.SetBounds(198,45,70,23); pcBadge.TextAlign=ContentAlignment.MiddleCenter; pcBadge.Font=F(8,FontStyle.Bold); pcBadge.ForeColor=Color.White; pcBadge.BackColor=Color.FromArgb(48,55,74); brandHeader.Controls.Add(pcBadge);
'@
$newSrc = [regex]::Replace($src, $brandPattern, $brandReplacement, 1)
if ($newSrc -eq $src) { throw "Brand patch failed" }
$src = $newSrc

$applyPattern = '(?s)        private void ApplyConfigToUi\(\)\s*\{.*?\r?\n        \}\r?\n\r?\n        private void BuildNav\(\)'
$applyReplacement = @'
        private void ApplyConfigToUi()
        {
            ThemeWallpaper.Load(cfg.WallpaperPath, cfg.WallpaperMode);
            pcBadge.Text="\u041F\u041A \u2116"+cfg.PcNumber;
            brandTitle.ForeColor=Accent; adminButton.Accent=Accent; restartButton.Accent=Accent; powerButton.Accent=Accent;
            work.Mode=cfg.WallpaperMode; work.Dim=cfg.WallpaperDim; work.LoadWallpaper(cfg.WallpaperPath);
            brandHeader.Transparency=cfg.HeaderTransparency; topHeader.Transparency=cfg.HeaderTransparency; footer.Transparency=cfg.HeaderTransparency;
            navHost.Transparency=cfg.SidebarTransparency;
            root.ColumnStyles[0].Width=Math.Max(220,Math.Min(360,cfg.SidebarWidth));
            dateLabel.Visible=cfg.ShowDate;
            footer.Visible=cfg.ShowFooter; root.RowStyles[2].Height=cfg.ShowFooter?26:0;
            brandHeader.Invalidate(); topHeader.Invalidate(); navHost.Invalidate(); footer.Invalidate(); work.Invalidate();
            if (cfg.CardSize=="\u041C\u0430\u043B\u0435\u043D\u044C\u043A\u0438\u0435") cardBase=145; else if (cfg.CardSize=="\u0411\u043E\u043B\u044C\u0448\u0438\u0435") cardBase=205; else cardBase=170;
            ApplyAutoStart();
        }

        private void BuildNav()
'@
$newSrc = [regex]::Replace($src, $applyPattern, $applyReplacement, 1)
if ($newSrc -eq $src) { throw "ApplyConfig patch failed" }
$src = $newSrc

$showGamesPattern = '(?s)        private void ShowGames\(\)\s*\{.*?\r?\n        \}\r?\n\r?\n        private void LayoutCards\(\)'
$showGamesReplacement = @'
        private void ShowGames()
        {
            adminView=false; work.SuspendLayout(); DisposeChildren(work); work.Controls.Clear();
            WallpaperFlow grid=new WallpaperFlow(); grid.Name="gamesGrid"; grid.Dock=DockStyle.Fill; grid.Padding=new Padding(26,24,20,20); grid.WrapContents=true; grid.AutoScroll=true;
            grid.Apply(cfg.WallpaperPath,cfg.WallpaperMode,cfg.WallpaperDim,Accent); work.Controls.Add(grid);
            foreach(GameItem g in cfg.Games)
            {
                if (selectedCategory!="\u0412\u0421\u0415 \u0418\u0413\u0420\u042B" && g.Category!=selectedCategory) continue;
                GameCard c=new GameCard(g,Accent); c.Click+=delegate(object s,EventArgs e){ LaunchGame(((GameCard)s).Game); }; grid.Controls.Add(c);
            }
            work.ResumeLayout(); LayoutCards();
        }

        private void LayoutCards()
'@
$newSrc = [regex]::Replace($src, $showGamesPattern, $showGamesReplacement, 1)
if ($newSrc -eq $src) { throw "ShowGames patch failed" }
$src = $newSrc

$src = $src.Replace(
'Color c1 = Selected ? Color.FromArgb(47, 54, 73) : (hover ? Color.FromArgb(34, 40, 55) : Color.FromArgb(19, 24, 35));',
'Color c1 = Selected ? Color.FromArgb(58, 68, 94) : (hover ? Color.FromArgb(42, 52, 74) : Color.FromArgb(19, 25, 38));')
$src = $src.Replace(
'Color c2 = Selected ? Color.FromArgb(33, 39, 55) : Color.FromArgb(13, 17, 26);',
'Color c2 = Selected ? Color.FromArgb(27, 34, 52) : Color.FromArgb(10, 14, 23);')
$src = $src.Replace(
'using (Pen p = new Pen(Color.FromArgb(28, 70, 80, 105))) e.Graphics.DrawLine(p, 0, Height-1, Width, Height-1);',
'using (Pen p = new Pen(Color.FromArgb(62, 80, 100, 138))) e.Graphics.DrawLine(p, 0, Height-1, Width, Height-1);')
$src = $src.Replace(
'using (LinearGradientBrush b = new LinearGradientBrush(r, hover ? Color.FromArgb(48,56,76) : Color.FromArgb(31,37,52), Color.FromArgb(12,16,25), LinearGradientMode.Vertical)) e.Graphics.FillRectangle(b,r);',
'using (LinearGradientBrush b = new LinearGradientBrush(r, hover ? Color.FromArgb(70,82,112) : Color.FromArgb(38,47,68), Color.FromArgb(8,12,21), LinearGradientMode.Vertical)) e.Graphics.FillRectangle(b,r);')

$showAdminPattern = '(?s)        private void ShowAdmin\(string section\)\s*\{.*?\r?\n        \}\r?\n\r?\n        private Label Title'
$showAdminReplacement = @'
        private void ShowAdmin(string section)
        {
            adminView=true; work.SuspendLayout(); DisposeChildren(work); work.Controls.Clear();
            TableLayoutPanel shell=new TableLayoutPanel(); shell.Dock=DockStyle.Fill; shell.BackColor=Color.FromArgb(12,16,25); shell.ColumnCount=2; shell.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute,220)); shell.ColumnStyles.Add(new ColumnStyle(SizeType.Percent,100)); work.Controls.Add(shell);
            GlassPanel menu=new GlassPanel();menu.Dock=DockStyle.Fill;menu.Transparency=Math.Max(0,Math.Min(75,cfg.SidebarTransparency+8));menu.TopColor=Color.FromArgb(22,29,43);menu.BottomColor=Color.FromArgb(10,14,24);shell.Controls.Add(menu,0,0);
            Label cap=new Label();cap.Text="\u041D\u0410\u0421\u0422\u0420\u041E\u0419\u041A\u0418";cap.SetBounds(18,18,185,25);cap.Font=F(10,FontStyle.Bold);cap.ForeColor=Accent;cap.BackColor=Color.FromArgb(22,29,43);menu.Controls.Add(cap);
            string[] names={"\u041E\u0431\u0449\u0438\u0435","\u0412\u043D\u0435\u0448\u043D\u0438\u0439 \u0432\u0438\u0434","\u0412\u043A\u043B\u0430\u0434\u043A\u0438","\u0418\u0433\u0440\u044B \u0438 \u044F\u0440\u043B\u044B\u043A\u0438","\u0421\u0438\u0441\u0442\u0435\u043C\u0430"};int y=58;
            foreach(string n in names){NavButton b=new NavButton();b.Text=n.ToUpper();b.Accent=Accent;b.Selected=(n==section);b.SetBounds(10,y,200,44);string key=n;b.Click+=delegate{ShowAdmin(key);};menu.Controls.Add(b);y+=46;}
            Button logout=new Button();logout.Text="\u0412\u042B\u0419\u0422\u0418 \u0418\u0417 \u0410\u0414\u041C\u0418\u041D\u041A\u0418";logout.SetBounds(16,ClientSize.Height-195,188,36);logout.Anchor=AnchorStyles.Left|AnchorStyles.Bottom;logout.Click+=delegate{adminMode=false;ShowGames();};menu.Controls.Add(logout);
            GlassPanel content=new GlassPanel();content.Dock=DockStyle.Fill;content.Transparency=12;content.TopColor=Color.FromArgb(18,24,37);content.BottomColor=Color.FromArgb(8,12,21);shell.Controls.Add(content,1,0);
            if(section=="\u041E\u0431\u0449\u0438\u0435")BuildAdminGeneral(content);else if(section=="\u0412\u043D\u0435\u0448\u043D\u0438\u0439 \u0432\u0438\u0434")BuildAdminAppearance(content);else if(section=="\u0412\u043A\u043B\u0430\u0434\u043A\u0438")BuildAdminCategories(content);else if(section=="\u0418\u0433\u0440\u044B \u0438 \u044F\u0440\u043B\u044B\u043A\u0438")BuildAdminGames(content);else BuildAdminSystem(content);
            ThemeControlTree(content); ThemeControlTree(menu);
            work.ResumeLayout();
        }

        private Label Title
'@
$newSrc = [regex]::Replace($src, $showAdminPattern, $showAdminReplacement, 1)
if ($newSrc -eq $src) { throw "ShowAdmin patch failed" }
$src = $newSrc

$helpersAnchor = '        private void BuildAdminGeneral(DbPanel p)'
$helpers = @'
        private Color InputBack
        {
            get
            {
                return Color.FromArgb((20*7+Accent.R)/8,(25*7+Accent.G)/8,(38*7+Accent.B)/8);
            }
        }

        private void ThemeControlTree(Control rootControl)
        {
            foreach(Control c in rootControl.Controls)
            {
                TextBox tb=c as TextBox;if(tb!=null){tb.BackColor=InputBack;tb.ForeColor=Color.White;tb.BorderStyle=BorderStyle.FixedSingle;}
                ComboBox cb=c as ComboBox;if(cb!=null){cb.BackColor=InputBack;cb.ForeColor=Color.White;cb.FlatStyle=FlatStyle.Flat;}
                ListBox lb=c as ListBox;if(lb!=null){lb.BackColor=InputBack;lb.ForeColor=Color.White;lb.BorderStyle=BorderStyle.FixedSingle;}
                NumericUpDown nu=c as NumericUpDown;if(nu!=null){nu.BackColor=InputBack;nu.ForeColor=Color.White;nu.BorderStyle=BorderStyle.FixedSingle;}
                TrackBar tr=c as TrackBar;if(tr!=null){tr.BackColor=Color.FromArgb(18,24,37);}
                CheckBox ck=c as CheckBox;if(ck!=null){ck.BackColor=Color.FromArgb(18,24,37);ck.ForeColor=Color.White;}
                Button bt=c as Button;if(bt!=null){bt.FlatStyle=FlatStyle.Flat;bt.FlatAppearance.BorderColor=Accent;bt.BackColor=Color.FromArgb(32,40,58);bt.ForeColor=Color.White;bt.Font=F(8,FontStyle.Bold);}
                if(c.HasChildren)ThemeControlTree(c);
            }
        }

        private Label ValueLabel(DbPanel p,string text,int x,int y,int w)
        {
            Label l=new Label();l.Text=text;l.SetBounds(x,y,w,24);l.Font=F(8,FontStyle.Bold);l.ForeColor=Accent;l.BackColor=Color.FromArgb(18,24,37);p.Controls.Add(l);return l;
        }

'@
$src = Replace-Exact $src $helpersAnchor ($helpers + $helpersAnchor) 'admin helper injection'

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

            FieldLabel(p,"\u041F\u0440\u043E\u0437\u0440\u0430\u0447\u043D\u043E\u0441\u0442\u044C \u0448\u0430\u043F\u043A\u0438",382);TrackBar ht=new TrackBar();ht.Minimum=0;ht.Maximum=80;ht.TickFrequency=10;ht.Value=Math.Max(0,Math.Min(80,cfg.HeaderTransparency));ht.SetBounds(24,404,330,42);p.Controls.Add(ht);Label htVal=ValueLabel(p,ht.Value+"%",365,412,70);

            FieldLabel(p,"\u041F\u0440\u043E\u0437\u0440\u0430\u0447\u043D\u043E\u0441\u0442\u044C \u043B\u0435\u0432\u043E\u0439 \u043F\u0430\u043D\u0435\u043B\u0438",454);TrackBar st=new TrackBar();st.Minimum=0;st.Maximum=80;st.TickFrequency=10;st.Value=Math.Max(0,Math.Min(80,cfg.SidebarTransparency));st.SetBounds(24,476,330,42);p.Controls.Add(st);Label stVal=ValueLabel(p,st.Value+"%",365,484,70);

            FieldLabel(p,"\u0428\u0438\u0440\u0438\u043D\u0430 \u043B\u0435\u0432\u043E\u0439 \u043F\u0430\u043D\u0435\u043B\u0438",526);NumericUpDown sw=new NumericUpDown();sw.Minimum=220;sw.Maximum=360;sw.Increment=5;sw.Value=Math.Max(220,Math.Min(360,cfg.SidebarWidth));sw.SetBounds(30,548,120,24);p.Controls.Add(sw);

            FieldLabel(p,"\u0420\u0430\u0437\u043C\u0435\u0440 \u043A\u0430\u0440\u0442\u043E\u0447\u0435\u043A",588);ComboBox cs=new ComboBox();cs.DropDownStyle=ComboBoxStyle.DropDownList;cs.Items.AddRange(new object[]{"\u041C\u0430\u043B\u0435\u043D\u044C\u043A\u0438\u0435","\u0421\u0440\u0435\u0434\u043D\u0438\u0435","\u0411\u043E\u043B\u044C\u0448\u0438\u0435"});cs.SelectedItem=cfg.CardSize;cs.SetBounds(30,610,180,24);p.Controls.Add(cs);

            CheckBox showDate=new CheckBox();showDate.Text="\u041F\u043E\u043A\u0430\u0437\u044B\u0432\u0430\u0442\u044C \u0434\u0430\u0442\u0443 \u043F\u043E\u0434 \u0447\u0430\u0441\u0430\u043C\u0438";showDate.Checked=cfg.ShowDate;showDate.SetBounds(245,608,260,24);p.Controls.Add(showDate);
            CheckBox showFooter=new CheckBox();showFooter.Text="\u041F\u043E\u043A\u0430\u0437\u044B\u0432\u0430\u0442\u044C \u043D\u0438\u0436\u043D\u044E\u044E \u0441\u0442\u0440\u043E\u043A\u0443";showFooter.Checked=cfg.ShowFooter;showFooter.SetBounds(510,608,260,24);p.Controls.Add(showFooter);

            dim.Scroll+=delegate{dimVal.Text=dim.Value+"%";preview.Dim=dim.Value;preview.Invalidate();};
            ht.Scroll+=delegate{htVal.Text=ht.Value+"%";brandHeader.Transparency=ht.Value;topHeader.Transparency=ht.Value;footer.Transparency=ht.Value;brandHeader.Invalidate();topHeader.Invalidate();footer.Invalidate();};
            st.Scroll+=delegate{stVal.Text=st.Value+"%";navHost.Transparency=st.Value;navHost.Invalidate();};

            ActionButton(p,"\u0421\u041E\u0425\u0420\u0410\u041D\u0418\u0422\u042C \u0412\u041D\u0415\u0428\u041D\u0418\u0419 \u0412\u0418\u0414",30,662,220,36,delegate{
                cfg.WallpaperMode=wm.SelectedItem==null?"Fill":wm.SelectedItem.ToString();cfg.WallpaperDim=dim.Value;cfg.HeaderTransparency=ht.Value;cfg.SidebarTransparency=st.Value;
                cfg.SidebarWidth=(int)sw.Value;cfg.CardSize=cs.SelectedItem==null?"\u0421\u0440\u0435\u0434\u043D\u0438\u0435":cs.SelectedItem.ToString();cfg.ShowDate=showDate.Checked;cfg.ShowFooter=showFooter.Checked;
                cfg.Save();ApplyConfigToUi();BuildNav();ShowAdmin("\u0412\u043D\u0435\u0448\u043D\u0438\u0439 \u0432\u0438\u0434");
            });
        }

        private void ChooseWallpaper()
'@
$newSrc = [regex]::Replace($src, $appearancePattern, $appearanceReplacement, 1)
if ($newSrc -eq $src) { throw "Appearance patch failed" }
$src = $newSrc

$choosePattern = '(?s)        private void ChooseWallpaper\(\)\s*\{.*?\r?\n        \}\r?\n\r?\n        private void BuildAdminCategories'
$chooseReplacement = @'
        private void ChooseWallpaper()
        {
            using(OpenFileDialog d=new OpenFileDialog())
            {
                d.Filter="Images|*.jpg;*.jpeg;*.png;*.bmp|All files|*.*"; if(d.ShowDialog()!=DialogResult.OK)return;
                try
                {
                    using(Image test=Image.FromFile(d.FileName)){int testW=test.Width;}
                    string ext=Path.GetExtension(d.FileName);string dst=Path.Combine(Program.AppDir,"wallpaper-"+DateTime.Now.Ticks.ToString()+ext);
                    File.Copy(d.FileName,dst,true);cfg.WallpaperPath=dst;cfg.Save();ApplyConfigToUi();
                }
                catch(Exception ex){MessageBox.Show("\u041D\u0435 \u0443\u0434\u0430\u043B\u043E\u0441\u044C \u0443\u0441\u0442\u0430\u043D\u043E\u0432\u0438\u0442\u044C \u043E\u0431\u043E\u0438:\r\n"+ex.Message,"\u042D\u041F\u041E\u0425\u0410",MessageBoxButtons.OK,MessageBoxIcon.Error);}
            }
        }

        private void BuildAdminCategories
'@
$newSrc = [regex]::Replace($src, $choosePattern, $chooseReplacement, 1)
if ($newSrc -eq $src) { throw "Wallpaper chooser patch failed" }
$src = $newSrc

$src = $src.Replace('if(f.ShowDialog()!=DialogResult.OK)return null;', 'ThemeControlTree(f);if(f.ShowDialog()!=DialogResult.OK)return null;')
$src = $src.Replace('return f.ShowDialog()==DialogResult.OK?t.Text:null;', 'ThemeControlTree(f);return f.ShowDialog()==DialogResult.OK?t.Text:null;')
$src = $src.Replace('return f.ShowDialog()==DialogResult.OK?t.Text.Trim():null;', 'ThemeControlTree(f);return f.ShowDialog()==DialogResult.OK?t.Text.Trim():null;')

$extraButton = @'
        private Button ActionButton(DbPanel p,string text,int x,int y,int w,int h,EventHandler ev){Button b=new Button();b.Text=text;b.SetBounds(x,y,w,h);b.FlatStyle=FlatStyle.Flat;b.FlatAppearance.BorderColor=Accent;b.BackColor=Color.FromArgb(32,40,58);b.ForeColor=Color.White;b.Font=F(8,FontStyle.Bold);b.Click+=ev;p.Controls.Add(b);return b;}

'@
$src = Replace-Exact $src '        private void BuildAdminGeneral(DbPanel p)' ($extraButton + '        private void BuildAdminGeneral(DbPanel p)') 'button overload'

Set-Content -Path ProgramV050Build.cs -Value $src -Encoding UTF8
