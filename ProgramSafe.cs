using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.IO;
using System.Windows.Forms;
using System.Xml.Serialization;

namespace EpohaShellSafe
{
    [Serializable]
    public class ShellConfig
    {
        public string AdminPassword = "2000";
        public string PcLabel = "ПК №01";
        public string Accent = "ORANGE";
        public string CardSize = "AUTO";
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
        public string Name = "ИГРА";
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
            get { return Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Epoha"); }
        }

        public static string ConfigPath { get { return Path.Combine(BaseDir, "config.xml"); } }

        public static ShellConfig Load()
        {
            try
            {
                if (!Directory.Exists(BaseDir)) Directory.CreateDirectory(BaseDir);
                if (File.Exists(ConfigPath))
                {
                    XmlSerializer xs = new XmlSerializer(typeof(ShellConfig));
                    using (FileStream fs = File.OpenRead(ConfigPath)) return (ShellConfig)xs.Deserialize(fs);
                }
            }
            catch { }
            ShellConfig c = Defaults();
            Save(c);
            return c;
        }

        public static void Save(ShellConfig c)
        {
            if (!Directory.Exists(BaseDir)) Directory.CreateDirectory(BaseDir);
            XmlSerializer xs = new XmlSerializer(typeof(ShellConfig));
            using (FileStream fs = File.Create(ConfigPath)) xs.Serialize(fs, c);
        }

        public static ShellConfig Defaults()
        {
            ShellConfig c = new ShellConfig();
            CategoryItem all = Cat("all", "ВСЕ ИГРЫ", 0);
            CategoryItem shooters = Cat(null, "ШУТЕРЫ", 10);
            CategoryItem action = Cat(null, "ЭКШЕН", 20);
            CategoryItem strategy = Cat(null, "СТРАТЕГИИ", 30);
            CategoryItem rpg = Cat(null, "RPG", 40);
            c.Categories.Add(all); c.Categories.Add(shooters); c.Categories.Add(action); c.Categories.Add(strategy); c.Categories.Add(rpg);
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
            CategoryItem c = new CategoryItem(); if (!String.IsNullOrEmpty(id)) c.Id = id; c.Name = name; c.Sort = sort; return c;
        }

        private static GameItem Game(string name, string cat, int sort)
        {
            GameItem g = new GameItem(); g.Name = name; g.CategoryId = cat; g.Sort = sort; return g;
        }
    }

    public static class Program
    {
        public static string LogPath = Path.Combine(Path.GetTempPath(), "EpohaShell-0.2.0.log");

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
            catch (Exception ex) { Fatal("Main", ex); }
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

    public class CosmicPanel : Panel
    {
        private Point[] stars;
        public Color TopColor = Color.FromArgb(14, 18, 28);
        public Color BottomColor = Color.FromArgb(7, 9, 15);
        public Color AccentColor = Color.FromArgb(219, 142, 40);

        public CosmicPanel()
        {
            DoubleBuffered = true;
            stars = new Point[75];
            Random r = new Random(20002015);
            for (int i = 0; i < stars.Length; i++) stars[i] = new Point(r.Next(0, 2000), r.Next(0, 1200));
        }

        protected override void OnPaintBackground(PaintEventArgs e)
        {
            Rectangle rect = ClientRectangle;
            if (rect.Width <= 0 || rect.Height <= 0) return;
            using (LinearGradientBrush b = new LinearGradientBrush(rect, TopColor, BottomColor, 90f)) e.Graphics.FillRectangle(b, rect);
            using (Pen line = new Pen(Color.FromArgb(18, AccentColor)))
            {
                for (int x = -rect.Height; x < rect.Width; x += 180)
                    e.Graphics.DrawLine(line, x, rect.Height, x + rect.Height, 0);
            }
            using (SolidBrush star = new SolidBrush(Color.FromArgb(70, 220, 230, 245)))
            {
                for (int i = 0; i < stars.Length; i++)
                {
                    int x = stars[i].X % Math.Max(1, rect.Width);
                    int y = stars[i].Y % Math.Max(1, rect.Height);
                    int s = (i % 11 == 0) ? 2 : 1;
                    e.Graphics.FillRectangle(star, x, y, s, s);
                }
            }
        }
    }

    public class MainForm : Form
    {
        private ShellConfig config;
        private readonly Color Bg = Color.FromArgb(8, 10, 16);
        private readonly Color SidebarBg = Color.FromArgb(17, 20, 29);
        private readonly Color HeaderBg = Color.FromArgb(23, 27, 39);
        private readonly Color CardBg = Color.FromArgb(26, 31, 44);
        private readonly Color CardHover = Color.FromArgb(39, 46, 64);
        private readonly Color MainText = Color.FromArgb(239, 242, 248);
        private readonly Color Muted = Color.FromArgb(145, 154, 173);
        private Color Accent;

        private Panel sidebar;
        private Panel brandPanel;
        private FlowLayoutPanel menu;
        private Panel rightRoot;
        private Panel header;
        private CosmicPanel body;
        private Panel footerPanel;
        private FlowLayoutPanel grid;
        private Label clock;
        private Label pc;
        private Label footer;
        private Label brandLogo;
        private Label brandTitle;
        private Label brandSub;
        private Label brandYears;
        private Button restartButton;
        private Button shutdownButton;
        private Timer timer;
        private string selected = "all";
        private bool admin = false;
        private string adminSection = "GENERAL";

        public MainForm()
        {
            config = ConfigStore.Load();
            UpdateAccent();
            Text = "ЭПОХА — КОМПЬЮТЕРНЫЙ КЛУБ";
            BackColor = Bg;
            ForeColor = MainText;
            FormBorderStyle = FormBorderStyle.None;
            WindowState = FormWindowState.Maximized;
            StartPosition = FormStartPosition.CenterScreen;
            KeyPreview = true;
            MinimumSize = new Size(900, 650);
            BuildUi();
            timer = new Timer(); timer.Interval = 1000; timer.Tick += delegate { UpdateClock(); }; timer.Start();
            Resize += delegate { AdaptiveLayout(); };
            Shown += delegate { AdaptiveLayout(); };
            KeyDown += MainForm_KeyDown;
            UpdateClock();
        }

        private void UpdateAccent()
        {
            if (config.Accent == "BLUE") Accent = Color.FromArgb(52, 171, 255);
            else if (config.Accent == "VIOLET") Accent = Color.FromArgb(163, 100, 255);
            else if (config.Accent == "GREEN") Accent = Color.FromArgb(55, 210, 150);
            else Accent = Color.FromArgb(227, 148, 42);
        }

        private Font F(float size, FontStyle style) { return new Font("Tahoma", size, style); }

        private void BuildUi()
        {
            Controls.Clear();

            sidebar = new Panel(); sidebar.BackColor = SidebarBg; Controls.Add(sidebar);
            rightRoot = new Panel(); rightRoot.BackColor = Bg; Controls.Add(rightRoot);

            brandPanel = new Panel(); brandPanel.BackColor = Color.FromArgb(13, 16, 24); sidebar.Controls.Add(brandPanel);
            brandPanel.Paint += delegate(object s, PaintEventArgs e) { using (Pen p = new Pen(Color.FromArgb(70, Accent))) e.Graphics.DrawLine(p, 0, brandPanel.Height - 1, brandPanel.Width, brandPanel.Height - 1); };

            brandLogo = new Label(); brandLogo.Text = "Э"; brandLogo.TextAlign = ContentAlignment.MiddleCenter; brandLogo.BackColor = Accent; brandLogo.ForeColor = Color.FromArgb(15, 17, 22); brandLogo.Font = F(24, FontStyle.Bold); brandPanel.Controls.Add(brandLogo);
            brandTitle = Label("ЭПОХА", 18, FontStyle.Bold, Accent); brandPanel.Controls.Add(brandTitle);
            brandSub = Label("КОМПЬЮТЕРНЫЙ КЛУБ", 8, FontStyle.Bold, MainText); brandPanel.Controls.Add(brandSub);
            brandYears = Label("2000—2015", 8, FontStyle.Regular, Muted); brandPanel.Controls.Add(brandYears);

            menu = new FlowLayoutPanel(); menu.FlowDirection = FlowDirection.TopDown; menu.WrapContents = false; menu.AutoScroll = true; menu.Padding = new Padding(10, 14, 10, 10); menu.BackColor = SidebarBg; sidebar.Controls.Add(menu);

            header = new Panel(); header.BackColor = HeaderBg; rightRoot.Controls.Add(header);
            header.Paint += delegate(object s, PaintEventArgs e) { using (Pen p = new Pen(Color.FromArgb(55, Accent))) e.Graphics.DrawLine(p, 0, header.Height - 1, header.Width, header.Height - 1); };
            clock = Label("00:00:00", 28, FontStyle.Bold, MainText); header.Controls.Add(clock);
            pc = Label(config.PcLabel, 8, FontStyle.Regular, Muted); header.Controls.Add(pc);
            restartButton = HeaderButton("ПЕРЕЗАГРУЗИТЬ", RestartClick); shutdownButton = HeaderButton("ВЫКЛЮЧИТЬ", ShutdownClick); header.Controls.Add(restartButton); header.Controls.Add(shutdownButton);

            footerPanel = new Panel(); footerPanel.BackColor = HeaderBg; rightRoot.Controls.Add(footerPanel);
            footer = new Label(); footer.Dock = DockStyle.Fill; footer.TextAlign = ContentAlignment.MiddleLeft; footer.Padding = new Padding(16, 0, 0, 0); footer.ForeColor = Muted; footer.Font = F(8, FontStyle.Regular); footerPanel.Controls.Add(footer);

            body = new CosmicPanel(); body.TopColor = Color.FromArgb(12, 16, 27); body.BottomColor = Color.FromArgb(6, 8, 14); body.AccentColor = Accent; rightRoot.Controls.Add(body);

            RebuildMenu();
            RebuildBody();
            AdaptiveLayout();
        }

        private Label Label(string text, float size, FontStyle style, Color color)
        {
            Label l = new Label(); l.Text = text; l.AutoSize = true; l.Font = F(size, style); l.ForeColor = color; l.BackColor = Color.Transparent; return l;
        }

        private Button HeaderButton(string text, EventHandler handler)
        {
            Button b = new Button(); b.Text = text; b.FlatStyle = FlatStyle.Flat; b.FlatAppearance.BorderColor = Color.FromArgb(70, Accent); b.FlatAppearance.BorderSize = 1; b.BackColor = Color.FromArgb(29, 34, 47); b.ForeColor = MainText; b.Font = F(8, FontStyle.Bold); b.Height = 34; b.Click += handler; return b;
        }

        private Button MenuButton(string text, string key)
        {
            Button b = new Button(); b.Text = text; b.Tag = key; b.Height = 48; b.FlatStyle = FlatStyle.Flat; b.FlatAppearance.BorderSize = 0; b.TextAlign = ContentAlignment.MiddleLeft; b.Padding = new Padding(14, 0, 0, 0); b.Font = F(10, FontStyle.Bold); b.ForeColor = key == selected ? Accent : MainText; b.BackColor = key == selected ? Color.FromArgb(32, 38, 53) : SidebarBg; b.Click += MenuClick; return b;
        }

        private void RebuildMenu()
        {
            menu.Controls.Clear();
            List<CategoryItem> list = new List<CategoryItem>(config.Categories); list.Sort(delegate(CategoryItem a, CategoryItem b) { return a.Sort.CompareTo(b.Sort); });
            foreach (CategoryItem c in list) menu.Controls.Add(MenuButton(c.Name, c.Id));
            Button adminButton = MenuButton("АДМИНИСТРАТОР", "__ADMIN__"); adminButton.Margin = new Padding(0, 18, 0, 0); menu.Controls.Add(adminButton);
            AdaptiveLayout();
        }

        private void MenuClick(object sender, EventArgs e)
        {
            Button b = sender as Button; if (b == null) return; selected = b.Tag.ToString(); RebuildMenu(); RebuildBody();
        }

        private void RebuildBody()
        {
            body.Controls.Clear(); grid = null;
            if (selected == "__ADMIN__") { if (!admin) BuildAdminLogin(); else BuildAdminConsole(); AdaptiveLayout(); return; }

            grid = new FlowLayoutPanel(); grid.AutoScroll = true; grid.WrapContents = true; grid.Padding = new Padding(24, 22, 24, 24); grid.BackColor = Color.Transparent; body.Controls.Add(grid);
            List<GameItem> games = new List<GameItem>();
            foreach (GameItem g in config.Games) if (selected == "all" || g.CategoryId == selected) games.Add(g);
            games.Sort(delegate(GameItem a, GameItem b) { return a.Sort.CompareTo(b.Sort); });
            foreach (GameItem g in games) grid.Controls.Add(CreateGameCard(g));
            AdaptiveLayout();
        }

        private Control CreateGameCard(GameItem g)
        {
            Panel card = new Panel(); card.BackColor = CardBg; card.Cursor = Cursors.Hand; card.Tag = g.Id;
            card.Paint += delegate(object s, PaintEventArgs e)
            {
                using (Pen border = new Pen(Color.FromArgb(85, Accent))) e.Graphics.DrawRectangle(border, 0, 0, card.Width - 1, card.Height - 1);
                using (SolidBrush top = new SolidBrush(Accent)) e.Graphics.FillRectangle(top, 0, 0, card.Width, 3);
            };

            PictureBox image = new PictureBox(); image.Dock = DockStyle.Fill; image.SizeMode = PictureBoxSizeMode.Zoom; image.BackColor = Color.FromArgb(19, 23, 33); Image img = LoadGameImage(g); if (img != null) image.Image = img;
            Label play = new Label(); play.Text = img == null ? "▶" : ""; play.Dock = DockStyle.Fill; play.TextAlign = ContentAlignment.MiddleCenter; play.ForeColor = Accent; play.BackColor = Color.Transparent; play.Font = F(28, FontStyle.Bold); image.Controls.Add(play);
            Label name = new Label(); name.Dock = DockStyle.Bottom; name.Height = 42; name.Text = g.Name; name.TextAlign = ContentAlignment.MiddleCenter; name.ForeColor = MainText; name.BackColor = Color.FromArgb(21, 25, 35); name.Font = F(9, FontStyle.Bold);

            EventHandler launch = delegate { Launch(g); }; card.Click += launch; image.Click += launch; play.Click += launch; name.Click += launch;
            card.MouseEnter += delegate { card.BackColor = CardHover; }; card.MouseLeave += delegate { card.BackColor = CardBg; };
            card.Controls.Add(image); card.Controls.Add(name); return card;
        }

        private Image LoadGameImage(GameItem g)
        {
            try
            {
                if (!String.IsNullOrEmpty(g.ImagePath) && File.Exists(g.ImagePath)) return Image.FromFile(g.ImagePath);
                if (!String.IsNullOrEmpty(g.ExePath) && File.Exists(g.ExePath)) { Icon ico = Icon.ExtractAssociatedIcon(g.ExePath); if (ico != null) return ico.ToBitmap(); }
            }
            catch { }
            return null;
        }

        private void BuildAdminLogin()
        {
            Panel center = AdminCard(480, 300); center.Tag = "adminCenter"; body.Controls.Add(center);
            Label icon = CenterLabel("⚙", 28, Accent, 20, 30, 440, 58); center.Controls.Add(icon);
            Label title = CenterLabel("АДМИНИСТРАТОР", 16, MainText, 20, 92, 440, 34); center.Controls.Add(title);
            Label hint = CenterLabel("Вход в настройки компьютерного клуба", 9, Muted, 30, 132, 420, 34); center.Controls.Add(hint);
            Button login = BigButton("ВОЙТИ", 130, 205, 220, 50); login.Click += AdminLoginClick; center.Controls.Add(login);
        }

        private void BuildAdminConsole()
        {
            Panel nav = new Panel(); nav.BackColor = Color.FromArgb(18, 22, 32); nav.Tag = "adminNav"; body.Controls.Add(nav);
            string[] names = new string[] { "ОБЩИЕ", "ВКЛАДКИ", "ИГРЫ", "ВНЕШНИЙ ВИД", "СИСТЕМА" };
            string[] keys = new string[] { "GENERAL", "CATEGORIES", "GAMES", "APPEARANCE", "SYSTEM" };
            int y = 18;
            for (int i = 0; i < names.Length; i++)
            {
                Button b = new Button(); b.Text = names[i]; b.Tag = keys[i]; b.SetBounds(12, y, 176, 42); b.FlatStyle = FlatStyle.Flat; b.FlatAppearance.BorderSize = 0; b.TextAlign = ContentAlignment.MiddleLeft; b.Padding = new Padding(12, 0, 0, 0); b.Font = F(9, FontStyle.Bold); b.ForeColor = adminSection == keys[i] ? Accent : MainText; b.BackColor = adminSection == keys[i] ? Color.FromArgb(35, 41, 57) : Color.FromArgb(18, 22, 32); b.Click += AdminSectionClick; nav.Controls.Add(b); y += 48;
            }
            Button logout = new Button(); logout.Text = "ВЫЙТИ ИЗ АДМИНКИ"; logout.Tag = "logout"; logout.SetBounds(12, y + 20, 176, 42); logout.FlatStyle = FlatStyle.Flat; logout.FlatAppearance.BorderColor = Color.FromArgb(80, Accent); logout.BackColor = Color.FromArgb(27, 31, 43); logout.ForeColor = MainText; logout.Font = F(8, FontStyle.Bold); logout.Click += AdminLogoutClick; nav.Controls.Add(logout);

            Panel content = new Panel(); content.BackColor = Color.FromArgb(16, 20, 30); content.Tag = "adminContent"; body.Controls.Add(content);
            BuildAdminSection(content);
        }

        private void AdminSectionClick(object sender, EventArgs e)
        {
            Button b = sender as Button; if (b == null) return; adminSection = b.Tag.ToString(); RebuildBody();
        }

        private Panel AdminCard(int w, int h)
        {
            Panel p = new Panel(); p.Size = new Size(w, h); p.BackColor = Color.FromArgb(20, 25, 36); p.Paint += delegate(object s, PaintEventArgs e) { using (Pen pen = new Pen(Color.FromArgb(85, Accent))) e.Graphics.DrawRectangle(pen, 0, 0, p.Width - 1, p.Height - 1); }; return p;
        }

        private Label CenterLabel(string text, float size, Color color, int x, int y, int w, int h)
        {
            Label l = new Label(); l.Text = text; l.SetBounds(x, y, w, h); l.TextAlign = ContentAlignment.MiddleCenter; l.ForeColor = color; l.BackColor = Color.Transparent; l.Font = F(size, FontStyle.Bold); return l;
        }

        private Button BigButton(string text, int x, int y, int w, int h)
        {
            Button b = new Button(); b.Text = text; b.SetBounds(x, y, w, h); b.FlatStyle = FlatStyle.Flat; b.FlatAppearance.BorderColor = Accent; b.BackColor = Accent; b.ForeColor = Color.FromArgb(16, 18, 22); b.Font = F(11, FontStyle.Bold); return b;
        }

        private void BuildAdminSection(Panel p)
        {
            if (adminSection == "CATEGORIES") BuildCategoriesSettings(p);
            else if (adminSection == "GAMES") BuildGamesSettings(p);
            else if (adminSection == "APPEARANCE") BuildAppearanceSettings(p);
            else if (adminSection == "SYSTEM") BuildSystemSettings(p);
            else BuildGeneralSettings(p);
        }

        private Label SectionTitle(Panel p, string text)
        {
            Label l = Label(text, 15, FontStyle.Bold, MainText); l.Location = new Point(24, 22); p.Controls.Add(l); return l;
        }

        private void BuildGeneralSettings(Panel p)
        {
            SectionTitle(p, "ОБЩИЕ НАСТРОЙКИ");
            Label lp = Label("Подпись компьютера", 9, FontStyle.Bold, Muted); lp.Location = new Point(26, 78); p.Controls.Add(lp);
            TextBox pcBox = new TextBox(); pcBox.Name = "pcBox"; pcBox.Text = config.PcLabel; pcBox.SetBounds(26, 104, 250, 26); pcBox.Font = F(9, FontStyle.Regular); p.Controls.Add(pcBox);
            Button save = SmallButton("СОХРАНИТЬ", 26, 150, 150); save.Click += delegate { config.PcLabel = pcBox.Text.Trim(); if (config.PcLabel.Length == 0) config.PcLabel = "ПК"; ConfigStore.Save(config); pc.Text = config.PcLabel; MessageBox.Show("Настройки сохранены.", "ЭПОХА"); }; p.Controls.Add(save);

            Label passL = Label("Пароль администратора", 9, FontStyle.Bold, Muted); passL.Location = new Point(26, 224); p.Controls.Add(passL);
            Button pass = SmallButton("СМЕНИТЬ ПАРОЛЬ", 26, 254, 180); pass.Click += ChangePasswordClick; p.Controls.Add(pass);
        }

        private void BuildCategoriesSettings(Panel p)
        {
            SectionTitle(p, "ВКЛАДКИ ЛЕВОГО МЕНЮ");
            ListBox list = new ListBox(); list.Name = "catList"; list.SetBounds(26, 70, 320, 330); list.Font = F(9, FontStyle.Regular); list.BackColor = Color.FromArgb(24, 28, 39); list.ForeColor = MainText;
            List<CategoryItem> cats = new List<CategoryItem>(config.Categories); cats.Sort(delegate(CategoryItem a, CategoryItem b) { return a.Sort.CompareTo(b.Sort); }); foreach (CategoryItem c in cats) list.Items.Add(c); p.Controls.Add(list);
            Button add = SmallButton("ДОБАВИТЬ", 370, 70, 150); add.Click += delegate { string name = Prompt.Show("Название новой вкладки", "ЭПОХА", false, "НОВАЯ ВКЛАДКА"); if (String.IsNullOrEmpty(name)) return; CategoryItem c = new CategoryItem(); c.Name = name.Trim().ToUpper(); c.Sort = config.Categories.Count * 10; config.Categories.Add(c); SaveRefreshAdmin(); }; p.Controls.Add(add);
            Button rename = SmallButton("ПЕРЕИМЕНОВАТЬ", 370, 120, 150); rename.Click += delegate { CategoryItem c = list.SelectedItem as CategoryItem; if (c == null || c.Id == "all") return; string name = Prompt.Show("Новое название", "ЭПОХА", false, c.Name); if (String.IsNullOrEmpty(name)) return; c.Name = name.Trim().ToUpper(); ConfigStore.Save(config); SaveRefreshAdmin(); }; p.Controls.Add(rename);
            Button del = SmallButton("УДАЛИТЬ", 370, 170, 150); del.Click += delegate { CategoryItem c = list.SelectedItem as CategoryItem; if (c == null || c.Id == "all") return; if (MessageBox.Show("Удалить вкладку и её ярлыки?", "ЭПОХА", MessageBoxButtons.YesNo) != DialogResult.Yes) return; config.Games.RemoveAll(delegate(GameItem g) { return g.CategoryId == c.Id; }); config.Categories.Remove(c); SaveRefreshAdmin(); }; p.Controls.Add(del);
            Button up = SmallButton("ВЫШЕ", 370, 240, 150); up.Click += delegate { MoveCategory(list.SelectedItem as CategoryItem, -1); }; p.Controls.Add(up);
            Button down = SmallButton("НИЖЕ", 370, 290, 150); down.Click += delegate { MoveCategory(list.SelectedItem as CategoryItem, 1); }; p.Controls.Add(down);
        }

        private void MoveCategory(CategoryItem c, int direction)
        {
            if (c == null || c.Id == "all") return;
            List<CategoryItem> cats = new List<CategoryItem>(config.Categories); cats.Sort(delegate(CategoryItem a, CategoryItem b) { return a.Sort.CompareTo(b.Sort); }); int idx = cats.IndexOf(c); int ni = idx + direction; if (ni < 1 || ni >= cats.Count) return; int t = cats[ni].Sort; cats[ni].Sort = c.Sort; c.Sort = t; SaveRefreshAdmin();
        }

        private void BuildGamesSettings(Panel p)
        {
            SectionTitle(p, "ЯРЛЫКИ ИГР");
            ComboBox cat = new ComboBox(); cat.DropDownStyle = ComboBoxStyle.DropDownList; cat.SetBounds(26, 66, 260, 26); cat.Font = F(9, FontStyle.Regular); foreach (CategoryItem c in config.Categories) if (c.Id != "all") cat.Items.Add(c); if (cat.Items.Count > 0) cat.SelectedIndex = 0; p.Controls.Add(cat);
            ListBox list = new ListBox(); list.SetBounds(26, 108, 380, 310); list.Font = F(9, FontStyle.Regular); list.BackColor = Color.FromArgb(24, 28, 39); list.ForeColor = MainText; p.Controls.Add(list);
            EventHandler reload = delegate { list.Items.Clear(); CategoryItem cc = cat.SelectedItem as CategoryItem; if (cc == null) return; List<GameItem> gs = new List<GameItem>(); foreach (GameItem g in config.Games) if (g.CategoryId == cc.Id) gs.Add(g); gs.Sort(delegate(GameItem a, GameItem b) { return a.Sort.CompareTo(b.Sort); }); foreach (GameItem g in gs) list.Items.Add(g); };
            cat.SelectedIndexChanged += reload; reload(null, EventArgs.Empty);
            Button add = SmallButton("ДОБАВИТЬ ИГРУ", 430, 108, 170); add.Click += delegate { CategoryItem cc = cat.SelectedItem as CategoryItem; if (cc == null) return; GameItem g = new GameItem(); g.CategoryId = cc.Id; g.Sort = config.Games.Count * 10; using (GameEditForm f = new GameEditForm(g, Accent)) if (f.ShowDialog(this) == DialogResult.OK) { config.Games.Add(g); ConfigStore.Save(config); reload(null, EventArgs.Empty); RebuildMenu(); } }; p.Controls.Add(add);
            Button edit = SmallButton("ИЗМЕНИТЬ", 430, 158, 170); edit.Click += delegate { GameItem g = list.SelectedItem as GameItem; if (g == null) return; using (GameEditForm f = new GameEditForm(g, Accent)) if (f.ShowDialog(this) == DialogResult.OK) { ConfigStore.Save(config); reload(null, EventArgs.Empty); } }; p.Controls.Add(edit);
            Button del = SmallButton("УДАЛИТЬ", 430, 208, 170); del.Click += delegate { GameItem g = list.SelectedItem as GameItem; if (g == null) return; if (MessageBox.Show("Удалить ярлык?", "ЭПОХА", MessageBoxButtons.YesNo) != DialogResult.Yes) return; config.Games.Remove(g); ConfigStore.Save(config); reload(null, EventArgs.Empty); }; p.Controls.Add(del);
            Button up = SmallButton("ВЫШЕ", 430, 278, 170); up.Click += delegate { MoveGame(list.SelectedItem as GameItem, -1); }; p.Controls.Add(up);
            Button down = SmallButton("НИЖЕ", 430, 328, 170); down.Click += delegate { MoveGame(list.SelectedItem as GameItem, 1); }; p.Controls.Add(down);
        }

        private void MoveGame(GameItem g, int direction)
        {
            if (g == null) return; List<GameItem> list = new List<GameItem>(); foreach (GameItem x in config.Games) if (x.CategoryId == g.CategoryId) list.Add(x); list.Sort(delegate(GameItem a, GameItem b) { return a.Sort.CompareTo(b.Sort); }); int idx = list.IndexOf(g); int ni = idx + direction; if (ni < 0 || ni >= list.Count) return; int t = list[ni].Sort; list[ni].Sort = g.Sort; g.Sort = t; SaveRefreshAdmin();
        }

        private void BuildAppearanceSettings(Panel p)
        {
            SectionTitle(p, "ВНЕШНИЙ ВИД");
            Label a = Label("Цвет подсветки", 9, FontStyle.Bold, Muted); a.Location = new Point(26, 78); p.Controls.Add(a);
            string[] vals = new string[] { "ORANGE", "BLUE", "VIOLET", "GREEN" }; string[] labels = new string[] { "ОРАНЖЕВЫЙ", "СИНИЙ", "ФИОЛЕТОВЫЙ", "ЗЕЛЁНЫЙ" }; int x = 26;
            for (int i = 0; i < vals.Length; i++)
            {
                Button b = SmallButton(labels[i], x, 110, 135); b.Tag = vals[i]; if (config.Accent == vals[i]) b.BackColor = Accent; b.Click += AccentClick; p.Controls.Add(b); x += 145;
            }
            Label cs = Label("Размер карточек игр", 9, FontStyle.Bold, Muted); cs.Location = new Point(26, 190); p.Controls.Add(cs);
            ComboBox combo = new ComboBox(); combo.DropDownStyle = ComboBoxStyle.DropDownList; combo.SetBounds(26, 220, 240, 26); combo.Items.Add("AUTO"); combo.Items.Add("COMPACT"); combo.Items.Add("LARGE"); combo.SelectedItem = config.CardSize; combo.Font = F(9, FontStyle.Regular); p.Controls.Add(combo);
            Button save = SmallButton("ПРИМЕНИТЬ", 290, 217, 150); save.Click += delegate { if (combo.SelectedItem != null) config.CardSize = combo.SelectedItem.ToString(); ConfigStore.Save(config); AdaptiveLayout(); MessageBox.Show("Размер карточек применён.", "ЭПОХА"); }; p.Controls.Add(save);
        }

        private void AccentClick(object sender, EventArgs e)
        {
            Button b = sender as Button; if (b == null) return; config.Accent = b.Tag.ToString(); ConfigStore.Save(config); UpdateAccent(); BuildUi(); selected = "__ADMIN__"; admin = true; adminSection = "APPEARANCE"; RebuildMenu(); RebuildBody();
        }

        private void BuildSystemSettings(Panel p)
        {
            SectionTitle(p, "СИСТЕМА");
            Label info = Label("Компьютер: " + Environment.MachineName + "\r\nОС: " + Environment.OSVersion.ToString() + "\r\nКонфигурация: " + ConfigStore.ConfigPath, 9, FontStyle.Regular, Muted); info.AutoSize = false; info.SetBounds(26, 74, 650, 90); p.Controls.Add(info);
            Button folder = SmallButton("ОТКРЫТЬ ПАПКУ НАСТРОЕК", 26, 190, 230); folder.Click += delegate { try { Process.Start("explorer.exe", ConfigStore.BaseDir); } catch { } }; p.Controls.Add(folder);
            Button explorer = SmallButton("ОТКРЫТЬ ПРОВОДНИК", 26, 245, 230); explorer.Click += delegate { try { Process.Start("explorer.exe"); } catch { } }; p.Controls.Add(explorer);
            Button exit = SmallButton("ЗАКРЫТЬ ЭПОХУ", 26, 300, 230); exit.Click += delegate { Close(); }; p.Controls.Add(exit);
            Label warning = Label("Защитные клубные ограничения пока специально не включены в тестовой 0.2.0. Сначала доводим интерфейс и админку до стабильного состояния.", 8, FontStyle.Regular, Muted); warning.AutoSize = false; warning.SetBounds(290, 190, 390, 100); p.Controls.Add(warning);
        }

        private Button SmallButton(string text, int x, int y, int w)
        {
            Button b = new Button(); b.Text = text; b.SetBounds(x, y, w, 36); b.FlatStyle = FlatStyle.Flat; b.FlatAppearance.BorderColor = Color.FromArgb(75, Accent); b.BackColor = Color.FromArgb(31, 36, 49); b.ForeColor = MainText; b.Font = F(8, FontStyle.Bold); return b;
        }

        private void ChangePasswordClick(object sender, EventArgs e)
        {
            string p = Prompt.Show("Новый пароль администратора", "ЭПОХА", true, ""); if (String.IsNullOrEmpty(p)) return; config.AdminPassword = p; ConfigStore.Save(config); MessageBox.Show("Пароль изменён.", "ЭПОХА");
        }

        private void SaveRefreshAdmin()
        {
            ConfigStore.Save(config); RebuildMenu(); selected = "__ADMIN__"; admin = true; RebuildBody();
        }

        private void AdminLoginClick(object sender, EventArgs e)
        {
            string pass = Prompt.Show("Введите пароль администратора", "ЭПОХА", true, ""); if (pass == null) return; if (pass != config.AdminPassword) { MessageBox.Show("Неверный пароль", "ЭПОХА", MessageBoxButtons.OK, MessageBoxIcon.Warning); return; } admin = true; adminSection = "GENERAL"; RebuildBody();
        }

        private void AdminLogoutClick(object sender, EventArgs e) { admin = false; RebuildBody(); }

        private void Launch(GameItem g)
        {
            if (String.IsNullOrEmpty(g.ExePath) || !File.Exists(g.ExePath)) { MessageBox.Show("Для «" + g.Name + "» пока не указан рабочий EXE.\r\n\r\nДобавьте путь во вкладке АДМИНИСТРАТОР → ИГРЫ.", "ЭПОХА"); return; }
            try { ProcessStartInfo psi = new ProcessStartInfo(g.ExePath, g.Arguments == null ? "" : g.Arguments); psi.WorkingDirectory = !String.IsNullOrEmpty(g.WorkingDirectory) ? g.WorkingDirectory : Path.GetDirectoryName(g.ExePath); Process.Start(psi); }
            catch (Exception ex) { MessageBox.Show(ex.Message, "Ошибка запуска"); }
        }

        private void UpdateClock()
        {
            clock.Text = DateTime.Now.ToString("HH:mm:ss"); pc.Text = config.PcLabel; footer.Text = "ЭПОХА 0.2.0  •  " + config.PcLabel + "  •  " + Environment.MachineName + "  •  CLUB SHELL"; AdaptiveHeaderOnly();
        }

        private void AdaptiveLayout()
        {
            if (ClientSize.Width < 500) return;
            int w = ClientSize.Width; int h = ClientSize.Height;
            int sidebarWidth = Math.Max(220, Math.Min(310, (int)(w * 0.16)));

            sidebar.SetBounds(0, 0, sidebarWidth, h);
            rightRoot.SetBounds(sidebarWidth, 0, Math.Max(1, w - sidebarWidth), h);

            int brandHeight = h < 800 ? 102 : 116;
            brandPanel.SetBounds(0, 0, sidebarWidth, brandHeight);
            menu.SetBounds(0, brandHeight, sidebarWidth, Math.Max(1, h - brandHeight));
            foreach (Control c in menu.Controls) c.Width = sidebarWidth - 24;

            if (sidebarWidth < 245)
            {
                brandLogo.SetBounds(12, 18, 42, 42); brandTitle.Font = F(15, FontStyle.Bold); brandTitle.Location = new Point(64, 17); brandSub.Font = F(7, FontStyle.Bold); brandSub.Location = new Point(65, 45); brandYears.Location = new Point(65, 66);
            }
            else
            {
                brandLogo.SetBounds(14, 18, 48, 48); brandTitle.Font = F(18, FontStyle.Bold); brandTitle.Location = new Point(74, 17); brandSub.Font = F(8, FontStyle.Bold); brandSub.Location = new Point(75, 48); brandYears.Location = new Point(75, 70);
            }

            int headerHeight = h < 800 ? 78 : 92; int footerHeight = 34;
            header.SetBounds(0, 0, rightRoot.ClientSize.Width, headerHeight);
            footerPanel.SetBounds(0, Math.Max(headerHeight, rightRoot.ClientSize.Height - footerHeight), rightRoot.ClientSize.Width, footerHeight);
            body.SetBounds(0, headerHeight, rightRoot.ClientSize.Width, Math.Max(1, rightRoot.ClientSize.Height - headerHeight - footerHeight));
            AdaptiveHeaderOnly();

            if (selected == "__ADMIN__")
            {
                foreach (Control c in body.Controls)
                {
                    if (c.Tag != null && c.Tag.ToString() == "adminCenter") { c.Left = Math.Max(20, (body.ClientSize.Width - c.Width) / 2); c.Top = Math.Max(20, (body.ClientSize.Height - c.Height) / 2); }
                    else if (c.Tag != null && c.Tag.ToString() == "adminNav") c.SetBounds(20, 20, 200, Math.Max(360, body.ClientSize.Height - 40));
                    else if (c.Tag != null && c.Tag.ToString() == "adminContent") c.SetBounds(238, 20, Math.Max(420, body.ClientSize.Width - 258), Math.Max(360, body.ClientSize.Height - 40));
                }
                return;
            }

            if (grid == null) return;
            grid.SetBounds(0, 0, body.ClientSize.Width, body.ClientSize.Height);
            int available = Math.Max(420, body.ClientSize.Width - 48);
            int minCard = 150; int maxCard = 220;
            if (config.CardSize == "COMPACT") { minCard = 125; maxCard = 165; }
            else if (config.CardSize == "LARGE") { minCard = 200; maxCard = 280; }
            else { if (w < 1200) { minCard = 135; maxCard = 180; } else if (w > 1900) { minCard = 170; maxCard = 230; } }
            int columns = Math.Max(2, available / (minCard + 18));
            int cw = Math.Max(minCard, Math.Min(maxCard, (available - columns * 18) / columns));
            int ch = Math.Max(100, (int)(cw * 0.66));
            foreach (Control c in grid.Controls) { c.Width = cw; c.Height = ch; c.Margin = new Padding(9); }
        }

        private void AdaptiveHeaderOnly()
        {
            if (rightRoot == null || header == null || clock == null) return; int w = rightRoot.ClientSize.Width; if (w <= 0) return;
            clock.Left = Math.Max(10, (w - clock.PreferredWidth) / 2); clock.Top = header.Height < 85 ? 8 : 10; pc.Left = Math.Max(10, (w - pc.PreferredWidth) / 2); pc.Top = clock.Bottom + 1;
            int buttonWidth = w < 800 ? 105 : 130; shutdownButton.Width = buttonWidth; restartButton.Width = buttonWidth + 18; shutdownButton.Left = w - shutdownButton.Width - 14; shutdownButton.Top = (header.Height - shutdownButton.Height) / 2; restartButton.Left = shutdownButton.Left - restartButton.Width - 8; restartButton.Top = shutdownButton.Top;
        }

        private void RestartClick(object sender, EventArgs e) { if (MessageBox.Show("Перезагрузить компьютер?", "ЭПОХА", MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes) Process.Start(new ProcessStartInfo("shutdown.exe", "/r /t 0") { UseShellExecute = false, CreateNoWindow = true }); }
        private void ShutdownClick(object sender, EventArgs e) { if (MessageBox.Show("Выключить компьютер?", "ЭПОХА", MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes) Process.Start(new ProcessStartInfo("shutdown.exe", "/s /t 0") { UseShellExecute = false, CreateNoWindow = true }); }

        private void MainForm_KeyDown(object sender, KeyEventArgs e)
        {
            if (e.Control && e.Alt && e.KeyCode == Keys.E) { selected = "__ADMIN__"; RebuildMenu(); RebuildBody(); if (!admin) AdminLoginClick(this, EventArgs.Empty); e.SuppressKeyPress = true; }
        }
    }

    public class GameEditForm : Form
    {
        private GameItem game; private TextBox name, exe, args, work, image; private Color accent;
        public GameEditForm(GameItem g, Color a)
        {
            game = g; accent = a; Text = "ЭПОХА — Ярлык игры"; StartPosition = FormStartPosition.CenterParent; Size = new Size(680, 405); BackColor = Color.FromArgb(20, 24, 34); ForeColor = Color.White; Font = new Font("Tahoma", 9);
            MakeLabel("Название", 20, 24); name = MakeText(g.Name, 155, 20, 440); MakeLabel("EXE", 20, 70); exe = MakeText(g.ExePath, 155, 66, 350); Button be = MakeButton("ОБЗОР", 515, 65, 80); be.Click += BrowseExe; MakeLabel("Параметры", 20, 116); args = MakeText(g.Arguments, 155, 112, 440); MakeLabel("Рабочая папка", 20, 162); work = MakeText(g.WorkingDirectory, 155, 158, 440); MakeLabel("Картинка", 20, 208); image = MakeText(g.ImagePath, 155, 204, 350); Button bi = MakeButton("ОБЗОР", 515, 203, 80); bi.Click += BrowseImage; Button ok = MakeButton("СОХРАНИТЬ", 390, 295, 110); ok.Click += Save; Button cancel = MakeButton("ОТМЕНА", 510, 295, 85); cancel.Click += delegate { DialogResult = DialogResult.Cancel; Close(); };
        }
        private void MakeLabel(string t, int x, int y) { Label l = new Label(); l.Text = t; l.SetBounds(x, y, 125, 24); l.ForeColor = Color.Gainsboro; Controls.Add(l); }
        private TextBox MakeText(string t, int x, int y, int w) { TextBox b = new TextBox(); b.Text = t == null ? "" : t; b.SetBounds(x, y, w, 26); Controls.Add(b); return b; }
        private Button MakeButton(string t, int x, int y, int w) { Button b = new Button(); b.Text = t; b.SetBounds(x, y, w, 32); b.FlatStyle = FlatStyle.Flat; b.FlatAppearance.BorderColor = accent; b.BackColor = Color.FromArgb(35, 40, 54); b.ForeColor = Color.White; Controls.Add(b); return b; }
        private void BrowseExe(object s, EventArgs e) { OpenFileDialog d = new OpenFileDialog(); d.Filter = "Программы (*.exe)|*.exe|Все файлы|*.*"; if (d.ShowDialog(this) == DialogResult.OK) { exe.Text = d.FileName; if (String.IsNullOrEmpty(work.Text)) work.Text = Path.GetDirectoryName(d.FileName); } }
        private void BrowseImage(object s, EventArgs e) { OpenFileDialog d = new OpenFileDialog(); d.Filter = "Изображения|*.png;*.jpg;*.jpeg;*.bmp;*.gif|Все файлы|*.*"; if (d.ShowDialog(this) == DialogResult.OK) image.Text = d.FileName; }
        private void Save(object s, EventArgs e) { if (String.IsNullOrEmpty(name.Text.Trim())) { MessageBox.Show("Введите название."); return; } game.Name = name.Text.Trim(); game.ExePath = exe.Text.Trim(); game.Arguments = args.Text.Trim(); game.WorkingDirectory = work.Text.Trim(); game.ImagePath = image.Text.Trim(); DialogResult = DialogResult.OK; Close(); }
    }

    public static class Prompt
    {
        public static string Show(string text, string caption, bool password, string value)
        {
            Form f = new Form(); f.Text = caption; f.Width = 430; f.Height = 165; f.StartPosition = FormStartPosition.CenterParent; f.FormBorderStyle = FormBorderStyle.FixedDialog; f.MinimizeBox = false; f.MaximizeBox = false; f.Font = new Font("Tahoma", 9);
            Label l = new Label(); l.Text = text; l.SetBounds(15, 15, 385, 22); f.Controls.Add(l); TextBox tb = new TextBox(); tb.Text = value == null ? "" : value; tb.SetBounds(15, 42, 385, 25); if (password) tb.UseSystemPasswordChar = true; f.Controls.Add(tb); Button ok = new Button(); ok.Text = "OK"; ok.DialogResult = DialogResult.OK; ok.SetBounds(245, 78, 75, 30); f.Controls.Add(ok); Button cancel = new Button(); cancel.Text = "Отмена"; cancel.DialogResult = DialogResult.Cancel; cancel.SetBounds(325, 78, 75, 30); f.Controls.Add(cancel); f.AcceptButton = ok; f.CancelButton = cancel; return f.ShowDialog() == DialogResult.OK ? tb.Text : null;
        }
    }
}
