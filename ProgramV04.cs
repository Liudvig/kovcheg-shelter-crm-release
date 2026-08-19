using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.IO;
using System.Windows.Forms;
using System.Xml;
using Microsoft.Win32;

namespace EpohaShellV04
{
    public static class Program
    {
        public static readonly string AppDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Epoha");
        public static readonly string ConfigPath = Path.Combine(AppDir, "config-v04.xml");
        public static readonly string LogPath = Path.Combine(Path.GetTempPath(), "EpohaShell-0.4.0.log");

        [STAThread]
        public static void Main()
        {
            try
            {
                Directory.CreateDirectory(AppDir);
                File.AppendAllText(LogPath, "\r\n--- START " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + " ---\r\n");
                Application.SetUnhandledExceptionMode(UnhandledExceptionMode.CatchException);
                Application.ThreadException += delegate(object sender, System.Threading.ThreadExceptionEventArgs e) { Fatal("ThreadException", e.Exception); };
                AppDomain.CurrentDomain.UnhandledException += delegate(object sender, UnhandledExceptionEventArgs e) { Fatal("UnhandledException", e.ExceptionObject as Exception); };
                Application.EnableVisualStyles();
                Application.SetCompatibleTextRenderingDefault(false);
                Application.Run(new MainForm());
            }
            catch (Exception ex) { Fatal("Main", ex); }
        }

        public static void Fatal(string where, Exception ex)
        {
            try
            {
                string text = where + ": " + (ex == null ? "unknown error" : ex.ToString());
                File.AppendAllText(LogPath, text + "\r\n");
                MessageBox.Show("ЭПОХА обнаружила ошибку.\r\n\r\n" + text + "\r\n\r\nЛог: " + LogPath,
                    "ЭПОХА — ошибка", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            catch { }
        }
    }

    public class GameItem
    {
        public string Name = "Новая игра";
        public string Category = "ПРОГРАММЫ";
        public string Exe = "";
        public string Args = "";
        public string WorkDir = "";
        public string ImagePath = "";
        public override string ToString() { return Name + "   [" + Category + "]"; }
    }

    public class AppConfig
    {
        public string PcNumber = "01";
        public string AdminPassword = "2000";
        public int AccentArgb = Color.FromArgb(139, 78, 240).ToArgb();
        public string WallpaperPath = "";
        public string WallpaperMode = "Fill";
        public int WallpaperDim = 48;
        public string CardSize = "Средние";
        public string SessionMode = "Бессрочно";
        public int SessionMinutes = 120;
        public bool AutoStart = false;
        public bool ConfirmPower = true;
        public List<string> Categories = new List<string>();
        public List<GameItem> Games = new List<GameItem>();

        public static AppConfig CreateDefault()
        {
            AppConfig c = new AppConfig();
            c.Categories.Add("ШУТЕРЫ");
            c.Categories.Add("ЭКШЕН");
            c.Categories.Add("СТРАТЕГИИ");
            c.Categories.Add("RPG");
            c.Categories.Add("ПРОГРАММЫ");
            c.Games.Add(NewGame("Counter-Strike 1.6", "ШУТЕРЫ"));
            c.Games.Add(NewGame("S.T.A.L.K.E.R.", "ШУТЕРЫ"));
            c.Games.Add(NewGame("Unreal Tournament", "ШУТЕРЫ"));
            c.Games.Add(NewGame("GTA San Andreas", "ЭКШЕН"));
            c.Games.Add(NewGame("Assassin's Creed", "ЭКШЕН"));
            c.Games.Add(NewGame("Warcraft III", "СТРАТЕГИИ"));
            c.Games.Add(NewGame("Diablo II", "RPG"));
            return c;
        }

        private static GameItem NewGame(string n, string cat)
        {
            GameItem g = new GameItem(); g.Name = n; g.Category = cat; return g;
        }

        public static AppConfig Load()
        {
            if (!File.Exists(Program.ConfigPath)) return CreateDefault();
            try
            {
                XmlDocument d = new XmlDocument(); d.Load(Program.ConfigPath);
                AppConfig c = new AppConfig();
                XmlElement root = d.DocumentElement;
                c.PcNumber = Attr(root, "pc", "01");
                c.AdminPassword = Attr(root, "password", "2000");
                c.AccentArgb = IntAttr(root, "accent", c.AccentArgb);
                c.WallpaperPath = Attr(root, "wallpaper", "");
                c.WallpaperMode = Attr(root, "wallpaperMode", "Fill");
                c.WallpaperDim = IntAttr(root, "wallpaperDim", 48);
                c.CardSize = Attr(root, "cardSize", "Средние");
                c.SessionMode = Attr(root, "sessionMode", "Бессрочно");
                c.SessionMinutes = IntAttr(root, "sessionMinutes", 120);
                c.AutoStart = BoolAttr(root, "autoStart", false);
                c.ConfirmPower = BoolAttr(root, "confirmPower", true);
                XmlNode cats = root.SelectSingleNode("categories");
                if (cats != null) foreach (XmlNode n in cats.ChildNodes) if (n.Name == "category") c.Categories.Add(Attr((XmlElement)n, "name", ""));
                XmlNode games = root.SelectSingleNode("games");
                if (games != null)
                {
                    foreach (XmlNode n in games.ChildNodes)
                    {
                        if (n.Name != "game") continue;
                        XmlElement e = (XmlElement)n;
                        GameItem g = new GameItem();
                        g.Name = Attr(e, "name", "Игра"); g.Category = Attr(e, "category", "ПРОГРАММЫ");
                        g.Exe = Attr(e, "exe", ""); g.Args = Attr(e, "args", ""); g.WorkDir = Attr(e, "workDir", ""); g.ImagePath = Attr(e, "image", "");
                        c.Games.Add(g);
                    }
                }
                if (c.Categories.Count == 0) c.Categories = CreateDefault().Categories;
                return c;
            }
            catch (Exception ex)
            {
                File.AppendAllText(Program.LogPath, "Config load: " + ex + "\r\n");
                return CreateDefault();
            }
        }

        public void Save()
        {
            Directory.CreateDirectory(Program.AppDir);
            XmlDocument d = new XmlDocument();
            XmlElement root = d.CreateElement("epoha"); d.AppendChild(root);
            root.SetAttribute("pc", PcNumber); root.SetAttribute("password", AdminPassword); root.SetAttribute("accent", AccentArgb.ToString());
            root.SetAttribute("wallpaper", WallpaperPath); root.SetAttribute("wallpaperMode", WallpaperMode); root.SetAttribute("wallpaperDim", WallpaperDim.ToString());
            root.SetAttribute("cardSize", CardSize); root.SetAttribute("sessionMode", SessionMode); root.SetAttribute("sessionMinutes", SessionMinutes.ToString());
            root.SetAttribute("autoStart", AutoStart.ToString()); root.SetAttribute("confirmPower", ConfirmPower.ToString());
            XmlElement cats = d.CreateElement("categories"); root.AppendChild(cats);
            foreach (string s in Categories) { XmlElement e = d.CreateElement("category"); e.SetAttribute("name", s); cats.AppendChild(e); }
            XmlElement games = d.CreateElement("games"); root.AppendChild(games);
            foreach (GameItem g in Games)
            {
                XmlElement e = d.CreateElement("game");
                e.SetAttribute("name", g.Name); e.SetAttribute("category", g.Category); e.SetAttribute("exe", g.Exe); e.SetAttribute("args", g.Args);
                e.SetAttribute("workDir", g.WorkDir); e.SetAttribute("image", g.ImagePath); games.AppendChild(e);
            }
            d.Save(Program.ConfigPath);
        }

        private static string Attr(XmlElement e, string name, string def) { string v = e.GetAttribute(name); return v == "" ? def : v; }
        private static int IntAttr(XmlElement e, string name, int def) { int v; return Int32.TryParse(e.GetAttribute(name), out v) ? v : def; }
        private static bool BoolAttr(XmlElement e, string name, bool def) { bool v; return Boolean.TryParse(e.GetAttribute(name), out v) ? v : def; }
    }

    public class DbPanel : Panel
    {
        public DbPanel() { DoubleBuffered = true; ResizeRedraw = true; }
    }

    public class GradientPanel : DbPanel
    {
        public Color TopColor = Color.FromArgb(28, 34, 48);
        public Color BottomColor = Color.FromArgb(15, 18, 27);
        protected override void OnPaintBackground(PaintEventArgs e)
        {
            using (LinearGradientBrush b = new LinearGradientBrush(ClientRectangle, TopColor, BottomColor, LinearGradientMode.Vertical)) e.Graphics.FillRectangle(b, ClientRectangle);
        }
    }

    public class WallpaperPanel : DbPanel
    {
        public Image WallpaperImage;
        public string Mode = "Fill";
        public int Dim = 48;
        public Color BaseColor = Color.FromArgb(8, 12, 22);
        protected override void OnPaintBackground(PaintEventArgs e)
        {
            e.Graphics.Clear(BaseColor);
            if (WallpaperImage != null)
            {
                Rectangle dest = GetDest(WallpaperImage.Size, ClientSize, Mode);
                e.Graphics.InterpolationMode = InterpolationMode.HighQualityBicubic;
                e.Graphics.DrawImage(WallpaperImage, dest);
            }
            int a = Math.Max(0, Math.Min(230, Dim * 255 / 100));
            using (SolidBrush shade = new SolidBrush(Color.FromArgb(a, 5, 8, 15))) e.Graphics.FillRectangle(shade, ClientRectangle);
            using (Pen p = new Pen(Color.FromArgb(30, 110, 125, 180)))
            {
                for (int x = -Height; x < Width; x += 170) e.Graphics.DrawLine(p, x, Height, x + Height, 0);
            }
        }
        private Rectangle GetDest(Size img, Size box, string mode)
        {
            if (mode == "Stretch") return new Rectangle(0, 0, box.Width, box.Height);
            if (mode == "Center") return new Rectangle((box.Width-img.Width)/2, (box.Height-img.Height)/2, img.Width, img.Height);
            double k = Math.Max((double)box.Width / img.Width, (double)box.Height / img.Height);
            int w = (int)(img.Width * k); int h = (int)(img.Height * k);
            return new Rectangle((box.Width-w)/2, (box.Height-h)/2, w, h);
        }
        public void LoadWallpaper(string path)
        {
            if (WallpaperImage != null) { WallpaperImage.Dispose(); WallpaperImage = null; }
            if (!String.IsNullOrEmpty(path) && File.Exists(path))
            {
                using (Image i = Image.FromFile(path)) WallpaperImage = new Bitmap(i);
            }
            Invalidate();
        }
    }

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
            Color c1 = Selected ? Color.FromArgb(47, 54, 73) : (hover ? Color.FromArgb(34, 40, 55) : Color.FromArgb(19, 24, 35));
            Color c2 = Selected ? Color.FromArgb(33, 39, 55) : Color.FromArgb(13, 17, 26);
            using (LinearGradientBrush b = new LinearGradientBrush(ClientRectangle, c1, c2, LinearGradientMode.Vertical)) e.Graphics.FillRectangle(b, ClientRectangle);
            if (Selected) using (SolidBrush a = new SolidBrush(Accent)) e.Graphics.FillRectangle(a, 0, 0, 4, Height);
            using (Pen p = new Pen(Color.FromArgb(28, 70, 80, 105))) e.Graphics.DrawLine(p, 0, Height-1, Width, Height-1);
            using (Font f = new Font("Tahoma", 9.5f, FontStyle.Bold))
            using (SolidBrush t = new SolidBrush(Selected ? Accent : Color.FromArgb(230, 233, 240)))
                e.Graphics.DrawString(Text, f, t, new RectangleF(20, 0, Width-25, Height), new StringFormat { LineAlignment = StringAlignment.Center });
        }
    }

    public class IconButton : Control
    {
        public enum IconKind { Admin, Restart, Power }
        public IconKind Kind;
        public Color Accent = Color.MediumPurple;
        private bool hover;
        public IconButton(IconKind kind) { Kind = kind; Size = new Size(46, 46); Cursor = Cursors.Hand; SetStyle(ControlStyles.UserPaint | ControlStyles.OptimizedDoubleBuffer | ControlStyles.AllPaintingInWmPaint, true); }
        protected override void OnMouseEnter(EventArgs e) { hover = true; Invalidate(); base.OnMouseEnter(e); }
        protected override void OnMouseLeave(EventArgs e) { hover = false; Invalidate(); base.OnMouseLeave(e); }
        protected override void OnPaint(PaintEventArgs e)
        {
            e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
            Rectangle r = new Rectangle(1,1,Width-3,Height-3);
            Color top = hover ? Blend(Accent, Color.White, 0.18f) : Color.FromArgb(39, 47, 64);
            Color bot = hover ? Blend(Accent, Color.Black, 0.30f) : Color.FromArgb(20, 25, 37);
            using (LinearGradientBrush b = new LinearGradientBrush(r, top, bot, LinearGradientMode.Vertical)) e.Graphics.FillRectangle(b, r);
            using (Pen border = new Pen(hover ? Accent : Color.FromArgb(84, 96, 126))) e.Graphics.DrawRectangle(border, r);
            using (Pen p = new Pen(hover ? Color.White : Color.FromArgb(218,225,238), 2.1f))
            {
                if (Kind == IconKind.Power) { e.Graphics.DrawArc(p, 13,13,20,20,-55,290); e.Graphics.DrawLine(p,23,9,23,23); }
                else if (Kind == IconKind.Restart) { e.Graphics.DrawArc(p, 11,11,24,24,30,290); Point[] q = { new Point(34,10), new Point(35,20), new Point(26,16) }; e.Graphics.FillPolygon(new SolidBrush(p.Color), q); }
                else { e.Graphics.DrawEllipse(p,17,11,12,12); e.Graphics.DrawArc(p,12,21,22,17,195,150); }
            }
        }
        private static Color Blend(Color a, Color b, float p) { return Color.FromArgb((int)(a.R+(b.R-a.R)*p),(int)(a.G+(b.G-a.G)*p),(int)(a.B+(b.B-a.B)*p)); }
    }

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
            using (LinearGradientBrush b = new LinearGradientBrush(r, hover ? Color.FromArgb(48,56,76) : Color.FromArgb(31,37,52), Color.FromArgb(12,16,25), LinearGradientMode.Vertical)) e.Graphics.FillRectangle(b,r);
            if (Cover != null)
            {
                Rectangle img = new Rectangle(1,1,Width-2,Height-44); e.Graphics.DrawImage(Cover,img);
                using (SolidBrush shade = new SolidBrush(Color.FromArgb(70,0,0,0))) e.Graphics.FillRectangle(shade,img);
            }
            else
            {
                using (SolidBrush glow = new SolidBrush(Color.FromArgb(hover?75:45, Accent))) e.Graphics.FillEllipse(glow, Width/2-25, Height/2-48, 50,50);
                Point[] tri = { new Point(Width/2-7,Height/2-39), new Point(Width/2-7,Height/2-18), new Point(Width/2+13,Height/2-28) };
                using (SolidBrush a = new SolidBrush(Color.White)) e.Graphics.FillPolygon(a, tri);
            }
            using (SolidBrush footer = new SolidBrush(Color.FromArgb(224,9,12,20))) e.Graphics.FillRectangle(footer,0,Height-44,Width,44);
            using (SolidBrush a = new SolidBrush(Accent)) e.Graphics.FillRectangle(a,0,0,Width,3);
            using (Pen border = new Pen(hover ? Accent : Color.FromArgb(52,64,88))) e.Graphics.DrawRectangle(border,r);
            using (Font f = new Font("Tahoma",9,FontStyle.Bold)) using (SolidBrush t = new SolidBrush(Color.White))
                e.Graphics.DrawString(Game.Name,f,t,new RectangleF(8,Height-39,Width-16,32),new StringFormat { Alignment=StringAlignment.Center, LineAlignment=StringAlignment.Center });
        }
    }

    public class MainForm : Form
    {
        private AppConfig cfg;
        private Color Accent { get { return Color.FromArgb(cfg.AccentArgb); } }
        private TableLayoutPanel root;
        private GradientPanel brandHeader;
        private GradientPanel topHeader;
        private DbPanel navHost;
        private FlowLayoutPanel navList;
        private WallpaperPanel work;
        private DbPanel footer;
        private Label brandTitle, brandSub, pcBadge, clockLabel, dateLabel, statusTitle, statusSub, footerLabel;
        private DbPanel statusBox;
        private IconButton adminButton, restartButton, powerButton;
        private Timer clockTimer;
        private string selectedCategory = "ВСЕ ИГРЫ";
        private bool adminMode = false;
        private bool adminView = false;
        private DateTime sessionStart = DateTime.Now;
        private Process runningGame;
        private string runningGameName = "";
        private int cardBase = 170;

        public MainForm()
        {
            cfg = AppConfig.Load();
            Text = "ЭПОХА — КОМПЬЮТЕРНЫЙ КЛУБ"; FormBorderStyle = FormBorderStyle.None; WindowState = FormWindowState.Maximized;
            BackColor = Color.FromArgb(7,10,17); KeyPreview = true; MinimumSize = new Size(900,650);
            SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer, true);
            BuildChrome(); ApplyConfigToUi(); ShowGames();
            clockTimer = new Timer(); clockTimer.Interval = 1000; clockTimer.Tick += delegate { UpdateClockAndStatus(); }; clockTimer.Start();
            Resize += delegate { LayoutHeader(); LayoutCards(); };
            KeyDown += MainForm_KeyDown;
            UpdateClockAndStatus();
        }

        private Font F(float n, FontStyle s) { return new Font("Tahoma", n, s); }

        private void BuildChrome()
        {
            root = new TableLayoutPanel(); root.Dock = DockStyle.Fill; root.Margin = new Padding(0); root.Padding = new Padding(0); root.BackColor = Color.FromArgb(7,10,17);
            root.ColumnCount=2; root.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 285)); root.ColumnStyles.Add(new ColumnStyle(SizeType.Percent,100));
            root.RowCount=3; root.RowStyles.Add(new RowStyle(SizeType.Absolute,86)); root.RowStyles.Add(new RowStyle(SizeType.Percent,100)); root.RowStyles.Add(new RowStyle(SizeType.Absolute,26));
            Controls.Add(root);

            brandHeader = new GradientPanel(); brandHeader.Dock=DockStyle.Fill; brandHeader.Margin=new Padding(0); brandHeader.TopColor=Color.FromArgb(25,30,43); brandHeader.BottomColor=Color.FromArgb(11,15,24);
            root.Controls.Add(brandHeader,0,0);
            Label logo = new Label(); logo.Text="Э"; logo.TextAlign=ContentAlignment.MiddleCenter; logo.SetBounds(14,15,50,50); logo.Font=F(24,FontStyle.Bold); logo.ForeColor=Color.FromArgb(20,16,28); logo.BackColor=Accent; brandHeader.Controls.Add(logo);
            brandTitle = new Label(); brandTitle.Text="ЭПОХА"; brandTitle.AutoSize=true; brandTitle.Font=F(17,FontStyle.Bold); brandTitle.ForeColor=Accent; brandTitle.Location=new Point(76,12); brandHeader.Controls.Add(brandTitle);
            brandSub = new Label(); brandSub.Text="КОМПЬЮТЕРНЫЙ КЛУБ  •  2000—2015"; brandSub.AutoSize=true; brandSub.Font=F(7.4f,FontStyle.Bold); brandSub.ForeColor=Color.FromArgb(185,194,211); brandSub.Location=new Point(77,39); brandHeader.Controls.Add(brandSub);
            pcBadge = new Label(); pcBadge.AutoSize=false; pcBadge.SetBounds(76,58,94,20); pcBadge.TextAlign=ContentAlignment.MiddleCenter; pcBadge.Font=F(8,FontStyle.Bold); pcBadge.ForeColor=Color.White; pcBadge.BackColor=Color.FromArgb(42,48,64); brandHeader.Controls.Add(pcBadge);

            topHeader = new GradientPanel(); topHeader.Dock=DockStyle.Fill; topHeader.Margin=new Padding(0); topHeader.TopColor=Color.FromArgb(29,35,49); topHeader.BottomColor=Color.FromArgb(14,18,28); root.Controls.Add(topHeader,1,0);
            statusBox = new DbPanel(); statusBox.BackColor=Color.FromArgb(21,27,39); statusBox.Height=58; topHeader.Controls.Add(statusBox); statusBox.Paint += StatusBox_Paint;
            statusTitle = new Label(); statusTitle.AutoSize=false; statusTitle.TextAlign=ContentAlignment.BottomCenter; statusTitle.Font=F(11,FontStyle.Bold); statusTitle.ForeColor=Color.White; statusTitle.BackColor=Color.FromArgb(21,27,39); statusBox.Controls.Add(statusTitle);
            statusSub = new Label(); statusSub.AutoSize=false; statusSub.TextAlign=ContentAlignment.TopCenter; statusSub.Font=F(7.8f,FontStyle.Regular); statusSub.ForeColor=Color.FromArgb(170,183,205); statusSub.BackColor=Color.FromArgb(21,27,39); statusBox.Controls.Add(statusSub);
            clockLabel = new Label(); clockLabel.AutoSize=true; clockLabel.Font=F(19,FontStyle.Bold); clockLabel.ForeColor=Color.White; topHeader.Controls.Add(clockLabel);
            dateLabel = new Label(); dateLabel.AutoSize=true; dateLabel.Font=F(7.5f,FontStyle.Regular); dateLabel.ForeColor=Color.FromArgb(155,166,187); topHeader.Controls.Add(dateLabel);
            adminButton = new IconButton(IconButton.IconKind.Admin); adminButton.Click += AdminButton_Click; topHeader.Controls.Add(adminButton);
            restartButton = new IconButton(IconButton.IconKind.Restart); restartButton.Click += Restart_Click; topHeader.Controls.Add(restartButton);
            powerButton = new IconButton(IconButton.IconKind.Power); powerButton.Click += Power_Click; topHeader.Controls.Add(powerButton);

            navHost = new DbPanel(); navHost.Dock=DockStyle.Fill; navHost.Margin=new Padding(0); navHost.BackColor=Color.FromArgb(12,16,25); root.Controls.Add(navHost,0,1); root.SetRowSpan(navHost,2);
            Label navCaption = new Label(); navCaption.Text="БИБЛИОТЕКА"; navCaption.SetBounds(18,16,220,24); navCaption.Font=F(8,FontStyle.Bold); navCaption.ForeColor=Color.FromArgb(113,126,151); navHost.Controls.Add(navCaption);
            navList = new FlowLayoutPanel(); navList.FlowDirection=FlowDirection.TopDown; navList.WrapContents=false; navList.AutoScroll=true; navList.SetBounds(10,48,265,ClientSize.Height-150); navList.Anchor=AnchorStyles.Top|AnchorStyles.Bottom|AnchorStyles.Left|AnchorStyles.Right; navList.BackColor=Color.FromArgb(12,16,25); navHost.Controls.Add(navList);

            work = new WallpaperPanel(); work.Dock=DockStyle.Fill; work.Margin=new Padding(0); root.Controls.Add(work,1,1);
            footer = new DbPanel(); footer.Dock=DockStyle.Fill; footer.Margin=new Padding(0); footer.BackColor=Color.FromArgb(12,16,25); root.Controls.Add(footer,1,2);
            footerLabel = new Label(); footerLabel.Dock=DockStyle.Fill; footerLabel.TextAlign=ContentAlignment.MiddleLeft; footerLabel.Padding=new Padding(16,0,0,0); footerLabel.Font=F(7,FontStyle.Regular); footerLabel.ForeColor=Color.FromArgb(115,129,153); footerLabel.BackColor=Color.FromArgb(12,16,25); footer.Controls.Add(footerLabel);
            BuildNav();
            Shown += delegate { LayoutHeader(); LayoutCards(); };
        }

        private void ApplyConfigToUi()
        {
            pcBadge.Text="ПК №" + cfg.PcNumber;
            brandTitle.ForeColor=Accent; adminButton.Accent=Accent; restartButton.Accent=Accent; powerButton.Accent=Accent;
            work.Mode=cfg.WallpaperMode; work.Dim=cfg.WallpaperDim; work.LoadWallpaper(cfg.WallpaperPath);
            if (cfg.CardSize=="Маленькие") cardBase=145; else if (cfg.CardSize=="Большие") cardBase=205; else cardBase=170;
            ApplyAutoStart();
        }

        private void BuildNav()
        {
            navList.SuspendLayout(); navList.Controls.Clear();
            AddNav("ВСЕ ИГРЫ");
            foreach (string cat in cfg.Categories) AddNav(cat);
            navList.ResumeLayout();
        }
        private void AddNav(string name)
        {
            NavButton b=new NavButton(); b.Text=name; b.Width=245; b.Accent=Accent; b.Selected=(name==selectedCategory); b.Click+=delegate { selectedCategory=name; adminView=false; BuildNav(); ShowGames(); }; navList.Controls.Add(b);
        }

        private void ShowGames()
        {
            adminView=false; work.SuspendLayout(); DisposeChildren(work); work.Controls.Clear();
            FlowLayoutPanel grid=new FlowLayoutPanel(); grid.Name="gamesGrid"; grid.Dock=DockStyle.Fill; grid.Padding=new Padding(24,22,18,18); grid.WrapContents=true; grid.AutoScroll=true; grid.BackColor=Color.FromArgb(9,12,19); work.Controls.Add(grid);
            foreach(GameItem g in cfg.Games)
            {
                if (selectedCategory!="ВСЕ ИГРЫ" && g.Category!=selectedCategory) continue;
                GameCard c=new GameCard(g,Accent); c.Click+=delegate(object s,EventArgs e){ LaunchGame(((GameCard)s).Game); }; grid.Controls.Add(c);
            }
            work.ResumeLayout(); LayoutCards();
        }

        private void LayoutCards()
        {
            Control[] arr=work.Controls.Find("gamesGrid",true); if(arr.Length==0)return; FlowLayoutPanel grid=arr[0] as FlowLayoutPanel; if(grid==null)return;
            int available=Math.Max(400,grid.ClientSize.Width-50); int wanted=cardBase; int cols=Math.Max(2,available/(wanted+18)); int w=Math.Max(125,Math.Min(cardBase+35,(available-cols*18)/cols)); int h=(int)(w*0.68)+44;
            foreach(Control c in grid.Controls){ c.Size=new Size(w,h); c.Margin=new Padding(9); }
        }

        private void LayoutHeader()
        {
            int w=topHeader.ClientSize.Width; if(w<400)return;
            int rightButtons=46*3+8*2+16; int clockW=150; int statusLeft=24; int statusRight=rightButtons+clockW+42; int statusW=Math.Max(300,w-statusLeft-statusRight);
            statusBox.SetBounds(statusLeft,14,statusW,58); statusTitle.SetBounds(12,8,statusW-24,22); statusSub.SetBounds(12,31,statusW-24,19);
            int x=w-16-46; powerButton.Location=new Point(x,20); x-=54; restartButton.Location=new Point(x,20); x-=54; adminButton.Location=new Point(x,20);
            clockLabel.Location=new Point(x-clockLabel.PreferredWidth-24,13); dateLabel.Location=new Point(x-dateLabel.PreferredWidth-24,49);
        }

        private void StatusBox_Paint(object sender, PaintEventArgs e)
        {
            e.Graphics.SmoothingMode=SmoothingMode.AntiAlias; Rectangle r=new Rectangle(0,0,statusBox.Width-1,statusBox.Height-1);
            using(Pen p=new Pen(Color.FromArgb(90,Accent))) e.Graphics.DrawRectangle(p,r);
            using(SolidBrush b=new SolidBrush(Accent)) e.Graphics.FillRectangle(b,0,0,4,statusBox.Height);
        }

        private void UpdateClockAndStatus()
        {
            clockLabel.Text=DateTime.Now.ToString("HH:mm:ss"); dateLabel.Text=DateTime.Now.ToString("dd.MM.yyyy");
            bool locked=false; string session;
            if(cfg.SessionMode=="По времени")
            {
                TimeSpan left=TimeSpan.FromMinutes(cfg.SessionMinutes)-(DateTime.Now-sessionStart); if(left.TotalSeconds<=0){ locked=true; left=TimeSpan.Zero; }
                session="ОСТАЛОСЬ: "+String.Format("{0:00}:{1:00}:{2:00}",(int)left.TotalHours,left.Minutes,left.Seconds);
            } else session="СЕАНС: БЕССРОЧНО";
            if(locked){statusTitle.Text="СЕАНС ЗАВЕРШЕН";statusTitle.ForeColor=Color.FromArgb(255,115,115);statusSub.Text="ДОСТУП К ИГРАМ ЗАБЛОКИРОВАН";}
            else if(runningGame!=null && !runningGame.HasExited){statusTitle.Text="ИГРА: "+runningGameName.ToUpper();statusTitle.ForeColor=Accent;statusSub.Text=session;}
            else {statusTitle.Text="СИСТЕМА ГОТОВА";statusTitle.ForeColor=Color.FromArgb(126,235,165);statusSub.Text=session;runningGame=null;runningGameName="";}
            footerLabel.Text="ЭПОХА 0.4.0  •  ПК №"+cfg.PcNumber+"  •  "+Environment.MachineName+"  •  WINDOWS 7 CLUB SHELL";
            LayoutHeader();
        }

        private bool SessionLocked()
        {
            return cfg.SessionMode=="По времени" && (DateTime.Now-sessionStart).TotalMinutes>=cfg.SessionMinutes;
        }

        private void LaunchGame(GameItem g)
        {
            if(SessionLocked()){MessageBox.Show("Сеанс завершён. Обратитесь к администратору.","ЭПОХА",MessageBoxButtons.OK,MessageBoxIcon.Information);return;}
            if(String.IsNullOrEmpty(g.Exe)||!File.Exists(g.Exe)){MessageBox.Show("Для «"+g.Name+"» пока не указан существующий EXE.\r\nДобавьте путь в настройках администратора.","ЭПОХА");return;}
            try
            {
                ProcessStartInfo psi=new ProcessStartInfo(g.Exe,g.Args==null?"":g.Args); if(!String.IsNullOrEmpty(g.WorkDir)&&Directory.Exists(g.WorkDir))psi.WorkingDirectory=g.WorkDir;
                Process p=Process.Start(psi); if(p!=null){runningGame=p;runningGameName=g.Name;p.EnableRaisingEvents=true;p.Exited+=delegate{BeginInvoke(new MethodInvoker(delegate{runningGame=null;runningGameName="";UpdateClockAndStatus();}));};}
            }catch(Exception ex){MessageBox.Show("Не удалось запустить игру:\r\n"+ex.Message,"ЭПОХА",MessageBoxButtons.OK,MessageBoxIcon.Error);}
        }

        private void AdminButton_Click(object sender, EventArgs e)
        {
            if(!adminMode)
            {
                string p=AskPassword(); if(p==null)return; if(p!=cfg.AdminPassword){MessageBox.Show("Неверный пароль.","ЭПОХА",MessageBoxButtons.OK,MessageBoxIcon.Warning);return;} adminMode=true;
            }
            if(adminView) ShowGames(); else ShowAdmin("Общие");
        }

        private string AskPassword()
        {
            Form f=new Form(); f.Text="ЭПОХА — Администратор"; f.StartPosition=FormStartPosition.CenterScreen; f.FormBorderStyle=FormBorderStyle.FixedDialog; f.ClientSize=new Size(390,145); f.MaximizeBox=false;f.MinimizeBox=false;f.Font=F(9,FontStyle.Regular);f.BackColor=Color.FromArgb(27,31,41);f.ForeColor=Color.White;
            Label l=new Label();l.Text="Пароль администратора";l.SetBounds(18,15,340,22);l.BackColor=f.BackColor;f.Controls.Add(l); TextBox t=new TextBox();t.UseSystemPasswordChar=true;t.SetBounds(18,42,350,25);f.Controls.Add(t);
            Button ok=new Button();ok.Text="ВОЙТИ";ok.DialogResult=DialogResult.OK;ok.SetBounds(198,88,80,30);f.Controls.Add(ok);Button cancel=new Button();cancel.Text="ОТМЕНА";cancel.DialogResult=DialogResult.Cancel;cancel.SetBounds(288,88,80,30);f.Controls.Add(cancel);f.AcceptButton=ok;f.CancelButton=cancel;
            return f.ShowDialog()==DialogResult.OK?t.Text:null;
        }

        private void ShowAdmin(string section)
        {
            adminView=true; work.SuspendLayout(); DisposeChildren(work); work.Controls.Clear();
            TableLayoutPanel shell=new TableLayoutPanel(); shell.Dock=DockStyle.Fill; shell.BackColor=Color.FromArgb(11,15,23); shell.ColumnCount=2; shell.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute,210)); shell.ColumnStyles.Add(new ColumnStyle(SizeType.Percent,100)); work.Controls.Add(shell);
            DbPanel menu=new DbPanel();menu.Dock=DockStyle.Fill;menu.BackColor=Color.FromArgb(17,22,32);shell.Controls.Add(menu,0,0);
            Label cap=new Label();cap.Text="НАСТРОЙКИ";cap.SetBounds(18,18,170,25);cap.Font=F(10,FontStyle.Bold);cap.ForeColor=Accent;cap.BackColor=menu.BackColor;menu.Controls.Add(cap);
            string[] names={"Общие","Внешний вид","Вкладки","Игры и ярлыки","Система"};int y=58;
            foreach(string n in names){NavButton b=new NavButton();b.Text=n.ToUpper();b.Accent=Accent;b.Selected=(n==section);b.SetBounds(10,y,190,44);string key=n;b.Click+=delegate{ShowAdmin(key);};menu.Controls.Add(b);y+=46;}
            Button logout=new Button();logout.Text="ВЫЙТИ ИЗ АДМИНКИ";logout.SetBounds(16,ClientSize.Height-195,178,34);logout.Anchor=AnchorStyles.Left|AnchorStyles.Bottom;logout.Click+=delegate{adminMode=false;ShowGames();};menu.Controls.Add(logout);
            DbPanel content=new DbPanel();content.Dock=DockStyle.Fill;content.BackColor=Color.FromArgb(13,17,26);shell.Controls.Add(content,1,0);
            if(section=="Общие")BuildAdminGeneral(content);else if(section=="Внешний вид")BuildAdminAppearance(content);else if(section=="Вкладки")BuildAdminCategories(content);else if(section=="Игры и ярлыки")BuildAdminGames(content);else BuildAdminSystem(content);
            work.ResumeLayout();
        }

        private Label Title(DbPanel p,string text){Label l=new Label();l.Text=text.ToUpper();l.SetBounds(28,22,650,36);l.Font=F(16,FontStyle.Bold);l.ForeColor=Color.White;l.BackColor=p.BackColor;p.Controls.Add(l);return l;}
        private Label FieldLabel(DbPanel p,string text,int y){Label l=new Label();l.Text=text;l.SetBounds(30,y,220,20);l.Font=F(8,FontStyle.Regular);l.ForeColor=Color.FromArgb(165,177,198);l.BackColor=p.BackColor;p.Controls.Add(l);return l;}
        private Button ActionButton(DbPanel p,string text,int x,int y,int w,EventHandler ev){Button b=new Button();b.Text=text;b.SetBounds(x,y,w,32);b.FlatStyle=FlatStyle.Flat;b.FlatAppearance.BorderColor=Accent;b.BackColor=Color.FromArgb(28,34,48);b.ForeColor=Color.White;b.Font=F(8,FontStyle.Bold);b.Click+=ev;p.Controls.Add(b);return b;}

        private void BuildAdminGeneral(DbPanel p)
        {
            Title(p,"Общие");
            FieldLabel(p,"Номер компьютера",80);TextBox pc=new TextBox();pc.Text=cfg.PcNumber;pc.SetBounds(30,102,180,24);p.Controls.Add(pc);
            FieldLabel(p,"Пароль администратора",142);TextBox pass=new TextBox();pass.Text=cfg.AdminPassword;pass.SetBounds(30,164,260,24);p.Controls.Add(pass);
            FieldLabel(p,"Режим сеанса",204);ComboBox mode=new ComboBox();mode.DropDownStyle=ComboBoxStyle.DropDownList;mode.Items.AddRange(new object[]{"Бессрочно","По времени"});mode.SelectedItem=cfg.SessionMode;mode.SetBounds(30,226,200,24);p.Controls.Add(mode);
            FieldLabel(p,"Продолжительность сеанса, минут",266);NumericUpDown mins=new NumericUpDown();mins.Minimum=5;mins.Maximum=1440;mins.Value=Math.Max(5,Math.Min(1440,cfg.SessionMinutes));mins.SetBounds(30,288,120,24);p.Controls.Add(mins);
            ActionButton(p,"СОХРАНИТЬ",30,340,130,delegate{cfg.PcNumber=pc.Text.Trim()==""?"01":pc.Text.Trim();cfg.AdminPassword=pass.Text==""?"2000":pass.Text;cfg.SessionMode=mode.SelectedItem==null?"Бессрочно":mode.SelectedItem.ToString();cfg.SessionMinutes=(int)mins.Value;cfg.Save();ApplyConfigToUi();UpdateClockAndStatus();MessageBox.Show("Настройки сохранены.","ЭПОХА");});
            ActionButton(p,"СБРОСИТЬ СЕАНС",170,340,150,delegate{sessionStart=DateTime.Now;UpdateClockAndStatus();});
        }

        private void BuildAdminAppearance(DbPanel p)
        {
            Title(p,"Внешний вид");
            FieldLabel(p,"Цвет интерфейса",80);Panel swatch=new Panel();swatch.BackColor=Accent;swatch.SetBounds(30,104,42,26);p.Controls.Add(swatch);
            ActionButton(p,"ВЫБРАТЬ ЦВЕТ",82,101,150,32,delegate{using(ColorDialog d=new ColorDialog()){d.Color=Accent;if(d.ShowDialog()==DialogResult.OK){cfg.AccentArgb=d.Color.ToArgb();cfg.Save();ApplyConfigToUi();BuildNav();ShowAdmin("Внешний вид");}}});
            FieldLabel(p,"Обои рабочей области",154);TextBox wall=new TextBox();wall.ReadOnly=true;wall.Text=String.IsNullOrEmpty(cfg.WallpaperPath)?"Не выбраны":cfg.WallpaperPath;wall.SetBounds(30,176,520,24);p.Controls.Add(wall);
            ActionButton(p,"ВЫБРАТЬ ОБОИ",30,210,150,32,delegate{ChooseWallpaper();ShowAdmin("Внешний вид");});
            ActionButton(p,"УБРАТЬ ОБОИ",190,210,150,32,delegate{cfg.WallpaperPath="";cfg.Save();ApplyConfigToUi();ShowAdmin("Внешний вид");});
            FieldLabel(p,"Режим обоев",260);ComboBox wm=new ComboBox();wm.DropDownStyle=ComboBoxStyle.DropDownList;wm.Items.AddRange(new object[]{"Fill","Stretch","Center"});wm.SelectedItem=cfg.WallpaperMode;wm.SetBounds(30,282,180,24);p.Controls.Add(wm);
            FieldLabel(p,"Затемнение обоев",326);TrackBar dim=new TrackBar();dim.Minimum=0;dim.Maximum=90;dim.TickFrequency=10;dim.Value=Math.Max(0,Math.Min(90,cfg.WallpaperDim));dim.SetBounds(24,348,330,45);p.Controls.Add(dim);Label dimVal=new Label();dimVal.Text=dim.Value+"%";dimVal.SetBounds(365,354,80,24);dimVal.ForeColor=Color.White;dimVal.BackColor=p.BackColor;p.Controls.Add(dimVal);dim.Scroll+=delegate{dimVal.Text=dim.Value+"%";work.Dim=dim.Value;work.Invalidate();};
            FieldLabel(p,"Размер карточек",408);ComboBox cs=new ComboBox();cs.DropDownStyle=ComboBoxStyle.DropDownList;cs.Items.AddRange(new object[]{"Маленькие","Средние","Большие"});cs.SelectedItem=cfg.CardSize;cs.SetBounds(30,430,180,24);p.Controls.Add(cs);
            ActionButton(p,"СОХРАНИТЬ ВНЕШНИЙ ВИД",30,480,220,34,delegate{cfg.WallpaperMode=wm.SelectedItem==null?"Fill":wm.SelectedItem.ToString();cfg.WallpaperDim=dim.Value;cfg.CardSize=cs.SelectedItem==null?"Средние":cs.SelectedItem.ToString();cfg.Save();ApplyConfigToUi();ShowAdmin("Внешний вид");});
        }

        private void ChooseWallpaper()
        {
            using(OpenFileDialog d=new OpenFileDialog())
            {
                d.Filter="Изображения|*.jpg;*.jpeg;*.png;*.bmp|Все файлы|*.*"; if(d.ShowDialog()!=DialogResult.OK)return;
                try{string ext=Path.GetExtension(d.FileName);string dst=Path.Combine(Program.AppDir,"wallpaper"+ext);File.Copy(d.FileName,dst,true);cfg.WallpaperPath=dst;cfg.Save();ApplyConfigToUi();}
                catch(Exception ex){MessageBox.Show("Не удалось установить обои:\r\n"+ex.Message,"ЭПОХА",MessageBoxButtons.OK,MessageBoxIcon.Error);}
            }
        }

        private void BuildAdminCategories(DbPanel p)
        {
            Title(p,"Вкладки");ListBox list=new ListBox();list.SetBounds(30,82,390,360);foreach(string s in cfg.Categories)list.Items.Add(s);p.Controls.Add(list);
            ActionButton(p,"ДОБАВИТЬ",440,82,130,32,delegate{string s=InputBox("Новая вкладка","Название вкладки","");if(!String.IsNullOrEmpty(s)){cfg.Categories.Add(s.ToUpper());cfg.Save();BuildNav();ShowAdmin("Вкладки");}});
            ActionButton(p,"ПЕРЕИМЕНОВАТЬ",440,124,150,32,delegate{if(list.SelectedIndex<0)return;string old=cfg.Categories[list.SelectedIndex];string s=InputBox("Переименовать","Новое название",old);if(String.IsNullOrEmpty(s))return;s=s.ToUpper();cfg.Categories[list.SelectedIndex]=s;foreach(GameItem g in cfg.Games)if(g.Category==old)g.Category=s;cfg.Save();BuildNav();ShowAdmin("Вкладки");});
            ActionButton(p,"ВВЕРХ",440,176,110,32,delegate{MoveCategory(list.SelectedIndex,-1);ShowAdmin("Вкладки");});ActionButton(p,"ВНИЗ",560,176,110,32,delegate{MoveCategory(list.SelectedIndex,1);ShowAdmin("Вкладки");});
            ActionButton(p,"УДАЛИТЬ",440,228,130,32,delegate{if(list.SelectedIndex<0)return;string s=cfg.Categories[list.SelectedIndex];if(MessageBox.Show("Удалить вкладку «"+s+"»? Игры останутся и будут видны в «Все игры».","ЭПОХА",MessageBoxButtons.YesNo)==DialogResult.Yes){cfg.Categories.RemoveAt(list.SelectedIndex);cfg.Save();BuildNav();ShowAdmin("Вкладки");}});
        }
        private void MoveCategory(int i,int d){int n=i+d;if(i<0||n<0||n>=cfg.Categories.Count)return;string x=cfg.Categories[i];cfg.Categories.RemoveAt(i);cfg.Categories.Insert(n,x);cfg.Save();BuildNav();}

        private void BuildAdminGames(DbPanel p)
        {
            Title(p,"Игры и ярлыки");ListBox list=new ListBox();list.SetBounds(30,82,500,390);foreach(GameItem g in cfg.Games)list.Items.Add(g);p.Controls.Add(list);
            ActionButton(p,"ДОБАВИТЬ",550,82,130,32,delegate{GameItem g=EditGame(null);if(g!=null){cfg.Games.Add(g);cfg.Save();ShowAdmin("Игры и ярлыки");}});
            ActionButton(p,"ИЗМЕНИТЬ",550,124,130,32,delegate{if(list.SelectedIndex<0)return;GameItem g=EditGame(cfg.Games[list.SelectedIndex]);if(g!=null){cfg.Games[list.SelectedIndex]=g;cfg.Save();ShowAdmin("Игры и ярлыки");}});
            ActionButton(p,"УДАЛИТЬ",550,166,130,32,delegate{if(list.SelectedIndex<0)return;cfg.Games.RemoveAt(list.SelectedIndex);cfg.Save();ShowAdmin("Игры и ярлыки");});
            ActionButton(p,"ВВЕРХ",550,218,100,32,delegate{MoveGame(list.SelectedIndex,-1);ShowAdmin("Игры и ярлыки");});ActionButton(p,"ВНИЗ",660,218,100,32,delegate{MoveGame(list.SelectedIndex,1);ShowAdmin("Игры и ярлыки");});
        }
        private void MoveGame(int i,int d){int n=i+d;if(i<0||n<0||n>=cfg.Games.Count)return;GameItem x=cfg.Games[i];cfg.Games.RemoveAt(i);cfg.Games.Insert(n,x);cfg.Save();}

        private GameItem EditGame(GameItem src)
        {
            GameItem g=new GameItem();if(src!=null){g.Name=src.Name;g.Category=src.Category;g.Exe=src.Exe;g.Args=src.Args;g.WorkDir=src.WorkDir;g.ImagePath=src.ImagePath;}
            Form f=new Form();f.Text=src==null?"ЭПОХА — Добавить":"ЭПОХА — Изменить";f.StartPosition=FormStartPosition.CenterScreen;f.ClientSize=new Size(620,370);f.FormBorderStyle=FormBorderStyle.FixedDialog;f.MaximizeBox=false;f.MinimizeBox=false;f.Font=F(9,FontStyle.Regular);
            LabelText(f,"Название",16);TextBox name=Box(f,g.Name,38,420);LabelText(f,"Вкладка",76);ComboBox cat=new ComboBox();cat.DropDownStyle=ComboBoxStyle.DropDownList;foreach(string s in cfg.Categories)cat.Items.Add(s);if(cat.Items.Count>0)cat.SelectedItem=cfg.Categories.Contains(g.Category)?g.Category:cat.Items[0];cat.SetBounds(16,98,250,24);f.Controls.Add(cat);
            LabelText(f,"EXE",136);TextBox exe=Box(f,g.Exe,158,500);Button be=new Button();be.Text="...";be.SetBounds(526,157,60,26);be.Click+=delegate{using(OpenFileDialog d=new OpenFileDialog()){d.Filter="Программы|*.exe|Все файлы|*.*";if(d.ShowDialog()==DialogResult.OK)exe.Text=d.FileName;}};f.Controls.Add(be);
            LabelText(f,"Параметры запуска",196);TextBox args=Box(f,g.Args,218,570);LabelText(f,"Картинка карточки",256);TextBox img=Box(f,g.ImagePath,278,500);Button bi=new Button();bi.Text="...";bi.SetBounds(526,277,60,26);bi.Click+=delegate{using(OpenFileDialog d=new OpenFileDialog()){d.Filter="Изображения|*.jpg;*.jpeg;*.png;*.bmp";if(d.ShowDialog()==DialogResult.OK)img.Text=d.FileName;}};f.Controls.Add(bi);
            Button ok=new Button();ok.Text="СОХРАНИТЬ";ok.DialogResult=DialogResult.OK;ok.SetBounds(390,326,100,30);f.Controls.Add(ok);Button cancel=new Button();cancel.Text="ОТМЕНА";cancel.DialogResult=DialogResult.Cancel;cancel.SetBounds(500,326,86,30);f.Controls.Add(cancel);f.AcceptButton=ok;f.CancelButton=cancel;
            if(f.ShowDialog()!=DialogResult.OK)return null;g.Name=name.Text.Trim();g.Category=cat.SelectedItem==null?"ПРОГРАММЫ":cat.SelectedItem.ToString();g.Exe=exe.Text.Trim();g.Args=args.Text;g.ImagePath=img.Text.Trim();if(!String.IsNullOrEmpty(g.Exe))g.WorkDir=Path.GetDirectoryName(g.Exe);return g;
        }
        private void LabelText(Form f,string t,int y){Label l=new Label();l.Text=t;l.SetBounds(16,y,300,20);f.Controls.Add(l);}private TextBox Box(Form f,string t,int y,int w){TextBox b=new TextBox();b.Text=t;b.SetBounds(16,y,w,24);f.Controls.Add(b);return b;}

        private void BuildAdminSystem(DbPanel p)
        {
            Title(p,"Система");CheckBox auto=new CheckBox();auto.Text="Запускать ЭПОХУ при входе Windows";auto.Checked=cfg.AutoStart;auto.SetBounds(30,90,340,25);auto.ForeColor=Color.White;auto.BackColor=p.BackColor;p.Controls.Add(auto);
            CheckBox confirm=new CheckBox();confirm.Text="Спрашивать подтверждение перед выключением/перезагрузкой";confirm.Checked=cfg.ConfirmPower;confirm.SetBounds(30,128,440,25);confirm.ForeColor=Color.White;confirm.BackColor=p.BackColor;p.Controls.Add(confirm);
            Label info=new Label();info.Text="Клубная блокировка Windows и замена Explorer будут добавлены отдельным безопасным этапом после стабилизации интерфейса.\r\nАварийный вход администратора: Ctrl + Alt + E.";info.SetBounds(30,180,650,80);info.ForeColor=Color.FromArgb(166,180,204);info.BackColor=p.BackColor;p.Controls.Add(info);
            ActionButton(p,"СОХРАНИТЬ",30,285,130,34,delegate{cfg.AutoStart=auto.Checked;cfg.ConfirmPower=confirm.Checked;cfg.Save();ApplyAutoStart();MessageBox.Show("Системные настройки сохранены.","ЭПОХА");});
        }

        private string InputBox(string title,string label,string value)
        {
            Form f=new Form();f.Text=title;f.StartPosition=FormStartPosition.CenterScreen;f.ClientSize=new Size(400,135);f.FormBorderStyle=FormBorderStyle.FixedDialog;Label l=new Label();l.Text=label;l.SetBounds(15,15,350,20);f.Controls.Add(l);TextBox t=new TextBox();t.Text=value;t.SetBounds(15,40,365,24);f.Controls.Add(t);Button ok=new Button();ok.Text="OK";ok.DialogResult=DialogResult.OK;ok.SetBounds(220,82,75,28);f.Controls.Add(ok);Button ca=new Button();ca.Text="Отмена";ca.DialogResult=DialogResult.Cancel;ca.SetBounds(305,82,75,28);f.Controls.Add(ca);f.AcceptButton=ok;f.CancelButton=ca;return f.ShowDialog()==DialogResult.OK?t.Text.Trim():null;
        }

        private void ApplyAutoStart()
        {
            try{using(RegistryKey k=Registry.CurrentUser.CreateSubKey(@"Software\Microsoft\Windows\CurrentVersion\Run")){if(cfg.AutoStart)k.SetValue("EpohaShell",Application.ExecutablePath);else k.DeleteValue("EpohaShell",false);}}catch(Exception ex){File.AppendAllText(Program.LogPath,"Autostart: "+ex+"\r\n");}
        }

        private void Restart_Click(object sender,EventArgs e){if(cfg.ConfirmPower&&MessageBox.Show("Перезагрузить компьютер?","ЭПОХА",MessageBoxButtons.YesNo,MessageBoxIcon.Question)!=DialogResult.Yes)return;Process.Start(new ProcessStartInfo("shutdown.exe","/r /t 0"){UseShellExecute=false,CreateNoWindow=true});}
        private void Power_Click(object sender,EventArgs e){if(cfg.ConfirmPower&&MessageBox.Show("Выключить компьютер?","ЭПОХА",MessageBoxButtons.YesNo,MessageBoxIcon.Question)!=DialogResult.Yes)return;Process.Start(new ProcessStartInfo("shutdown.exe","/s /t 0"){UseShellExecute=false,CreateNoWindow=true});}
        private void MainForm_KeyDown(object sender,KeyEventArgs e){if(e.Control&&e.Alt&&e.KeyCode==Keys.E){AdminButton_Click(this,EventArgs.Empty);e.SuppressKeyPress=true;}}
        private void DisposeChildren(Control p){foreach(Control c in p.Controls){try{c.Dispose();}catch{}}}
    }
}
