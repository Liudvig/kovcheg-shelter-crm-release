using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Runtime.InteropServices;
using System.Windows.Forms;
using System.Xml.Serialization;
using Microsoft.Win32;

namespace EpohaShell
{
    [Serializable]
    public class ShellConfig
    {
        public string AdminPassword = "2000";
        public string PcLabel = "ПК №01";
        public bool KioskRestrictions = false;
        public List<CategoryItem> Categories = new List<CategoryItem>();
        public List<GameItem> Games = new List<GameItem>();
    }

    [Serializable]
    public class CategoryItem
    {
        public string Id = Guid.NewGuid().ToString("N");
        public string Name = "Раздел";
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
                string p = Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData);
                return Path.Combine(p, "Epoha");
            }
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
            ShellConfig c = CreateDefault();
            Save(c);
            return c;
        }

        public static void Save(ShellConfig c)
        {
            try
            {
                if (!Directory.Exists(BaseDir)) Directory.CreateDirectory(BaseDir);
                XmlSerializer xs = new XmlSerializer(typeof(ShellConfig));
                using (FileStream fs = File.Create(ConfigPath)) xs.Serialize(fs, c);
            }
            catch (Exception ex)
            {
                MessageBox.Show("Не удалось сохранить настройки:\r\n" + ex.Message, "ЭПОХА", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            }
        }

        private static ShellConfig CreateDefault()
        {
            ShellConfig c = new ShellConfig();
            CategoryItem all = new CategoryItem(); all.Id = "all"; all.Name = "ВСЕ ИГРЫ"; all.Sort = 0;
            CategoryItem shooters = new CategoryItem(); shooters.Name = "ШУТЕРЫ"; shooters.Sort = 10;
            CategoryItem action = new CategoryItem(); action.Name = "ЭКШЕН"; action.Sort = 20;
            CategoryItem strategy = new CategoryItem(); strategy.Name = "СТРАТЕГИИ"; strategy.Sort = 30;
            CategoryItem rpg = new CategoryItem(); rpg.Name = "RPG"; rpg.Sort = 40;
            c.Categories.Add(all); c.Categories.Add(shooters); c.Categories.Add(action); c.Categories.Add(strategy); c.Categories.Add(rpg);
            c.Games.Add(NewGame("Counter-Strike 1.6", shooters.Id, 10));
            c.Games.Add(NewGame("S.T.A.L.K.E.R.", shooters.Id, 20));
            c.Games.Add(NewGame("Unreal Tournament", shooters.Id, 30));
            c.Games.Add(NewGame("GTA San Andreas", action.Id, 40));
            c.Games.Add(NewGame("Assassin's Creed", action.Id, 50));
            c.Games.Add(NewGame("Warcraft III", strategy.Id, 60));
            c.Games.Add(NewGame("Diablo II", rpg.Id, 70));
            return c;
        }

        private static GameItem NewGame(string name, string cat, int sort)
        {
            GameItem g = new GameItem(); g.Name = name; g.CategoryId = cat; g.Sort = sort; return g;
        }
    }

    public static class Program
    {
        [STAThread]
        public static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new MainForm());
        }
    }

    public class MainForm : Form
    {
        private ShellConfig config;
        private Panel header;
        private FlowLayoutPanel leftMenu;
        private FlowLayoutPanel gameGrid;
        private Label clockLabel;
        private Label pcLabel;
        private Label titleLabel;
        private Label subtitleLabel;
        private Label yearsLabel;
        private Label statusLabel;
        private string currentCategory = "all";
        private Timer clockTimer;
        private KeyboardBlocker blocker;
        private bool adminMode = false;
        private bool allowClose = false;

        private readonly Color Bg = Color.FromArgb(17, 19, 24);
        private readonly Color PanelBg = Color.FromArgb(26, 29, 36);
        private readonly Color CardBg = Color.FromArgb(36, 40, 49);
        private readonly Color Accent = Color.FromArgb(221, 143, 41);
        private readonly Color TextMain = Color.FromArgb(238, 238, 238);
        private readonly Color TextMuted = Color.FromArgb(170, 174, 182);

        public MainForm()
        {
            config = ConfigStore.Load();
            Text = "ЭПОХА — КОМПЬЮТЕРНЫЙ КЛУБ";
            BackColor = Bg;
            ForeColor = TextMain;
            FormBorderStyle = FormBorderStyle.None;
            WindowState = FormWindowState.Maximized;
            StartPosition = FormStartPosition.CenterScreen;
            KeyPreview = true;
            MinimumSize = new Size(900, 650);
            BuildUi();
            ApplyRestrictions(config.KioskRestrictions);
            clockTimer = new Timer();
            clockTimer.Interval = 1000;
            clockTimer.Tick += delegate { UpdateClock(); };
            clockTimer.Start();
            UpdateClock();
            Resize += delegate { LayoutAdaptive(); };
            Shown += delegate { LayoutAdaptive(); };
            FormClosing += MainForm_FormClosing;
            KeyDown += MainForm_KeyDown;
        }

        private void BuildUi()
        {
            header = new Panel(); header.BackColor = PanelBg; header.Dock = DockStyle.Top; header.Height = 112; Controls.Add(header);

            titleLabel = new Label(); titleLabel.Text = "ЭПОХА"; titleLabel.ForeColor = Accent; titleLabel.Font = new Font("Segoe UI", 26, FontStyle.Bold); titleLabel.AutoSize = true; header.Controls.Add(titleLabel);
            subtitleLabel = new Label(); subtitleLabel.Text = "КОМПЬЮТЕРНЫЙ КЛУБ"; subtitleLabel.ForeColor = TextMain; subtitleLabel.Font = new Font("Segoe UI", 11, FontStyle.Bold); subtitleLabel.AutoSize = true; header.Controls.Add(subtitleLabel);
            yearsLabel = new Label(); yearsLabel.Text = "2000—2015"; yearsLabel.ForeColor = TextMuted; yearsLabel.Font = new Font("Segoe UI", 9, FontStyle.Regular); yearsLabel.AutoSize = true; header.Controls.Add(yearsLabel);

            clockLabel = MakeHeaderLabel("00:00", 15, FontStyle.Bold); pcLabel = MakeHeaderLabel(config.PcLabel, 9, FontStyle.Regular); header.Controls.Add(clockLabel); header.Controls.Add(pcLabel);
            Button admin = MakeTopButton("АДМИН", AdminClicked); admin.Tag = "admin"; header.Controls.Add(admin);
            Button restart = MakeTopButton("ПЕРЕЗАГРУЗИТЬ", RestartClicked); restart.Tag = "restart"; header.Controls.Add(restart);
            Button shutdown = MakeTopButton("ВЫКЛЮЧИТЬ", ShutdownClicked); shutdown.Tag = "shutdown"; header.Controls.Add(shutdown);

            Panel bottom = new Panel(); bottom.Dock = DockStyle.Bottom; bottom.Height = 34; bottom.BackColor = PanelBg; Controls.Add(bottom);
            statusLabel = new Label(); statusLabel.Dock = DockStyle.Fill; statusLabel.TextAlign = ContentAlignment.MiddleLeft; statusLabel.Padding = new Padding(18, 0, 0, 0); statusLabel.ForeColor = TextMuted; statusLabel.Font = new Font("Segoe UI", 8, FontStyle.Regular); bottom.Controls.Add(statusLabel);

            leftMenu = new FlowLayoutPanel(); leftMenu.Dock = DockStyle.Left; leftMenu.FlowDirection = FlowDirection.TopDown; leftMenu.WrapContents = false; leftMenu.AutoScroll = true; leftMenu.BackColor = PanelBg; leftMenu.Padding = new Padding(10, 14, 10, 10); Controls.Add(leftMenu);
            gameGrid = new FlowLayoutPanel(); gameGrid.Dock = DockStyle.Fill; gameGrid.AutoScroll = true; gameGrid.BackColor = Bg; gameGrid.Padding = new Padding(18); gameGrid.WrapContents = true; Controls.Add(gameGrid); gameGrid.BringToFront();

            RebuildCategories(); RebuildGames(); LayoutAdaptive();
        }

        private Label MakeHeaderLabel(string text, float size, FontStyle style)
        {
            Label l = new Label(); l.Text = text; l.AutoSize = true; l.ForeColor = TextMain; l.Font = new Font("Segoe UI", size, style); return l;
        }

        private Button MakeTopButton(string text, EventHandler click)
        {
            Button b = new Button(); b.Text = text; b.FlatStyle = FlatStyle.Flat; b.FlatAppearance.BorderColor = Color.FromArgb(64, 68, 78); b.BackColor = CardBg; b.ForeColor = TextMain; b.Font = new Font("Segoe UI", 8, FontStyle.Bold); b.Height = 32; b.Click += click; return b;
        }

        private void LayoutAdaptive()
        {
            if (ClientSize.Width < 100) return;
            int w = ClientSize.Width; int h = ClientSize.Height;
            header.Height = h < 800 ? 92 : 112;
            int menuWidth = Math.Max(170, Math.Min(280, (int)(w * 0.16))); leftMenu.Width = menuWidth;
            foreach (Control c in leftMenu.Controls) c.Width = menuWidth - 24;

            titleLabel.Font = new Font("Segoe UI", w < 1150 ? 20 : (w > 1900 ? 30 : 26), FontStyle.Bold);
            int centerX = w / 2; titleLabel.Location = new Point(centerX - titleLabel.PreferredWidth / 2, 8); subtitleLabel.Location = new Point(centerX - subtitleLabel.PreferredWidth / 2, titleLabel.Bottom + 1); yearsLabel.Location = new Point(centerX - yearsLabel.PreferredWidth / 2, subtitleLabel.Bottom + 1);

            int right = w - 16; Control shutdown = FindHeader("shutdown"); Control restart = FindHeader("restart"); Control admin = FindHeader("admin"); int buttonW = w < 1200 ? 92 : 118;
            if (shutdown != null) { shutdown.Width = buttonW; shutdown.Left = right - buttonW; shutdown.Top = 58; right = shutdown.Left - 6; }
            if (restart != null) { restart.Width = buttonW + 15; restart.Left = right - restart.Width; restart.Top = 58; right = restart.Left - 6; }
            if (admin != null) { admin.Width = 76; admin.Left = right - admin.Width; admin.Top = 58; }
            clockLabel.Location = new Point(w - clockLabel.PreferredWidth - 20, 10); pcLabel.Location = new Point(w - pcLabel.PreferredWidth - 20, 36);

            int available = Math.Max(520, w - menuWidth - 48); int minCard = w < 1150 ? 150 : 175; int maxCard = w > 1900 ? 245 : 215; int cols = Math.Max(3, available / (minCard + 18)); int cardW = Math.Max(minCard, Math.Min(maxCard, (available - cols * 18) / cols)); int cardH = (int)(cardW * 0.68);
            foreach (Control c in gameGrid.Controls) { c.Width = cardW; c.Height = cardH; c.Margin = new Padding(8); }
        }

        private Control FindHeader(string tag)
        {
            foreach (Control c in header.Controls) if (c.Tag != null && c.Tag.ToString() == tag) return c; return null;
        }

        private void UpdateClock()
        {
            clockLabel.Text = DateTime.Now.ToString("HH:mm");
            statusLabel.Text = "ЭПОХА 0.1  •  " + config.PcLabel + "  •  " + (config.KioskRestrictions ? "Клубный режим: ВКЛ" : "Клубный режим: ВЫКЛ") + "  •  " + Environment.MachineName;
        }

        private void RebuildCategories()
        {
            leftMenu.Controls.Clear();
            List<CategoryItem> cats = new List<CategoryItem>(config.Categories); cats.Sort(delegate(CategoryItem a, CategoryItem b) { return a.Sort.CompareTo(b.Sort); });
            foreach (CategoryItem c in cats)
            {
                Button b = new Button(); b.Text = c.Name; b.Tag = c.Id; b.Height = 45; b.FlatStyle = FlatStyle.Flat; b.FlatAppearance.BorderSize = 0; b.TextAlign = ContentAlignment.MiddleLeft; b.Padding = new Padding(14, 0, 0, 0); b.Font = new Font("Segoe UI", 10, FontStyle.Bold); b.ForeColor = c.Id == currentCategory ? Accent : TextMain; b.BackColor = c.Id == currentCategory ? Color.FromArgb(42, 45, 53) : PanelBg; b.Click += CategoryClicked; leftMenu.Controls.Add(b);
            }
            LayoutAdaptive();
        }

        private void CategoryClicked(object sender, EventArgs e)
        {
            Button b = (Button)sender; currentCategory = b.Tag.ToString(); RebuildCategories(); RebuildGames();
        }

        private void RebuildGames()
        {
            gameGrid.SuspendLayout(); gameGrid.Controls.Clear();
            List<GameItem> games = new List<GameItem>(); foreach (GameItem g in config.Games) if (currentCategory == "all" || g.CategoryId == currentCategory) games.Add(g);
            games.Sort(delegate(GameItem a, GameItem b) { return a.Sort.CompareTo(b.Sort); }); foreach (GameItem g in games) gameGrid.Controls.Add(CreateGameCard(g));
            if (games.Count == 0) { Label empty = new Label(); empty.Text = "В этом разделе пока нет игр"; empty.ForeColor = TextMuted; empty.Font = new Font("Segoe UI", 14); empty.AutoSize = true; empty.Margin = new Padding(20); gameGrid.Controls.Add(empty); }
            gameGrid.ResumeLayout(); LayoutAdaptive();
        }

        private Control CreateGameCard(GameItem game)
        {
            Panel p = new Panel(); p.Tag = game.Id; p.BackColor = CardBg; p.Cursor = Cursors.Hand; p.Margin = new Padding(8);
            p.Paint += delegate(object s, PaintEventArgs e) { using (Pen pen = new Pen(Color.FromArgb(62, 66, 76))) e.Graphics.DrawRectangle(pen, 0, 0, p.Width - 1, p.Height - 1); };
            PictureBox pic = new PictureBox(); pic.Dock = DockStyle.Fill; pic.SizeMode = PictureBoxSizeMode.Zoom; pic.BackColor = Color.FromArgb(29, 32, 39); Image img = LoadGameImage(game); if (img != null) pic.Image = img;
            Label name = new Label(); name.Text = game.Name; name.Dock = DockStyle.Bottom; name.Height = 40; name.TextAlign = ContentAlignment.MiddleCenter; name.ForeColor = TextMain; name.BackColor = Color.FromArgb(24, 27, 33); name.Font = new Font("Segoe UI", 9, FontStyle.Bold);
            p.Controls.Add(pic); p.Controls.Add(name);
            EventHandler launch = delegate { LaunchGame(game); }; p.Click += launch; pic.Click += launch; name.Click += launch;
            p.MouseEnter += delegate { p.BackColor = Color.FromArgb(46, 50, 60); }; p.MouseLeave += delegate { p.BackColor = CardBg; };
            if (adminMode)
            {
                ContextMenuStrip menu = new ContextMenuStrip(); menu.Items.Add("Изменить", null, delegate { EditGame(game); }); menu.Items.Add("Удалить", null, delegate { DeleteGame(game); }); p.ContextMenuStrip = menu; pic.ContextMenuStrip = menu; name.ContextMenuStrip = menu;
            }
            return p;
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

        private void LaunchGame(GameItem g)
        {
            if (String.IsNullOrEmpty(g.ExePath) || !File.Exists(g.ExePath)) { MessageBox.Show("Для \"" + g.Name + "\" ещё не указан рабочий EXE.\r\n\r\nВойдите как администратор и добавьте путь к игре.", "ЭПОХА", MessageBoxButtons.OK, MessageBoxIcon.Information); return; }
            try { ProcessStartInfo psi = new ProcessStartInfo(g.ExePath, g.Arguments == null ? "" : g.Arguments); psi.WorkingDirectory = !String.IsNullOrEmpty(g.WorkingDirectory) ? g.WorkingDirectory : Path.GetDirectoryName(g.ExePath); Process.Start(psi); }
            catch (Exception ex) { MessageBox.Show("Не удалось запустить игру:\r\n" + ex.Message, "ЭПОХА", MessageBoxButtons.OK, MessageBoxIcon.Error); }
        }

        private void AdminClicked(object sender, EventArgs e)
        {
            if (!adminMode)
            {
                string pass = Prompt.Show("Введите пароль администратора", "Вход администратора", true, ""); if (pass == null) return; if (pass != config.AdminPassword) { MessageBox.Show("Неверный пароль", "ЭПОХА", MessageBoxButtons.OK, MessageBoxIcon.Warning); return; }
                adminMode = true; blocker.Enabled = false;
            }
            using (AdminForm af = new AdminForm(config, this)) af.ShowDialog(this);
            adminMode = false; ApplyRestrictions(config.KioskRestrictions); RebuildCategories(); RebuildGames(); UpdateClock();
        }

        public void SaveAndRefresh() { ConfigStore.Save(config); pcLabel.Text = config.PcLabel; RebuildCategories(); RebuildGames(); UpdateClock(); }

        public void ApplyRestrictions(bool enable)
        {
            config.KioskRestrictions = enable; ConfigStore.Save(config); if (blocker == null) blocker = new KeyboardBlocker(); blocker.Enabled = enable && !adminMode;
            try { RegistryKey key = Registry.CurrentUser.CreateSubKey(@"Software\Microsoft\Windows\CurrentVersion\Policies\System"); if (enable) key.SetValue("DisableTaskMgr", 1, RegistryValueKind.DWord); else key.DeleteValue("DisableTaskMgr", false); key.Close(); } catch { }
            UpdateClock();
        }

        public void LaunchExplorerMaintenance() { try { Process.Start("explorer.exe"); Hide(); } catch (Exception ex) { MessageBox.Show(ex.Message); } }

        public void SetAsShell(bool enable)
        {
            try
            {
                RegistryKey key = Registry.CurrentUser.CreateSubKey(@"Software\Microsoft\Windows NT\CurrentVersion\Winlogon"); if (enable) key.SetValue("Shell", Application.ExecutablePath, RegistryValueKind.String); else key.SetValue("Shell", "explorer.exe", RegistryValueKind.String); key.Close();
                MessageBox.Show(enable ? "ЭПОХА назначена оболочкой текущего пользователя. Изменение вступит в силу при следующем входе." : "Обычная оболочка Windows восстановлена для текущего пользователя.", "ЭПОХА");
            }
            catch (Exception ex) { MessageBox.Show("Не удалось изменить оболочку:\r\n" + ex.Message, "ЭПОХА", MessageBoxButtons.OK, MessageBoxIcon.Error); }
        }

        private void RestartClicked(object sender, EventArgs e) { if (MessageBox.Show("Перезагрузить компьютер?", "ЭПОХА", MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes) Process.Start(new ProcessStartInfo("shutdown.exe", "/r /t 0") { CreateNoWindow = true, UseShellExecute = false }); }
        private void ShutdownClicked(object sender, EventArgs e) { if (MessageBox.Show("Выключить компьютер?", "ЭПОХА", MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes) Process.Start(new ProcessStartInfo("shutdown.exe", "/s /t 0") { CreateNoWindow = true, UseShellExecute = false }); }
        private void MainForm_FormClosing(object sender, FormClosingEventArgs e) { if (!allowClose && config.KioskRestrictions) { e.Cancel = true; return; } if (blocker != null) blocker.Dispose(); }
        private void MainForm_KeyDown(object sender, KeyEventArgs e) { if (e.Control && e.Alt && e.KeyCode == Keys.E) { AdminClicked(this, EventArgs.Empty); e.SuppressKeyPress = true; } }
        public void ExitShell() { allowClose = true; Close(); }
        private void EditGame(GameItem g) { using (GameEditForm f = new GameEditForm(g)) { if (f.ShowDialog(this) == DialogResult.OK) { ConfigStore.Save(config); RebuildGames(); } } }
        private void DeleteGame(GameItem g) { if (MessageBox.Show("Удалить ярлык \"" + g.Name + "\"?", "ЭПОХА", MessageBoxButtons.YesNo) == DialogResult.Yes) { config.Games.Remove(g); ConfigStore.Save(config); RebuildGames(); } }
    }

    public class AdminForm : Form
    {
        private ShellConfig config; private MainForm main; private ListBox categories; private ListBox games; private TextBox pcText; private CheckBox kiosk;
        public AdminForm(ShellConfig c, MainForm m) { config = c; main = m; Text = "ЭПОХА — Администратор"; StartPosition = FormStartPosition.CenterParent; Size = new Size(820, 540); MinimumSize = new Size(760, 500); BackColor = Color.FromArgb(28, 31, 38); ForeColor = Color.White; Build(); ReloadLists(); }
        private Button Btn(string text, int x, int y, int w, EventHandler h) { Button b = new Button(); b.Text = text; b.SetBounds(x, y, w, 34); b.FlatStyle = FlatStyle.Flat; b.BackColor = Color.FromArgb(45, 49, 59); b.ForeColor = Color.White; b.Click += h; Controls.Add(b); return b; }
        private void Build()
        {
            Label l1 = new Label(); l1.Text = "Вкладки"; l1.SetBounds(20, 18, 200, 24); l1.Font = new Font("Segoe UI", 11, FontStyle.Bold); Controls.Add(l1); categories = new ListBox(); categories.SetBounds(20, 48, 230, 285); categories.SelectedIndexChanged += delegate { ReloadGames(); }; Controls.Add(categories); Btn("Добавить", 20, 345, 72, AddCategory); Btn("Переименовать", 98, 345, 105, RenameCategory); Btn("Удалить", 209, 345, 70, DeleteCategory);
            Label l2 = new Label(); l2.Text = "Ярлыки выбранной вкладки"; l2.SetBounds(300, 18, 260, 24); l2.Font = new Font("Segoe UI", 11, FontStyle.Bold); Controls.Add(l2); games = new ListBox(); games.SetBounds(300, 48, 280, 285); Controls.Add(games); Btn("Добавить игру", 300, 345, 105, AddGame); Btn("Изменить", 411, 345, 82, EditGame); Btn("Удалить", 499, 345, 82, DeleteGame);
            Label sys = new Label(); sys.Text = "Компьютер / клубный режим"; sys.SetBounds(610, 18, 190, 24); sys.Font = new Font("Segoe UI", 10, FontStyle.Bold); Controls.Add(sys); Label pl = new Label(); pl.Text = "Подпись ПК:"; pl.SetBounds(610, 55, 170, 22); Controls.Add(pl); pcText = new TextBox(); pcText.Text = config.PcLabel; pcText.SetBounds(610, 78, 165, 26); Controls.Add(pcText); kiosk = new CheckBox(); kiosk.Text = "Клубные ограничения"; kiosk.Checked = config.KioskRestrictions; kiosk.SetBounds(610, 120, 180, 26); kiosk.ForeColor = Color.White; Controls.Add(kiosk);
            Btn("Сохранить", 610, 155, 165, SaveSettings); Btn("Сменить пароль", 610, 198, 165, ChangePassword); Btn("Открыть Explorer", 610, 241, 165, ExplorerMode); Btn("Сделать ЭПОХУ shell", 610, 284, 165, SetShell); Btn("Вернуть Explorer shell", 610, 327, 165, RestoreShell); Btn("Закрыть ЭПОХУ", 610, 370, 165, ExitShell);
            Label hint = new Label(); hint.Text = "Аварийный вход: Ctrl+Alt+E\r\nCtrl+Alt+Del Windows не блокируется, но Task Manager можно отключить политикой."; hint.SetBounds(20, 405, 550, 55); hint.ForeColor = Color.Silver; Controls.Add(hint);
        }
        private void ReloadLists() { categories.Items.Clear(); List<CategoryItem> list = new List<CategoryItem>(config.Categories); list.Sort(delegate(CategoryItem a, CategoryItem b) { return a.Sort.CompareTo(b.Sort); }); foreach (CategoryItem c in list) categories.Items.Add(c); if (categories.Items.Count > 0) categories.SelectedIndex = 0; ReloadGames(); }
        private void ReloadGames() { games.Items.Clear(); CategoryItem cat = categories.SelectedItem as CategoryItem; if (cat == null) return; List<GameItem> list = new List<GameItem>(); foreach (GameItem g in config.Games) if (cat.Id == "all" || g.CategoryId == cat.Id) list.Add(g); list.Sort(delegate(GameItem a, GameItem b) { return a.Sort.CompareTo(b.Sort); }); foreach (GameItem g in list) games.Items.Add(g); }
        private void AddCategory(object s, EventArgs e) { string name = Prompt.Show("Название новой вкладки", "ЭПОХА", false, "НОВАЯ ВКЛАДКА"); if (String.IsNullOrEmpty(name)) return; CategoryItem c = new CategoryItem(); c.Name = name.Trim(); c.Sort = config.Categories.Count * 10; config.Categories.Add(c); ConfigStore.Save(config); ReloadLists(); }
        private void RenameCategory(object s, EventArgs e) { CategoryItem c = categories.SelectedItem as CategoryItem; if (c == null || c.Id == "all") return; string name = Prompt.Show("Новое название", "ЭПОХА", false, c.Name); if (String.IsNullOrEmpty(name)) return; c.Name = name.Trim(); ConfigStore.Save(config); ReloadLists(); }
        private void DeleteCategory(object s, EventArgs e) { CategoryItem c = categories.SelectedItem as CategoryItem; if (c == null || c.Id == "all") return; if (MessageBox.Show("Удалить вкладку и её ярлыки?", "ЭПОХА", MessageBoxButtons.YesNo) != DialogResult.Yes) return; config.Games.RemoveAll(delegate(GameItem g) { return g.CategoryId == c.Id; }); config.Categories.Remove(c); ConfigStore.Save(config); ReloadLists(); }
        private void AddGame(object s, EventArgs e) { CategoryItem c = categories.SelectedItem as CategoryItem; if (c == null) return; if (c.Id == "all") { MessageBox.Show("Выберите конкретную вкладку слева."); return; } GameItem g = new GameItem(); g.CategoryId = c.Id; g.Sort = config.Games.Count * 10; using (GameEditForm f = new GameEditForm(g)) if (f.ShowDialog(this) == DialogResult.OK) { config.Games.Add(g); ConfigStore.Save(config); ReloadGames(); } }
        private void EditGame(object s, EventArgs e) { GameItem g = games.SelectedItem as GameItem; if (g == null) return; using (GameEditForm f = new GameEditForm(g)) if (f.ShowDialog(this) == DialogResult.OK) { ConfigStore.Save(config); ReloadGames(); } }
        private void DeleteGame(object s, EventArgs e) { GameItem g = games.SelectedItem as GameItem; if (g == null) return; if (MessageBox.Show("Удалить ярлык?", "ЭПОХА", MessageBoxButtons.YesNo) != DialogResult.Yes) return; config.Games.Remove(g); ConfigStore.Save(config); ReloadGames(); }
        private void SaveSettings(object s, EventArgs e) { config.PcLabel = String.IsNullOrEmpty(pcText.Text) ? "ПК" : pcText.Text.Trim(); config.KioskRestrictions = kiosk.Checked; ConfigStore.Save(config); main.ApplyRestrictions(config.KioskRestrictions); main.SaveAndRefresh(); MessageBox.Show("Настройки сохранены.", "ЭПОХА"); }
        private void ChangePassword(object s, EventArgs e) { string p = Prompt.Show("Новый пароль администратора", "ЭПОХА", true, ""); if (String.IsNullOrEmpty(p)) return; config.AdminPassword = p; ConfigStore.Save(config); MessageBox.Show("Пароль изменён."); }
        private void ExplorerMode(object s, EventArgs e) { main.ApplyRestrictions(false); main.LaunchExplorerMaintenance(); Close(); }
        private void SetShell(object s, EventArgs e) { main.SetAsShell(true); }
        private void RestoreShell(object s, EventArgs e) { main.SetAsShell(false); }
        private void ExitShell(object s, EventArgs e) { main.ApplyRestrictions(false); main.SetAsShell(false); main.ExitShell(); Close(); }
    }

    public class GameEditForm : Form
    {
        private GameItem game; private TextBox name, exe, args, work, image;
        public GameEditForm(GameItem g)
        {
            game = g; Text = "Ярлык игры — ЭПОХА"; StartPosition = FormStartPosition.CenterParent; Size = new Size(650, 390); BackColor = Color.FromArgb(30, 33, 40); ForeColor = Color.White;
            MakeLabel("Название", 20, 22); name = MakeText(g.Name, 150, 18, 430); MakeLabel("EXE", 20, 66); exe = MakeText(g.ExePath, 150, 62, 350); Button be = MakeButton("Обзор", 510, 61); be.Click += BrowseExe; MakeLabel("Параметры", 20, 110); args = MakeText(g.Arguments, 150, 106, 430); MakeLabel("Рабочая папка", 20, 154); work = MakeText(g.WorkingDirectory, 150, 150, 430); MakeLabel("Картинка", 20, 198); image = MakeText(g.ImagePath, 150, 194, 350); Button bi = MakeButton("Обзор", 510, 193); bi.Click += BrowseImage; Button ok = MakeButton("Сохранить", 390, 280); ok.Width = 100; ok.Click += Save; Button cancel = MakeButton("Отмена", 500, 280); cancel.Width = 80; cancel.Click += delegate { DialogResult = DialogResult.Cancel; Close(); };
        }
        private void MakeLabel(string t, int x, int y) { Label l = new Label(); l.Text = t; l.SetBounds(x, y, 120, 24); Controls.Add(l); }
        private TextBox MakeText(string t, int x, int y, int w) { TextBox b = new TextBox(); b.Text = t == null ? "" : t; b.SetBounds(x, y, w, 26); Controls.Add(b); return b; }
        private Button MakeButton(string t, int x, int y) { Button b = new Button(); b.Text = t; b.SetBounds(x, y, 70, 30); Controls.Add(b); return b; }
        private void BrowseExe(object s, EventArgs e) { OpenFileDialog d = new OpenFileDialog(); d.Filter = "Программы (*.exe)|*.exe|Все файлы|*.*"; if (d.ShowDialog(this) == DialogResult.OK) { exe.Text = d.FileName; if (String.IsNullOrEmpty(work.Text)) work.Text = Path.GetDirectoryName(d.FileName); } }
        private void BrowseImage(object s, EventArgs e) { OpenFileDialog d = new OpenFileDialog(); d.Filter = "Изображения|*.png;*.jpg;*.jpeg;*.bmp;*.gif|Все файлы|*.*"; if (d.ShowDialog(this) == DialogResult.OK) image.Text = d.FileName; }
        private void Save(object s, EventArgs e) { if (String.IsNullOrEmpty(name.Text.Trim())) { MessageBox.Show("Введите название."); return; } game.Name = name.Text.Trim(); game.ExePath = exe.Text.Trim(); game.Arguments = args.Text.Trim(); game.WorkingDirectory = work.Text.Trim(); game.ImagePath = image.Text.Trim(); DialogResult = DialogResult.OK; Close(); }
    }

    public static class Prompt
    {
        public static string Show(string text, string caption, bool password, string value)
        {
            Form f = new Form(); f.Text = caption; f.Width = 430; f.Height = 165; f.StartPosition = FormStartPosition.CenterParent; f.FormBorderStyle = FormBorderStyle.FixedDialog; f.MinimizeBox = false; f.MaximizeBox = false; Label l = new Label(); l.Text = text; l.SetBounds(15, 15, 385, 22); f.Controls.Add(l); TextBox tb = new TextBox(); tb.Text = value == null ? "" : value; tb.SetBounds(15, 42, 385, 25); if (password) tb.UseSystemPasswordChar = true; f.Controls.Add(tb); Button ok = new Button(); ok.Text = "OK"; ok.DialogResult = DialogResult.OK; ok.SetBounds(245, 78, 75, 30); f.Controls.Add(ok); Button cancel = new Button(); cancel.Text = "Отмена"; cancel.DialogResult = DialogResult.Cancel; cancel.SetBounds(325, 78, 75, 30); f.Controls.Add(cancel); f.AcceptButton = ok; f.CancelButton = cancel; return f.ShowDialog() == DialogResult.OK ? tb.Text : null;
        }
    }

    public class KeyboardBlocker : IDisposable
    {
        private const int WH_KEYBOARD_LL = 13; private const int WM_KEYDOWN = 0x0100; private const int WM_SYSKEYDOWN = 0x0104; private IntPtr hook = IntPtr.Zero; private LowLevelKeyboardProc proc; public bool Enabled = false;
        public KeyboardBlocker() { proc = HookCallback; try { hook = SetWindowsHookEx(WH_KEYBOARD_LL, proc, GetModuleHandle(null), 0); } catch { } }
        private IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam)
        {
            if (nCode >= 0 && Enabled && (wParam == (IntPtr)WM_KEYDOWN || wParam == (IntPtr)WM_SYSKEYDOWN))
            {
                KBDLLHOOKSTRUCT k = (KBDLLHOOKSTRUCT)Marshal.PtrToStructure(lParam, typeof(KBDLLHOOKSTRUCT)); Keys key = (Keys)k.vkCode; bool alt = (Control.ModifierKeys & Keys.Alt) == Keys.Alt; bool ctrl = (Control.ModifierKeys & Keys.Control) == Keys.Control;
                if (key == Keys.LWin || key == Keys.RWin || (alt && key == Keys.Tab) || (alt && key == Keys.F4) || (ctrl && key == Keys.Escape)) return (IntPtr)1;
            }
            return CallNextHookEx(hook, nCode, wParam, lParam);
        }
        public void Dispose() { if (hook != IntPtr.Zero) { UnhookWindowsHookEx(hook); hook = IntPtr.Zero; } }
        private delegate IntPtr LowLevelKeyboardProc(int nCode, IntPtr wParam, IntPtr lParam);
        [StructLayout(LayoutKind.Sequential)] private struct KBDLLHOOKSTRUCT { public uint vkCode, scanCode, flags, time; public IntPtr dwExtraInfo; }
        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)] private static extern IntPtr SetWindowsHookEx(int idHook, LowLevelKeyboardProc lpfn, IntPtr hMod, uint dwThreadId);
        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)] private static extern bool UnhookWindowsHookEx(IntPtr hhk);
        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)] private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);
        [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)] private static extern IntPtr GetModuleHandle(string lpModuleName);
    }
}
