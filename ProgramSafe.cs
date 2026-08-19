using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.IO;
using System.Windows.Forms;
using System.Xml.Serialization;

namespace EpohaShell
{
    [Serializable]
    public class AppConfig
    {
        public string AdminPassword = "2000";
        public string PcLabel = "ПК №01";
        public int AccentArgb = Color.FromArgb(151, 82, 255).ToArgb();
        public string WallpaperPath = "";
        public string WallpaperMode = "Fill";
        public int WallpaperDarkness = 120;
        public string CardSize = "Auto";
        public List<CategoryItem> Categories = new List<CategoryItem>();
        public List<GameItem> Games = new List<GameItem>();
    }

    [Serializable]
    public class CategoryItem
    {
        public string Id = Guid.NewGuid().ToString("N");
        public string Name = "РАЗДЕЛ";
        public int Sort = 0;
        public override string ToString() { return Name; }
    }

    [Serializable]
    public class GameItem
    {
        public string Id = Guid.NewGuid().ToString("N");
        public string CategoryId = "";
        public string Name = "Игра";
        public string ExePath = "";
        public string Arguments = "";
        public string WorkingDirectory = "";
        public string ImagePath = "";
        public int Sort = 0;
        public override string ToString() { return Name; }
    }

    public static class ConfigStore
    {
        public static string BaseDir
        {
            get
            {
                return Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Epoha");
            }
        }

        public static string ConfigPath { get { return Path.Combine(BaseDir, "config.xml"); } }

        public static AppConfig Load()
        {
            try
            {
                if (!Directory.Exists(BaseDir)) Directory.CreateDirectory(BaseDir);
                if (File.Exists(ConfigPath))
                {
                    XmlSerializer xs = new XmlSerializer(typeof(AppConfig));
                    using (FileStream fs = File.OpenRead(ConfigPath))
                        return (AppConfig)xs.Deserialize(fs);
                }
            }
            catch
            {
                try
                {
                    string bad = ConfigPath + ".broken-" + DateTime.Now.ToString("yyyyMMdd-HHmmss");
                    if (File.Exists(ConfigPath)) File.Copy(ConfigPath, bad, true);
                }
                catch { }
            }

            AppConfig c = CreateDefault();
            Save(c);
            return c;
        }

        public static void Save(AppConfig c)
        {
            if (!Directory.Exists(BaseDir)) Directory.CreateDirectory(BaseDir);
            XmlSerializer xs = new XmlSerializer(typeof(AppConfig));
            using (FileStream fs = File.Create(ConfigPath)) xs.Serialize(fs, c);
        }

        public static AppConfig CreateDefault()
        {
            AppConfig c = new AppConfig();
            CategoryItem all = Cat("all", "ВСЕ ИГРЫ", 0);
            CategoryItem shooters = Cat(null, "ШУТЕРЫ", 10);
            CategoryItem action = Cat(null, "ЭКШЕН", 20);
            CategoryItem strategy = Cat(null, "СТРАТЕГИИ", 30);
            CategoryItem rpg = Cat(null, "RPG", 40);
            CategoryItem programs = Cat(null, "ПРОГРАММЫ", 50);
            c.Categories.Add(all);
            c.Categories.Add(shooters);
            c.Categories.Add(action);
            c.Categories.Add(strategy);
            c.Categories.Add(rpg);
            c.Categories.Add(programs);
            c.Games.Add(Game("Counter-Strike 1.6", shooters.Id, 10));
            c.Games.Add(Game("S.T.A.L.K.E.R.", shooters.Id, 20));
            c.Games.Add(Game("Unreal Tournament", shooters.Id, 30));
            c.Games.Add(Game("GTA San Andreas", action.Id, 40));
            c.Games.Add(Game("Assassin's Creed", action.Id, 50));
            c.Games.Add(Game("Warcraft III", strategy.Id, 60));
            c.Games.Add(Game("Diablo II", rpg.Id, 70));
            return c;
        }

        private static CategoryItem Cat(string id, string name, int sort)
        {
            CategoryItem c = new CategoryItem();
            if (!String.IsNullOrEmpty(id)) c.Id = id;
            c.Name = name;
            c.Sort = sort;
            return c;
        }

        private static GameItem Game(string name, string category, int sort)
        {
            GameItem g = new GameItem();
            g.Name = name;
            g.CategoryId = category;
            g.Sort = sort;
            return g;
        }
    }

    public static class Program
    {
        public static string LogPath = Path.Combine(Path.GetTempPath(), "EpohaShell-0.3.0.log");

        [STAThread]
        public static void Main()
        {
            try
            {
                File.AppendAllText(LogPath, "\r\n--- START " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + " ---\r\n");
                Application.SetUnhandledExceptionMode(UnhandledExceptionMode.CatchException);
                Application.ThreadException += delegate(object sender, System.Threading.ThreadExceptionEventArgs e) { Fatal("ThreadException", e.Exception); };
                AppDomain.CurrentDomain.UnhandledException += delegate(object sender, UnhandledExceptionEventArgs e) { Fatal("UnhandledException", e.ExceptionObject as Exception); };
                Application.EnableVisualStyles();
                Application.SetCompatibleTextRenderingDefault(false);
                Application.Run(new MainForm());
            }
            catch (Exception ex)
            {
                Fatal("Main", ex);
            }
        }

        private static void Fatal(string where, Exception ex)
        {
            try
            {
                string text = where + ": " + (ex == null ? "unknown error" : ex.ToString());
                File.AppendAllText(LogPath, text + "\r\n");
                MessageBox.Show("ЭПОХА не смогла запуститься.\r\n\r\n" + text + "\r\n\r\nЛог:\r\n" + LogPath,
                    "ЭПОХА — ошибка запуска", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            catch { }
        }
    }

    public class BufferedPanel : Panel
    {
        public BufferedPanel()
        {
            SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.UserPaint | ControlStyles.OptimizedDoubleBuffer, true);
            UpdateStyles();
        }
    }

    public class BufferedFlowLayoutPanel : FlowLayoutPanel
    {
        public BufferedFlowLayoutPanel()
        {
            SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.UserPaint | ControlStyles.OptimizedDoubleBuffer | ControlStyles.SupportsTransparentBackColor, true);
            UpdateStyles();
        }
    }

    public class BufferedTableLayoutPanel : TableLayoutPanel
    {
        public BufferedTableLayoutPanel()
        {
            SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.UserPaint | ControlStyles.OptimizedDoubleBuffer, true);
            UpdateStyles();
        }
    }

    public class WallpaperCanvas : BufferedPanel
    {
        private string wallpaperPath = "";
        private string wallpaperMode = "Fill";
        private int darkness = 120;
        private Color accent = Color.FromArgb(151, 82, 255);
        private Image wallpaper;

        public void Apply(string path, string mode, int dark, Color accentColor)
        {
            wallpaperPath = path == null ? "" : path;
            wallpaperMode = mode == null ? "Fill" : mode;
            darkness = Math.Max(0, Math.Min(220, dark));
            accent = accentColor;
            LoadWallpaper();
            Invalidate();
        }

        private void LoadWallpaper()
        {
            if (wallpaper != null) { wallpaper.Dispose(); wallpaper = null; }
            try
            {
                if (!String.IsNullOrEmpty(wallpaperPath) && File.Exists(wallpaperPath))
                {
                    using (FileStream fs = File.OpenRead(wallpaperPath))
                    using (Image tmp = Image.FromStream(fs))
                        wallpaper = new Bitmap(tmp);
                }
            }
            catch { wallpaper = null; }
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing && wallpaper != null) wallpaper.Dispose();
            base.Dispose(disposing);
        }

        protected override void OnPaintBackground(PaintEventArgs e)
        {
            Graphics g = e.Graphics;
            g.SmoothingMode = SmoothingMode.HighQuality;
            Rectangle r = ClientRectangle;
            if (r.Width <= 0 || r.Height <= 0) return;

            if (wallpaper != null)
            {
                DrawWallpaper(g, wallpaper, r, wallpaperMode);
                using (SolidBrush shade = new SolidBrush(Color.FromArgb(darkness, 4, 7, 15))) g.FillRectangle(shade, r);
            }
            else
            {
                using (LinearGradientBrush bg = new LinearGradientBrush(r, Color.FromArgb(7, 11, 22), Color.FromArgb(10, 13, 27), 35f)) g.FillRectangle(bg, r);
            }

            using (Pen p = new Pen(Color.FromArgb(18, accent), 1f))
            {
                int step = 170;
                for (int x = -r.Height; x < r.Width + r.Height; x += step)
                    g.DrawLine(p, x, r.Height, x + r.Height, 0);
            }

            using (SolidBrush star = new SolidBrush(Color.FromArgb(90, 205, 218, 255)))
            {
                int count = Math.Max(20, (r.Width * r.Height) / 45000);
                for (int i = 0; i < count; i++)
                {
                    int x = (i * 173 + 97) % Math.Max(1, r.Width);
                    int y = (i * 271 + 53) % Math.Max(1, r.Height);
                    int s = (i % 5 == 0) ? 2 : 1;
                    g.FillEllipse(star, x, y, s, s);
                }
            }
        }

        private void DrawWallpaper(Graphics g, Image img, Rectangle dst, string mode)
        {
            if (mode == "Stretch")
            {
                g.DrawImage(img, dst);
                return;
            }

            if (mode == "Center")
            {
                int x = dst.Left + (dst.Width - img.Width) / 2;
                int y = dst.Top + (dst.Height - img.Height) / 2;
                g.DrawImage(img, x, y, img.Width, img.Height);
                return;
            }

            double sx = (double)dst.Width / img.Width;
            double sy = (double)dst.Height / img.Height;
            double scale = Math.Max(sx, sy);
            int w = (int)(img.Width * scale);
            int h = (int)(img.Height * scale);
            int dx = dst.Left + (dst.Width - w) / 2;
            int dy = dst.Top + (dst.Height - h) / 2;
            g.DrawImage(img, new Rectangle(dx, dy, w, h));
        }
    }

    public enum HeaderIcon { Admin, Restart, Power }

    public class IconButton : Control
    {
        private bool hover;
        private HeaderIcon icon;
        private Color accent;
        private bool active;

        public IconButton(HeaderIcon iconKind, Color accentColor)
        {
            icon = iconKind;
            accent = accentColor;
            Size = new Size(46, 46);
            Cursor = Cursors.Hand;
            SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.UserPaint | ControlStyles.OptimizedDoubleBuffer, true);
        }

        public void SetAccent(Color c) { accent = c; Invalidate(); }
        public void SetActive(bool value) { active = value; Invalidate(); }

        protected override void OnMouseEnter(EventArgs e) { hover = true; Invalidate(); base.OnMouseEnter(e); }
        protected override void OnMouseLeave(EventArgs e) { hover = false; Invalidate(); base.OnMouseLeave(e); }

        protected override void OnPaint(PaintEventArgs e)
        {
            Graphics g = e.Graphics;
            g.SmoothingMode = SmoothingMode.AntiAlias;
            Rectangle r = new Rectangle(1, 1, Width - 3, Height - 3);
            Color fill = active ? Color.FromArgb(70, accent) : (hover ? Color.FromArgb(46, accent) : Color.FromArgb(27, 31, 43));
            using (SolidBrush b = new SolidBrush(fill)) g.FillRectangle(b, r);
            using (Pen border = new Pen(active || hover ? Color.FromArgb(210, accent) : Color.FromArgb(70, 83, 108), 1f)) g.DrawRectangle(border, r);
            using (Pen p = new Pen(active || hover ? accent : Color.FromArgb(215, 220, 235), 2.2f))
            {
                int cx = Width / 2;
                int cy = Height / 2;
                if (icon == HeaderIcon.Power)
                {
                    g.DrawArc(p, cx - 10, cy - 9, 20, 20, -55, 290);
                    g.DrawLine(p, cx, cy - 13, cx, cy - 2);
                }
                else if (icon == HeaderIcon.Restart)
                {
                    g.DrawArc(p, cx - 10, cy - 10, 21, 21, 35, 285);
                    Point[] pts = new Point[] { new Point(cx + 9, cy - 10), new Point(cx + 12, cy - 3), new Point(cx + 4, cy - 5) };
                    using (SolidBrush sb = new SolidBrush(p.Color)) g.FillPolygon(sb, pts);
                }
                else
                {
                    g.DrawEllipse(p, cx - 5, cy - 10, 10, 10);
                    g.DrawArc(p, cx - 11, cy + 1, 22, 16, 195, 150);
                }
            }
        }
    }

    public class NavButton : Control
    {
        private string textValue;
        private Color accent;
        private bool selected;
        private bool hover;

        public NavButton(string text, Color c)
        {
            textValue = text;
            accent = c;
            Height = 48;
            Cursor = Cursors.Hand;
            Font = new Font("Tahoma", 10, FontStyle.Bold);
            SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.UserPaint | ControlStyles.OptimizedDoubleBuffer, true);
        }

        public void Apply(Color c, bool isSelected)
        {
            accent = c;
            selected = isSelected;
            Invalidate();
        }

        protected override void OnMouseEnter(EventArgs e) { hover = true; Invalidate(); base.OnMouseEnter(e); }
        protected override void OnMouseLeave(EventArgs e) { hover = false; Invalidate(); base.OnMouseLeave(e); }

        protected override void OnPaint(PaintEventArgs e)
        {
            Graphics g = e.Graphics;
            Rectangle r = ClientRectangle;
            Color bg = selected ? Color.FromArgb(38, 43, 59) : (hover ? Color.FromArgb(28, 32, 44) : Color.FromArgb(17, 21, 30));
            using (SolidBrush b = new SolidBrush(bg)) g.FillRectangle(b, r);
            if (selected)
            {
                using (SolidBrush bar = new SolidBrush(accent)) g.FillRectangle(bar, 0, 0, 4, Height);
            }
            TextRenderer.DrawText(g, textValue, Font, new Rectangle(18, 0, Width - 24, Height), selected ? accent : Color.FromArgb(232, 235, 244), TextFormatFlags.Left | TextFormatFlags.VerticalCenter | TextFormatFlags.EndEllipsis);
        }
    }

    public class GameCard : Control
    {
        private GameItem game;
        private Color accent;
        private bool hover;
        private Image image;

        public GameCard(GameItem item, Color c)
        {
            game = item;
            accent = c;
            Cursor = Cursors.Hand;
            Font = new Font("Tahoma", 9, FontStyle.Bold);
            SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.UserPaint | ControlStyles.OptimizedDoubleBuffer, true);
            LoadImage();
        }

        public GameItem Game { get { return game; } }
        public void SetAccent(Color c) { accent = c; Invalidate(); }

        private void LoadImage()
        {
            try
            {
                if (!String.IsNullOrEmpty(game.ImagePath) && File.Exists(game.ImagePath))
                {
                    using (FileStream fs = File.OpenRead(game.ImagePath))
                    using (Image tmp = Image.FromStream(fs)) image = new Bitmap(tmp);
                }
                else if (!String.IsNullOrEmpty(game.ExePath) && File.Exists(game.ExePath))
                {
                    Icon ico = Icon.ExtractAssociatedIcon(game.ExePath);
                    if (ico != null) image = ico.ToBitmap();
                }
            }
            catch { image = null; }
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing && image != null) image.Dispose();
            base.Dispose(disposing);
        }

        protected override void OnMouseEnter(EventArgs e) { hover = true; Invalidate(); base.OnMouseEnter(e); }
        protected override void OnMouseLeave(EventArgs e) { hover = false; Invalidate(); base.OnMouseLeave(e); }

        protected override void OnPaint(PaintEventArgs e)
        {
            Graphics g = e.Graphics;
            g.SmoothingMode = SmoothingMode.HighQuality;
            Rectangle r = new Rectangle(1, 1, Width - 3, Height - 3);
            using (LinearGradientBrush bg = new LinearGradientBrush(r, hover ? Color.FromArgb(39, 45, 61) : Color.FromArgb(25, 30, 43), Color.FromArgb(17, 21, 31), 90f)) g.FillRectangle(bg, r);
            using (Pen border = new Pen(hover ? Color.FromArgb(220, accent) : Color.FromArgb(55, 67, 91), hover ? 1.7f : 1f)) g.DrawRectangle(border, r);

            Rectangle imageArea = new Rectangle(10, 10, Width - 20, Math.Max(48, Height - 57));
            if (image != null)
            {
                DrawImageContain(g, image, imageArea);
                using (SolidBrush shade = new SolidBrush(Color.FromArgb(45, 0, 0, 0))) g.FillRectangle(shade, imageArea);
            }
            else
            {
                using (SolidBrush faint = new SolidBrush(Color.FromArgb(20, accent))) g.FillRectangle(faint, imageArea);
                int cx = imageArea.Left + imageArea.Width / 2;
                int cy = imageArea.Top + imageArea.Height / 2;
                Point[] tri = new Point[] { new Point(cx - 7, cy - 10), new Point(cx - 7, cy + 10), new Point(cx + 11, cy) };
                using (SolidBrush play = new SolidBrush(accent)) g.FillPolygon(play, tri);
            }

            using (SolidBrush strip = new SolidBrush(Color.FromArgb(205, 12, 15, 24))) g.FillRectangle(strip, 1, Height - 39, Width - 3, 38);
            TextRenderer.DrawText(g, game.Name, Font, new Rectangle(8, Height - 38, Width - 16, 36), Color.White, TextFormatFlags.HorizontalCenter | TextFormatFlags.VerticalCenter | TextFormatFlags.EndEllipsis | TextFormatFlags.SingleLine);
        }

        private void DrawImageContain(Graphics g, Image img, Rectangle dst)
        {
            double s = Math.Min((double)dst.Width / img.Width, (double)dst.Height / img.Height);
            int w = Math.Max(1, (int)(img.Width * s));
            int h = Math.Max(1, (int)(img.Height * s));
            int x = dst.Left + (dst.Width - w) / 2;
            int y = dst.Top + (dst.Height - h) / 2;
            g.DrawImage(img, new Rectangle(x, y, w, h));
        }
    }

    public class MainForm : Form
    {
        private AppConfig config;
        private Color Accent { get { return Color.FromArgb(config.AccentArgb); } }

        private BufferedTableLayoutPanel root;
        private BufferedPanel sidebar;
        private BufferedPanel brand;
        private BufferedFlowLayoutPanel nav;
        private BufferedPanel right;
        private BufferedPanel header;
        private WallpaperCanvas canvas;
        private BufferedPanel footer;
        private Label clock;
        private Label pcLabel;
        private Label footerLabel;
        private IconButton adminButton;
        private IconButton restartButton;
        private IconButton powerButton;
        private ToolTip tips;
        private Timer clockTimer;
        private Control currentView;
        private string currentCategory = "all";
        private bool adminLoggedIn;
        private int headerHeight = 92;
        private int sidebarWidth = 286;

        private BufferedPanel adminContent;
        private string adminSection = "general";

        public MainForm()
        {
            config = ConfigStore.Load();
            Text = "ЭПОХА — КОМПЬЮТЕРНЫЙ КЛУБ";
            FormBorderStyle = FormBorderStyle.None;
            WindowState = FormWindowState.Maximized;
            StartPosition = FormStartPosition.CenterScreen;
            MinimumSize = new Size(900, 650);
            BackColor = Color.FromArgb(6, 9, 16);
            KeyPreview = true;
            SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.UserPaint | ControlStyles.OptimizedDoubleBuffer, true);

            BuildUi();
            RebuildNavigation();
            ShowGames();
            ApplyVisuals();

            clockTimer = new Timer();
            clockTimer.Interval = 1000;
            clockTimer.Tick += delegate { UpdateClock(); };
            clockTimer.Start();
            UpdateClock();

            Resize += delegate { AdaptiveLayout(); };
            Shown += delegate { AdaptiveLayout(); };
            KeyDown += MainForm_KeyDown;
        }

        private Font F(float size, FontStyle style) { return new Font("Tahoma", size, style); }

        private void BuildUi()
        {
            root = new BufferedTableLayoutPanel();
            root.Dock = DockStyle.Fill;
            root.Margin = new Padding(0);
            root.Padding = new Padding(0);
            root.RowCount = 1;
            root.ColumnCount = 2;
            root.RowStyles.Add(new RowStyle(SizeType.Percent, 100f));
            root.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, sidebarWidth));
            root.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100f));
            Controls.Add(root);

            sidebar = new BufferedPanel();
            sidebar.Dock = DockStyle.Fill;
            sidebar.Margin = new Padding(0);
            sidebar.BackColor = Color.FromArgb(14, 18, 27);
            root.Controls.Add(sidebar, 0, 0);

            brand = new BufferedPanel();
            brand.Dock = DockStyle.Top;
            brand.Height = headerHeight;
            brand.BackColor = Color.FromArgb(20, 24, 35);
            brand.Paint += BrandPaint;
            sidebar.Controls.Add(brand);

            nav = new BufferedFlowLayoutPanel();
            nav.Dock = DockStyle.Fill;
            nav.FlowDirection = FlowDirection.TopDown;
            nav.WrapContents = false;
            nav.AutoScroll = true;
            nav.Padding = new Padding(12, 18, 12, 12);
            nav.BackColor = Color.FromArgb(14, 18, 27);
            sidebar.Controls.Add(nav);
            nav.BringToFront();

            right = new BufferedPanel();
            right.Dock = DockStyle.Fill;
            right.Margin = new Padding(0);
            right.BackColor = Color.FromArgb(7, 10, 18);
            root.Controls.Add(right, 1, 0);

            header = new BufferedPanel();
            header.Dock = DockStyle.Top;
            header.Height = headerHeight;
            header.BackColor = Color.FromArgb(20, 24, 35);
            header.Paint += HeaderPaint;
            right.Controls.Add(header);

            clock = new Label();
            clock.AutoSize = false;
            clock.TextAlign = ContentAlignment.MiddleCenter;
            clock.ForeColor = Color.White;
            clock.Font = F(25, FontStyle.Bold);
            header.Controls.Add(clock);

            pcLabel = new Label();
            pcLabel.AutoSize = false;
            pcLabel.TextAlign = ContentAlignment.TopCenter;
            pcLabel.ForeColor = Color.FromArgb(148, 158, 181);
            pcLabel.Font = F(8, FontStyle.Regular);
            header.Controls.Add(pcLabel);

            adminButton = new IconButton(HeaderIcon.Admin, Accent);
            adminButton.Click += AdminHeaderClick;
            header.Controls.Add(adminButton);

            restartButton = new IconButton(HeaderIcon.Restart, Accent);
            restartButton.Click += RestartClick;
            header.Controls.Add(restartButton);

            powerButton = new IconButton(HeaderIcon.Power, Accent);
            powerButton.Click += PowerClick;
            header.Controls.Add(powerButton);

            tips = new ToolTip();
            tips.SetToolTip(adminButton, "Администратор");
            tips.SetToolTip(restartButton, "Перезагрузить компьютер");
            tips.SetToolTip(powerButton, "Выключить компьютер");

            footer = new BufferedPanel();
            footer.Dock = DockStyle.Bottom;
            footer.Height = 30;
            footer.BackColor = Color.FromArgb(17, 21, 31);
            right.Controls.Add(footer);

            footerLabel = new Label();
            footerLabel.Dock = DockStyle.Fill;
            footerLabel.Padding = new Padding(15, 0, 0, 0);
            footerLabel.TextAlign = ContentAlignment.MiddleLeft;
            footerLabel.ForeColor = Color.FromArgb(125, 136, 160);
            footerLabel.Font = F(7.5f, FontStyle.Regular);
            footer.Controls.Add(footerLabel);

            canvas = new WallpaperCanvas();
            canvas.Dock = DockStyle.Fill;
            canvas.Margin = new Padding(0);
            right.Controls.Add(canvas);
            canvas.BringToFront();
        }

        private void BrandPaint(object sender, PaintEventArgs e)
        {
            Graphics g = e.Graphics;
            g.SmoothingMode = SmoothingMode.AntiAlias;
            int box = Math.Min(54, brand.Height - 28);
            int x = 14;
            int y = (brand.Height - box) / 2;
            using (SolidBrush b = new SolidBrush(Accent)) g.FillRectangle(b, x, y, box, box);
            using (Font logo = F(23, FontStyle.Bold)) TextRenderer.DrawText(g, "Э", logo, new Rectangle(x, y, box, box), Color.FromArgb(16, 18, 24), TextFormatFlags.HorizontalCenter | TextFormatFlags.VerticalCenter);
            using (Font title = F(17, FontStyle.Bold)) TextRenderer.DrawText(g, "ЭПОХА", title, new Point(x + box + 14, y + 1), Accent);
            using (Font sub = F(7.2f, FontStyle.Bold)) TextRenderer.DrawText(g, "КОМПЬЮТЕРНЫЙ КЛУБ", sub, new Point(x + box + 15, y + 28), Color.White);
            using (Font years = F(7.2f, FontStyle.Regular)) TextRenderer.DrawText(g, "2000—2015", years, new Point(x + box + 15, y + 47), Color.FromArgb(140, 150, 174));
            using (Pen line = new Pen(Color.FromArgb(55, Accent), 1f)) g.DrawLine(line, 0, brand.Height - 1, brand.Width, brand.Height - 1);
        }

        private void HeaderPaint(object sender, PaintEventArgs e)
        {
            using (Pen line = new Pen(Color.FromArgb(55, Accent), 1f)) e.Graphics.DrawLine(line, 0, header.Height - 1, header.Width, header.Height - 1);
        }

        private void RebuildNavigation()
        {
            nav.SuspendLayout();
            nav.Controls.Clear();
            List<CategoryItem> cats = new List<CategoryItem>(config.Categories);
            cats.Sort(delegate(CategoryItem a, CategoryItem b) { return a.Sort.CompareTo(b.Sort); });
            foreach (CategoryItem c in cats)
            {
                NavButton b = new NavButton(c.Name, Accent);
                b.Tag = c.Id;
                b.Apply(Accent, currentCategory == c.Id);
                b.Margin = new Padding(0, 0, 0, 2);
                b.Click += CategoryClick;
                nav.Controls.Add(b);
            }
            nav.ResumeLayout();
            AdaptiveLayout();
        }

        private void CategoryClick(object sender, EventArgs e)
        {
            Control c = sender as Control;
            if (c == null || c.Tag == null) return;
            currentCategory = c.Tag.ToString();
            RebuildNavigation();
            ShowGames();
        }

        private void ShowGames()
        {
            BufferedFlowLayoutPanel grid = new BufferedFlowLayoutPanel();
            grid.Dock = DockStyle.Fill;
            grid.AutoScroll = true;
            grid.WrapContents = true;
            grid.Padding = new Padding(22, 20, 22, 22);
            grid.BackColor = Color.Transparent;

            List<GameItem> list = new List<GameItem>();
            foreach (GameItem g in config.Games)
                if (currentCategory == "all" || g.CategoryId == currentCategory) list.Add(g);
            list.Sort(delegate(GameItem a, GameItem b) { return a.Sort.CompareTo(b.Sort); });

            foreach (GameItem g in list)
            {
                GameCard card = new GameCard(g, Accent);
                card.Margin = new Padding(8);
                card.Click += GameClick;
                grid.Controls.Add(card);
            }

            if (list.Count == 0)
            {
                Label empty = new Label();
                empty.Text = "В этом разделе пока нет ярлыков";
                empty.AutoSize = true;
                empty.ForeColor = Color.FromArgb(150, 160, 182);
                empty.Font = F(13, FontStyle.Regular);
                empty.Margin = new Padding(25);
                grid.Controls.Add(empty);
            }

            SwapView(grid);
            AdaptiveGameCards();
        }

        private void SwapView(Control next)
        {
            canvas.SuspendLayout();
            if (currentView != null)
            {
                canvas.Controls.Remove(currentView);
                currentView.Dispose();
            }
            currentView = next;
            currentView.Dock = DockStyle.Fill;
            canvas.Controls.Add(currentView);
            canvas.ResumeLayout(true);
        }

        private void GameClick(object sender, EventArgs e)
        {
            GameCard card = sender as GameCard;
            if (card == null) return;
            GameItem g = card.Game;
            if (String.IsNullOrEmpty(g.ExePath) || !File.Exists(g.ExePath))
            {
                MessageBox.Show("Для «" + g.Name + "» пока не указан рабочий EXE.\r\nДобавьте путь через админку.", "ЭПОХА", MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }
            try
            {
                ProcessStartInfo psi = new ProcessStartInfo(g.ExePath, g.Arguments == null ? "" : g.Arguments);
                psi.WorkingDirectory = !String.IsNullOrEmpty(g.WorkingDirectory) ? g.WorkingDirectory : Path.GetDirectoryName(g.ExePath);
                Process.Start(psi);
            }
            catch (Exception ex)
            {
                MessageBox.Show("Не удалось запустить игру:\r\n" + ex.Message, "ЭПОХА", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void AdminHeaderClick(object sender, EventArgs e)
        {
            if (!adminLoggedIn)
            {
                string pass = PromptPassword();
                if (pass == null) return;
                if (pass != config.AdminPassword)
                {
                    MessageBox.Show("Неверный пароль", "ЭПОХА", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return;
                }
                adminLoggedIn = true;
                adminButton.SetActive(true);
            }
            ShowAdmin();
        }

        private string PromptPassword()
        {
            Form f = new Form();
            f.Text = "ЭПОХА — вход администратора";
            f.StartPosition = FormStartPosition.CenterScreen;
            f.FormBorderStyle = FormBorderStyle.FixedDialog;
            f.Width = 420;
            f.Height = 170;
            f.MaximizeBox = false;
            f.MinimizeBox = false;
            f.BackColor = Color.FromArgb(20, 24, 35);
            f.ForeColor = Color.White;
            f.Font = F(9, FontStyle.Regular);

            Label l = new Label(); l.Text = "Пароль администратора"; l.SetBounds(18, 18, 360, 22); f.Controls.Add(l);
            TextBox t = new TextBox(); t.UseSystemPasswordChar = true; t.SetBounds(18, 45, 365, 25); f.Controls.Add(t);
            Button ok = DialogButton("ВОЙТИ", 223, 86, 76); ok.DialogResult = DialogResult.OK; f.Controls.Add(ok);
            Button cancel = DialogButton("ОТМЕНА", 307, 86, 76); cancel.DialogResult = DialogResult.Cancel; f.Controls.Add(cancel);
            f.AcceptButton = ok; f.CancelButton = cancel;
            return f.ShowDialog() == DialogResult.OK ? t.Text : null;
        }

        private Button DialogButton(string text, int x, int y, int w)
        {
            Button b = new Button();
            b.Text = text;
            b.SetBounds(x, y, w, 32);
            b.FlatStyle = FlatStyle.Flat;
            b.FlatAppearance.BorderColor = Accent;
            b.BackColor = Color.FromArgb(30, 35, 49);
            b.ForeColor = Color.White;
            b.Font = F(8, FontStyle.Bold);
            return b;
        }

        private void ShowAdmin()
        {
            BufferedPanel page = new BufferedPanel();
            page.BackColor = Color.Transparent;

            BufferedPanel left = new BufferedPanel();
            left.Dock = DockStyle.Left;
            left.Width = 210;
            left.BackColor = Color.FromArgb(205, 12, 16, 26);
            page.Controls.Add(left);

            Label title = new Label();
            title.Text = "НАСТРОЙКИ";
            title.Dock = DockStyle.Top;
            title.Height = 58;
            title.Padding = new Padding(18, 0, 0, 0);
            title.TextAlign = ContentAlignment.MiddleLeft;
            title.ForeColor = Accent;
            title.Font = F(12, FontStyle.Bold);
            left.Controls.Add(title);

            BufferedFlowLayoutPanel subnav = new BufferedFlowLayoutPanel();
            subnav.Dock = DockStyle.Fill;
            subnav.FlowDirection = FlowDirection.TopDown;
            subnav.WrapContents = false;
            subnav.Padding = new Padding(10, 10, 10, 10);
            subnav.BackColor = Color.Transparent;
            left.Controls.Add(subnav);
            subnav.BringToFront();

            AddAdminNav(subnav, "ОБЩИЕ", "general");
            AddAdminNav(subnav, "ВНЕШНИЙ ВИД", "appearance");
            AddAdminNav(subnav, "ВКЛАДКИ", "categories");
            AddAdminNav(subnav, "ИГРЫ И ЯРЛЫКИ", "games");
            AddAdminNav(subnav, "СИСТЕМА", "system");

            Button logout = FlatActionButton("ВЫЙТИ ИЗ АДМИНКИ");
            logout.Dock = DockStyle.Bottom;
            logout.Height = 44;
            logout.Click += delegate
            {
                adminLoggedIn = false;
                adminButton.SetActive(false);
                ShowGames();
            };
            left.Controls.Add(logout);

            adminContent = new BufferedPanel();
            adminContent.Dock = DockStyle.Fill;
            adminContent.BackColor = Color.FromArgb(225, 9, 13, 23);
            page.Controls.Add(adminContent);
            adminContent.BringToFront();

            SwapView(page);
            ShowAdminSection(adminSection);
        }

        private void AddAdminNav(FlowLayoutPanel p, string text, string key)
        {
            NavButton b = new NavButton(text, Accent);
            b.Tag = key;
            b.Width = 180;
            b.Apply(Accent, adminSection == key);
            b.Margin = new Padding(0, 0, 0, 2);
            b.Click += delegate(object sender, EventArgs e)
            {
                Control c = sender as Control;
                if (c == null || c.Tag == null) return;
                adminSection = c.Tag.ToString();
                ShowAdmin();
            };
            p.Controls.Add(b);
        }

        private void ShowAdminSection(string key)
        {
            if (adminContent == null) return;
            adminContent.SuspendLayout();
            adminContent.Controls.Clear();
            if (key == "appearance") BuildAppearanceSettings();
            else if (key == "categories") BuildCategorySettings();
            else if (key == "games") BuildGameSettings();
            else if (key == "system") BuildSystemSettings();
            else BuildGeneralSettings();
            adminContent.ResumeLayout(true);
        }

        private Label SectionTitle(string text)
        {
            Label l = new Label();
            l.Text = text;
            l.SetBounds(28, 24, 620, 38);
            l.ForeColor = Color.White;
            l.Font = F(18, FontStyle.Bold);
            return l;
        }

        private Label FormLabel(string text, int x, int y, int width)
        {
            Label l = new Label(); l.Text = text; l.SetBounds(x, y, width, 22); l.ForeColor = Color.FromArgb(165, 176, 198); l.Font = F(8.5f, FontStyle.Regular); return l;
        }

        private TextBox DarkText(string value, int x, int y, int width)
        {
            TextBox t = new TextBox(); t.Text = value == null ? "" : value; t.SetBounds(x, y, width, 25); t.BackColor = Color.FromArgb(25, 30, 43); t.ForeColor = Color.White; t.BorderStyle = BorderStyle.FixedSingle; t.Font = F(9, FontStyle.Regular); return t;
        }

        private Button FlatActionButton(string text)
        {
            Button b = new Button();
            b.Text = text;
            b.FlatStyle = FlatStyle.Flat;
            b.FlatAppearance.BorderColor = Color.FromArgb(110, Accent);
            b.BackColor = Color.FromArgb(28, 33, 47);
            b.ForeColor = Color.White;
            b.Font = F(8, FontStyle.Bold);
            return b;
        }

        private void BuildGeneralSettings()
        {
            adminContent.Controls.Add(SectionTitle("ОБЩИЕ НАСТРОЙКИ"));
            adminContent.Controls.Add(FormLabel("Подпись компьютера", 30, 90, 260));
            TextBox pc = DarkText(config.PcLabel, 30, 116, 300); adminContent.Controls.Add(pc);
            adminContent.Controls.Add(FormLabel("Новый пароль администратора", 30, 166, 300));
            TextBox pass = DarkText("", 30, 192, 300); pass.UseSystemPasswordChar = true; adminContent.Controls.Add(pass);
            Label hint = FormLabel("Оставьте пароль пустым, если менять его не нужно.", 30, 224, 430); adminContent.Controls.Add(hint);
            Button save = FlatActionButton("СОХРАНИТЬ"); save.SetBounds(30, 270, 160, 38); adminContent.Controls.Add(save);
            save.Click += delegate
            {
                config.PcLabel = String.IsNullOrEmpty(pc.Text.Trim()) ? "ПК" : pc.Text.Trim();
                if (!String.IsNullOrEmpty(pass.Text)) config.AdminPassword = pass.Text;
                SaveAndRefresh();
                MessageBox.Show("Настройки сохранены.", "ЭПОХА");
            };
        }

        private void BuildAppearanceSettings()
        {
            adminContent.Controls.Add(SectionTitle("ВНЕШНИЙ ВИД"));

            adminContent.Controls.Add(FormLabel("Цвет интерфейса", 30, 88, 240));
            BufferedPanel swatch = new BufferedPanel(); swatch.SetBounds(30, 114, 42, 28); swatch.BackColor = Accent; adminContent.Controls.Add(swatch);
            Button color = FlatActionButton("ВЫБРАТЬ ЦВЕТ"); color.SetBounds(84, 110, 160, 36); adminContent.Controls.Add(color);
            color.Click += delegate
            {
                ColorDialog cd = new ColorDialog(); cd.Color = Accent; cd.FullOpen = true;
                if (cd.ShowDialog(this) == DialogResult.OK)
                {
                    config.AccentArgb = cd.Color.ToArgb();
                    ConfigStore.Save(config);
                    ApplyVisuals();
                    ShowAdmin();
                }
            };

            adminContent.Controls.Add(FormLabel("Обои рабочей области", 30, 168, 280));
            Label wallpaper = FormLabel(String.IsNullOrEmpty(config.WallpaperPath) ? "Не выбраны" : Path.GetFileName(config.WallpaperPath), 30, 194, 520); adminContent.Controls.Add(wallpaper);
            Button choose = FlatActionButton("ВЫБРАТЬ ОБОИ"); choose.SetBounds(30, 226, 160, 36); adminContent.Controls.Add(choose);
            Button clear = FlatActionButton("УБРАТЬ ОБОИ"); clear.SetBounds(200, 226, 150, 36); adminContent.Controls.Add(clear);
            choose.Click += delegate { SelectWallpaper(); };
            clear.Click += delegate
            {
                config.WallpaperPath = "";
                ConfigStore.Save(config);
                ApplyVisuals();
                ShowAdmin();
            };

            adminContent.Controls.Add(FormLabel("Режим обоев", 30, 286, 240));
            ComboBox mode = DarkCombo(30, 312, 220); mode.Items.Add("Fill"); mode.Items.Add("Stretch"); mode.Items.Add("Center"); mode.SelectedItem = config.WallpaperMode; if (mode.SelectedIndex < 0) mode.SelectedIndex = 0; adminContent.Controls.Add(mode);

            adminContent.Controls.Add(FormLabel("Затемнение обоев", 30, 358, 240));
            TrackBar dark = new TrackBar(); dark.SetBounds(25, 382, 320, 45); dark.Minimum = 0; dark.Maximum = 220; dark.TickFrequency = 20; dark.Value = Math.Max(0, Math.Min(220, config.WallpaperDarkness)); dark.BackColor = Color.FromArgb(225, 9, 13, 23); adminContent.Controls.Add(dark);

            adminContent.Controls.Add(FormLabel("Размер карточек игр", 390, 88, 260));
            ComboBox cards = DarkCombo(390, 114, 220); cards.Items.Add("Auto"); cards.Items.Add("Compact"); cards.Items.Add("Medium"); cards.Items.Add("Large"); cards.SelectedItem = config.CardSize; if (cards.SelectedIndex < 0) cards.SelectedIndex = 0; adminContent.Controls.Add(cards);

            Button save = FlatActionButton("ПРИМЕНИТЬ"); save.SetBounds(390, 172, 160, 38); adminContent.Controls.Add(save);
            save.Click += delegate
            {
                config.WallpaperMode = mode.SelectedItem == null ? "Fill" : mode.SelectedItem.ToString();
                config.WallpaperDarkness = dark.Value;
                config.CardSize = cards.SelectedItem == null ? "Auto" : cards.SelectedItem.ToString();
                SaveAndRefresh();
                ShowAdmin();
            };
        }

        private ComboBox DarkCombo(int x, int y, int w)
        {
            ComboBox c = new ComboBox(); c.SetBounds(x, y, w, 25); c.DropDownStyle = ComboBoxStyle.DropDownList; c.BackColor = Color.FromArgb(25, 30, 43); c.ForeColor = Color.White; c.Font = F(9, FontStyle.Regular); return c;
        }

        private void SelectWallpaper()
        {
            OpenFileDialog d = new OpenFileDialog();
            d.Filter = "Изображения|*.jpg;*.jpeg;*.png;*.bmp|Все файлы|*.*";
            if (d.ShowDialog(this) != DialogResult.OK) return;
            try
            {
                if (!Directory.Exists(ConfigStore.BaseDir)) Directory.CreateDirectory(ConfigStore.BaseDir);
                string ext = Path.GetExtension(d.FileName);
                string target = Path.Combine(ConfigStore.BaseDir, "wallpaper" + ext);
                File.Copy(d.FileName, target, true);
                config.WallpaperPath = target;
                ConfigStore.Save(config);
                ApplyVisuals();
                ShowAdmin();
            }
            catch (Exception ex)
            {
                MessageBox.Show("Не удалось установить обои:\r\n" + ex.Message, "ЭПОХА", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void BuildCategorySettings()
        {
            adminContent.Controls.Add(SectionTitle("ВКЛАДКИ"));
            ListBox list = DarkList(30, 82, 360, 330); adminContent.Controls.Add(list);
            ReloadCategoryList(list);
            Button add = FlatActionButton("ДОБАВИТЬ"); add.SetBounds(420, 82, 150, 36); adminContent.Controls.Add(add);
            Button rename = FlatActionButton("ПЕРЕИМЕНОВАТЬ"); rename.SetBounds(420, 128, 150, 36); adminContent.Controls.Add(rename);
            Button up = FlatActionButton("ВЫШЕ"); up.SetBounds(420, 174, 150, 36); adminContent.Controls.Add(up);
            Button down = FlatActionButton("НИЖЕ"); down.SetBounds(420, 220, 150, 36); adminContent.Controls.Add(down);
            Button del = FlatActionButton("УДАЛИТЬ"); del.SetBounds(420, 266, 150, 36); adminContent.Controls.Add(del);

            add.Click += delegate
            {
                string name = PromptText("Название новой вкладки", "НОВАЯ ВКЛАДКА");
                if (String.IsNullOrEmpty(name)) return;
                CategoryItem c = new CategoryItem(); c.Name = name.Trim(); c.Sort = config.Categories.Count * 10; config.Categories.Add(c); SaveAndRefresh(); ShowAdmin();
            };
            rename.Click += delegate
            {
                CategoryItem c = list.SelectedItem as CategoryItem; if (c == null || c.Id == "all") return;
                string name = PromptText("Новое название", c.Name); if (String.IsNullOrEmpty(name)) return;
                c.Name = name.Trim(); SaveAndRefresh(); ShowAdmin();
            };
            up.Click += delegate { MoveCategory(list.SelectedItem as CategoryItem, -1); ShowAdmin(); };
            down.Click += delegate { MoveCategory(list.SelectedItem as CategoryItem, 1); ShowAdmin(); };
            del.Click += delegate
            {
                CategoryItem c = list.SelectedItem as CategoryItem; if (c == null || c.Id == "all") return;
                if (MessageBox.Show("Удалить вкладку и ярлыки внутри неё?", "ЭПОХА", MessageBoxButtons.YesNo, MessageBoxIcon.Question) != DialogResult.Yes) return;
                config.Games.RemoveAll(delegate(GameItem g) { return g.CategoryId == c.Id; }); config.Categories.Remove(c); SaveAndRefresh(); ShowAdmin();
            };
        }

        private ListBox DarkList(int x, int y, int w, int h)
        {
            ListBox l = new ListBox(); l.SetBounds(x, y, w, h); l.BackColor = Color.FromArgb(20, 25, 37); l.ForeColor = Color.White; l.BorderStyle = BorderStyle.FixedSingle; l.Font = F(9, FontStyle.Regular); return l;
        }

        private void ReloadCategoryList(ListBox list)
        {
            list.Items.Clear();
            List<CategoryItem> cats = new List<CategoryItem>(config.Categories); cats.Sort(delegate(CategoryItem a, CategoryItem b) { return a.Sort.CompareTo(b.Sort); });
            foreach (CategoryItem c in cats) list.Items.Add(c);
        }

        private void MoveCategory(CategoryItem c, int dir)
        {
            if (c == null || c.Id == "all") return;
            List<CategoryItem> cats = new List<CategoryItem>(config.Categories); cats.Sort(delegate(CategoryItem a, CategoryItem b) { return a.Sort.CompareTo(b.Sort); });
            int i = cats.IndexOf(c); int j = i + dir; if (j < 1 || j >= cats.Count) return;
            int tmp = cats[i].Sort; cats[i].Sort = cats[j].Sort; cats[j].Sort = tmp; SaveAndRefresh();
        }

        private void BuildGameSettings()
        {
            adminContent.Controls.Add(SectionTitle("ИГРЫ И ЯРЛЫКИ"));
            adminContent.Controls.Add(FormLabel("Вкладка", 30, 80, 200));
            ComboBox cat = DarkCombo(30, 106, 300); adminContent.Controls.Add(cat);
            List<CategoryItem> cats = new List<CategoryItem>(); foreach (CategoryItem c in config.Categories) if (c.Id != "all") cats.Add(c); cats.Sort(delegate(CategoryItem a, CategoryItem b) { return a.Sort.CompareTo(b.Sort); }); foreach (CategoryItem c in cats) cat.Items.Add(c); if (cat.Items.Count > 0) cat.SelectedIndex = 0;
            ListBox games = DarkList(30, 150, 420, 300); adminContent.Controls.Add(games);
            EventHandler reload = delegate { ReloadGamesForCategory(games, cat.SelectedItem as CategoryItem); };
            cat.SelectedIndexChanged += reload; reload(this, EventArgs.Empty);

            Button add = FlatActionButton("ДОБАВИТЬ"); add.SetBounds(480, 150, 155, 36); adminContent.Controls.Add(add);
            Button edit = FlatActionButton("ИЗМЕНИТЬ"); edit.SetBounds(480, 196, 155, 36); adminContent.Controls.Add(edit);
            Button up = FlatActionButton("ВЫШЕ"); up.SetBounds(480, 242, 155, 36); adminContent.Controls.Add(up);
            Button down = FlatActionButton("НИЖЕ"); down.SetBounds(480, 288, 155, 36); adminContent.Controls.Add(down);
            Button del = FlatActionButton("УДАЛИТЬ"); del.SetBounds(480, 334, 155, 36); adminContent.Controls.Add(del);

            add.Click += delegate
            {
                CategoryItem c = cat.SelectedItem as CategoryItem; if (c == null) return;
                GameItem g = new GameItem(); g.CategoryId = c.Id; g.Sort = config.Games.Count * 10;
                using (GameEditDialog d = new GameEditDialog(g, Accent, F(9, FontStyle.Regular)))
                    if (d.ShowDialog(this) == DialogResult.OK) { config.Games.Add(g); SaveAndRefresh(); ShowAdmin(); }
            };
            edit.Click += delegate
            {
                GameItem g = games.SelectedItem as GameItem; if (g == null) return;
                using (GameEditDialog d = new GameEditDialog(g, Accent, F(9, FontStyle.Regular)))
                    if (d.ShowDialog(this) == DialogResult.OK) { SaveAndRefresh(); ShowAdmin(); }
            };
            up.Click += delegate { MoveGame(games.SelectedItem as GameItem, -1); ShowAdmin(); };
            down.Click += delegate { MoveGame(games.SelectedItem as GameItem, 1); ShowAdmin(); };
            del.Click += delegate
            {
                GameItem g = games.SelectedItem as GameItem; if (g == null) return;
                if (MessageBox.Show("Удалить ярлык «" + g.Name + "»?", "ЭПОХА", MessageBoxButtons.YesNo, MessageBoxIcon.Question) != DialogResult.Yes) return;
                config.Games.Remove(g); SaveAndRefresh(); ShowAdmin();
            };
        }

        private void ReloadGamesForCategory(ListBox list, CategoryItem c)
        {
            list.Items.Clear(); if (c == null) return;
            List<GameItem> items = new List<GameItem>(); foreach (GameItem g in config.Games) if (g.CategoryId == c.Id) items.Add(g); items.Sort(delegate(GameItem a, GameItem b) { return a.Sort.CompareTo(b.Sort); }); foreach (GameItem g in items) list.Items.Add(g);
        }

        private void MoveGame(GameItem g, int dir)
        {
            if (g == null) return;
            List<GameItem> items = new List<GameItem>(); foreach (GameItem x in config.Games) if (x.CategoryId == g.CategoryId) items.Add(x); items.Sort(delegate(GameItem a, GameItem b) { return a.Sort.CompareTo(b.Sort); });
            int i = items.IndexOf(g); int j = i + dir; if (j < 0 || j >= items.Count) return;
            int tmp = items[i].Sort; items[i].Sort = items[j].Sort; items[j].Sort = tmp; SaveAndRefresh();
        }

        private void BuildSystemSettings()
        {
            adminContent.Controls.Add(SectionTitle("СИСТЕМА"));
            adminContent.Controls.Add(FormLabel("Компьютер: " + Environment.MachineName, 30, 92, 600));
            adminContent.Controls.Add(FormLabel("Windows: " + Environment.OSVersion.ToString(), 30, 122, 700));
            adminContent.Controls.Add(FormLabel("CLR: " + Environment.Version.ToString(), 30, 152, 500));
            adminContent.Controls.Add(FormLabel("Конфигурация: " + ConfigStore.ConfigPath, 30, 182, 760));
            Button folder = FlatActionButton("ОТКРЫТЬ ПАПКУ КОНФИГУРАЦИИ"); folder.SetBounds(30, 228, 280, 38); adminContent.Controls.Add(folder);
            folder.Click += delegate { try { Process.Start("explorer.exe", ConfigStore.BaseDir); } catch (Exception ex) { MessageBox.Show(ex.Message); } };
            Label note = FormLabel("Клубные блокировки Windows пока не активируются в этой тестовой ветке — сначала доводим интерфейс и настройки.", 30, 294, 760); adminContent.Controls.Add(note);
        }

        private string PromptText(string caption, string value)
        {
            Form f = new Form(); f.Text = caption; f.StartPosition = FormStartPosition.CenterScreen; f.FormBorderStyle = FormBorderStyle.FixedDialog; f.Width = 420; f.Height = 160; f.BackColor = Color.FromArgb(20, 24, 35); f.ForeColor = Color.White; f.Font = F(9, FontStyle.Regular); f.MaximizeBox = false; f.MinimizeBox = false;
            TextBox t = DarkText(value, 18, 28, 365); f.Controls.Add(t);
            Button ok = DialogButton("OK", 223, 76, 76); ok.DialogResult = DialogResult.OK; f.Controls.Add(ok);
            Button cancel = DialogButton("ОТМЕНА", 307, 76, 76); cancel.DialogResult = DialogResult.Cancel; f.Controls.Add(cancel); f.AcceptButton = ok; f.CancelButton = cancel;
            return f.ShowDialog() == DialogResult.OK ? t.Text : null;
        }

        private void SaveAndRefresh()
        {
            ConfigStore.Save(config);
            RebuildNavigation();
            ApplyVisuals();
            UpdateClock();
        }

        private void ApplyVisuals()
        {
            canvas.Apply(config.WallpaperPath, config.WallpaperMode, config.WallpaperDarkness, Accent);
            adminButton.SetAccent(Accent); restartButton.SetAccent(Accent); powerButton.SetAccent(Accent);
            brand.Invalidate(); header.Invalidate();
            foreach (Control c in nav.Controls)
            {
                NavButton n = c as NavButton; if (n != null) n.Apply(Accent, c.Tag != null && c.Tag.ToString() == currentCategory);
            }
            if (currentView is BufferedFlowLayoutPanel)
            {
                foreach (Control c in currentView.Controls)
                {
                    GameCard g = c as GameCard; if (g != null) g.SetAccent(Accent);
                }
            }
            AdaptiveLayout();
        }

        private void UpdateClock()
        {
            clock.Text = DateTime.Now.ToString("HH:mm:ss");
            pcLabel.Text = config.PcLabel;
            footerLabel.Text = "ЭПОХА 0.3.0   •   " + config.PcLabel + "   •   " + Environment.MachineName + "   •   CLUB SHELL";
        }

        private void AdaptiveLayout()
        {
            int w = ClientSize.Width;
            int h = ClientSize.Height;
            if (w < 500) return;
            sidebarWidth = Math.Max(230, Math.Min(320, (int)(w * 0.15)));
            headerHeight = h < 800 ? 82 : 92;
            root.ColumnStyles[0].Width = sidebarWidth;
            brand.Height = headerHeight;
            header.Height = headerHeight;
            foreach (Control c in nav.Controls) c.Width = Math.Max(160, sidebarWidth - 24);

            int hw = header.ClientSize.Width;
            int clockWidth = Math.Min(330, Math.Max(220, hw / 3));
            clock.SetBounds((hw - clockWidth) / 2, headerHeight < 90 ? 8 : 10, clockWidth, 40);
            pcLabel.SetBounds((hw - 220) / 2, clock.Bottom - 2, 220, 22);

            int btn = headerHeight < 90 ? 40 : 46;
            adminButton.Size = new Size(btn, btn); restartButton.Size = new Size(btn, btn); powerButton.Size = new Size(btn, btn);
            int gap = 8;
            int rightEdge = hw - 16;
            powerButton.Location = new Point(rightEdge - btn, (headerHeight - btn) / 2); rightEdge = powerButton.Left - gap;
            restartButton.Location = new Point(rightEdge - btn, (headerHeight - btn) / 2); rightEdge = restartButton.Left - gap;
            adminButton.Location = new Point(rightEdge - btn, (headerHeight - btn) / 2);

            AdaptiveGameCards();
            brand.Invalidate(); header.Invalidate();
        }

        private void AdaptiveGameCards()
        {
            BufferedFlowLayoutPanel grid = currentView as BufferedFlowLayoutPanel;
            if (grid == null) return;
            int available = Math.Max(420, canvas.ClientSize.Width - 48);
            int minCard = 150;
            int maxCard = 225;
            if (config.CardSize == "Compact") { minCard = 125; maxCard = 160; }
            else if (config.CardSize == "Medium") { minCard = 165; maxCard = 195; }
            else if (config.CardSize == "Large") { minCard = 205; maxCard = 260; }
            int cols = Math.Max(2, available / (minCard + 16));
            int cw = Math.Max(minCard, Math.Min(maxCard, (available - cols * 16) / cols));
            int ch = Math.Max(108, (int)(cw * 0.66));
            foreach (Control c in grid.Controls)
            {
                GameCard card = c as GameCard;
                if (card != null) { card.Size = new Size(cw, ch); card.Margin = new Padding(8); }
            }
        }

        private void RestartClick(object sender, EventArgs e)
        {
            if (MessageBox.Show("Перезагрузить компьютер?", "ЭПОХА", MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes)
                Process.Start(new ProcessStartInfo("shutdown.exe", "/r /t 0") { UseShellExecute = false, CreateNoWindow = true });
        }

        private void PowerClick(object sender, EventArgs e)
        {
            if (MessageBox.Show("Выключить компьютер?", "ЭПОХА", MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes)
                Process.Start(new ProcessStartInfo("shutdown.exe", "/s /t 0") { UseShellExecute = false, CreateNoWindow = true });
        }

        private void MainForm_KeyDown(object sender, KeyEventArgs e)
        {
            if (e.Control && e.Alt && e.KeyCode == Keys.E)
            {
                AdminHeaderClick(adminButton, EventArgs.Empty);
                e.SuppressKeyPress = true;
            }
        }
    }

    public class GameEditDialog : Form
    {
        private GameItem game;
        private Color accent;
        private TextBox name;
        private TextBox exe;
        private TextBox args;
        private TextBox work;
        private TextBox image;

        public GameEditDialog(GameItem item, Color c, Font font)
        {
            game = item; accent = c;
            Text = "ЭПОХА — ярлык";
            StartPosition = FormStartPosition.CenterParent;
            FormBorderStyle = FormBorderStyle.FixedDialog;
            MaximizeBox = false; MinimizeBox = false;
            Size = new Size(690, 390);
            BackColor = Color.FromArgb(20, 24, 35);
            ForeColor = Color.White;
            Font = font;
            Build();
        }

        private void Build()
        {
            LabelAt("Название", 22, 22); name = TextAt(game.Name, 155, 18, 480);
            LabelAt("EXE", 22, 68); exe = TextAt(game.ExePath, 155, 64, 390); Button be = Btn("ОБЗОР", 555, 62, 80); be.Click += BrowseExe;
            LabelAt("Параметры", 22, 114); args = TextAt(game.Arguments, 155, 110, 480);
            LabelAt("Рабочая папка", 22, 160); work = TextAt(game.WorkingDirectory, 155, 156, 480);
            LabelAt("Картинка", 22, 206); image = TextAt(game.ImagePath, 155, 202, 390); Button bi = Btn("ОБЗОР", 555, 200, 80); bi.Click += BrowseImage;
            Button ok = Btn("СОХРАНИТЬ", 435, 286, 100); ok.Click += Save;
            Button cancel = Btn("ОТМЕНА", 545, 286, 90); cancel.Click += delegate { DialogResult = DialogResult.Cancel; Close(); };
        }

        private void LabelAt(string text, int x, int y)
        {
            Label l = new Label(); l.Text = text; l.SetBounds(x, y, 120, 22); l.ForeColor = Color.FromArgb(165, 176, 198); Controls.Add(l);
        }

        private TextBox TextAt(string text, int x, int y, int w)
        {
            TextBox t = new TextBox(); t.Text = text == null ? "" : text; t.SetBounds(x, y, w, 25); t.BackColor = Color.FromArgb(25, 30, 43); t.ForeColor = Color.White; t.BorderStyle = BorderStyle.FixedSingle; Controls.Add(t); return t;
        }

        private Button Btn(string text, int x, int y, int w)
        {
            Button b = new Button(); b.Text = text; b.SetBounds(x, y, w, 32); b.FlatStyle = FlatStyle.Flat; b.FlatAppearance.BorderColor = accent; b.BackColor = Color.FromArgb(30, 35, 49); b.ForeColor = Color.White; return b;
        }

        private void BrowseExe(object sender, EventArgs e)
        {
            OpenFileDialog d = new OpenFileDialog(); d.Filter = "Программы (*.exe)|*.exe|Все файлы|*.*";
            if (d.ShowDialog(this) == DialogResult.OK) { exe.Text = d.FileName; if (String.IsNullOrEmpty(work.Text)) work.Text = Path.GetDirectoryName(d.FileName); }
        }

        private void BrowseImage(object sender, EventArgs e)
        {
            OpenFileDialog d = new OpenFileDialog(); d.Filter = "Изображения|*.jpg;*.jpeg;*.png;*.bmp|Все файлы|*.*";
            if (d.ShowDialog(this) == DialogResult.OK) image.Text = d.FileName;
        }

        private void Save(object sender, EventArgs e)
        {
            if (String.IsNullOrEmpty(name.Text.Trim())) { MessageBox.Show("Введите название."); return; }
            game.Name = name.Text.Trim(); game.ExePath = exe.Text.Trim(); game.Arguments = args.Text.Trim(); game.WorkingDirectory = work.Text.Trim(); game.ImagePath = image.Text.Trim();
            DialogResult = DialogResult.OK; Close();
        }
    }
}
