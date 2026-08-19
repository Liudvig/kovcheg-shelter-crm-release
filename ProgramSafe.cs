using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Windows.Forms;

namespace EpohaShellSafe
{
    public static class Program
    {
        public static string LogPath = Path.Combine(Path.GetTempPath(), "EpohaShell-0.1.3.log");

        [STAThread]
        public static void Main()
        {
            try
            {
                File.AppendAllText(LogPath, "\r\n--- START " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + " ---\r\n");
                File.AppendAllText(LogPath, "OS=" + Environment.OSVersion + " CLR=" + Environment.Version + " Machine=" + Environment.MachineName + "\r\n");
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

    public class Category
    {
        public string Name;
        public Category(string name) { Name = name; }
        public override string ToString() { return Name; }
    }

    public class Game
    {
        public string Name;
        public string Category;
        public string Exe;
        public Game(string name, string category) { Name = name; Category = category; Exe = ""; }
        public override string ToString() { return Name; }
    }

    public class MainForm : Form
    {
        private readonly Color Bg = Color.FromArgb(16, 18, 23);
        private readonly Color PanelBg = Color.FromArgb(24, 27, 34);
        private readonly Color PanelBg2 = Color.FromArgb(29, 33, 41);
        private readonly Color CardBg = Color.FromArgb(35, 39, 48);
        private readonly Color CardHover = Color.FromArgb(46, 51, 62);
        private readonly Color Accent = Color.FromArgb(219, 142, 40);
        private readonly Color MainText = Color.FromArgb(238, 238, 238);
        private readonly Color Muted = Color.FromArgb(160, 165, 175);

        private Panel sidebar;
        private Panel brandPanel;
        private FlowLayoutPanel menu;
        private Panel rightRoot;
        private Panel header;
        private Panel body;
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

        private List<Category> categories = new List<Category>();
        private List<Game> games = new List<Game>();
        private string selected = "ВСЕ ИГРЫ";
        private bool admin = false;

        public MainForm()
        {
            Text = "ЭПОХА — КОМПЬЮТЕРНЫЙ КЛУБ";
            BackColor = Bg;
            ForeColor = MainText;
            FormBorderStyle = FormBorderStyle.None;
            WindowState = FormWindowState.Maximized;
            StartPosition = FormStartPosition.CenterScreen;
            KeyPreview = true;
            MinimumSize = new Size(900, 650);

            InitData();
            BuildUi();

            timer = new Timer();
            timer.Interval = 1000;
            timer.Tick += delegate { UpdateClock(); };
            timer.Start();

            Resize += delegate { AdaptiveLayout(); };
            Shown += delegate { AdaptiveLayout(); };
            KeyDown += MainForm_KeyDown;

            UpdateClock();
            File.AppendAllText(Program.LogPath, "MainForm shown successfully\r\n");
        }

        private void InitData()
        {
            categories.Add(new Category("ВСЕ ИГРЫ"));
            categories.Add(new Category("ШУТЕРЫ"));
            categories.Add(new Category("ЭКШЕН"));
            categories.Add(new Category("СТРАТЕГИИ"));
            categories.Add(new Category("RPG"));

            games.Add(new Game("Counter-Strike 1.6", "ШУТЕРЫ"));
            games.Add(new Game("S.T.A.L.K.E.R.", "ШУТЕРЫ"));
            games.Add(new Game("Unreal Tournament", "ШУТЕРЫ"));
            games.Add(new Game("GTA San Andreas", "ЭКШЕН"));
            games.Add(new Game("Assassin's Creed", "ЭКШЕН"));
            games.Add(new Game("Warcraft III", "СТРАТЕГИИ"));
            games.Add(new Game("Diablo II", "RPG"));
        }

        private Font F(float size, FontStyle style)
        {
            return new Font("Tahoma", size, style);
        }

        private void BuildUi()
        {
            rightRoot = new Panel();
            rightRoot.Dock = DockStyle.Fill;
            rightRoot.BackColor = Bg;
            Controls.Add(rightRoot);

            sidebar = new Panel();
            sidebar.Dock = DockStyle.Left;
            sidebar.Width = 250;
            sidebar.BackColor = PanelBg;
            Controls.Add(sidebar);
            sidebar.BringToFront();

            brandPanel = new Panel();
            brandPanel.Dock = DockStyle.Top;
            brandPanel.Height = 118;
            brandPanel.BackColor = Color.FromArgb(20, 23, 29);
            sidebar.Controls.Add(brandPanel);

            brandLogo = new Label();
            brandLogo.Text = "Э";
            brandLogo.TextAlign = ContentAlignment.MiddleCenter;
            brandLogo.BackColor = Accent;
            brandLogo.ForeColor = Color.FromArgb(18, 19, 22);
            brandLogo.Font = F(24, FontStyle.Bold);
            brandLogo.SetBounds(14, 18, 48, 48);
            brandPanel.Controls.Add(brandLogo);

            brandTitle = new Label();
            brandTitle.Text = "ЭПОХА";
            brandTitle.AutoSize = true;
            brandTitle.ForeColor = Accent;
            brandTitle.Font = F(18, FontStyle.Bold);
            brandTitle.Location = new Point(74, 17);
            brandPanel.Controls.Add(brandTitle);

            brandSub = new Label();
            brandSub.Text = "КОМПЬЮТЕРНЫЙ КЛУБ";
            brandSub.AutoSize = true;
            brandSub.ForeColor = MainText;
            brandSub.Font = F(8, FontStyle.Bold);
            brandSub.Location = new Point(75, 48);
            brandPanel.Controls.Add(brandSub);

            brandYears = new Label();
            brandYears.Text = "2000—2015";
            brandYears.AutoSize = true;
            brandYears.ForeColor = Muted;
            brandYears.Font = F(8, FontStyle.Regular);
            brandYears.Location = new Point(75, 70);
            brandPanel.Controls.Add(brandYears);

            menu = new FlowLayoutPanel();
            menu.Dock = DockStyle.Fill;
            menu.FlowDirection = FlowDirection.TopDown;
            menu.WrapContents = false;
            menu.AutoScroll = true;
            menu.Padding = new Padding(10, 14, 10, 10);
            menu.BackColor = PanelBg;
            sidebar.Controls.Add(menu);
            menu.BringToFront();

            header = new Panel();
            header.Dock = DockStyle.Top;
            header.Height = 92;
            header.BackColor = PanelBg2;
            rightRoot.Controls.Add(header);

            clock = new Label();
            clock.Text = "00:00";
            clock.AutoSize = true;
            clock.ForeColor = MainText;
            clock.Font = F(28, FontStyle.Bold);
            header.Controls.Add(clock);

            pc = new Label();
            pc.Text = "ПК №01";
            pc.AutoSize = true;
            pc.ForeColor = Muted;
            pc.Font = F(8, FontStyle.Regular);
            header.Controls.Add(pc);

            restartButton = HeaderButton("ПЕРЕЗАГРУЗИТЬ", RestartClick);
            shutdownButton = HeaderButton("ВЫКЛЮЧИТЬ", ShutdownClick);
            header.Controls.Add(restartButton);
            header.Controls.Add(shutdownButton);

            Panel bottom = new Panel();
            bottom.Dock = DockStyle.Bottom;
            bottom.Height = 34;
            bottom.BackColor = PanelBg2;
            rightRoot.Controls.Add(bottom);

            footer = new Label();
            footer.Dock = DockStyle.Fill;
            footer.TextAlign = ContentAlignment.MiddleLeft;
            footer.Padding = new Padding(16, 0, 0, 0);
            footer.ForeColor = Muted;
            footer.Font = F(8, FontStyle.Regular);
            bottom.Controls.Add(footer);

            body = new Panel();
            body.Dock = DockStyle.Fill;
            body.BackColor = Bg;
            rightRoot.Controls.Add(body);
            body.BringToFront();

            RebuildMenu();
            RebuildBody();
            AdaptiveLayout();
        }

        private Button HeaderButton(string text, EventHandler handler)
        {
            Button b = new Button();
            b.Text = text;
            b.FlatStyle = FlatStyle.Flat;
            b.FlatAppearance.BorderColor = Color.FromArgb(72, 77, 88);
            b.BackColor = CardBg;
            b.ForeColor = MainText;
            b.Font = F(8, FontStyle.Bold);
            b.Height = 34;
            b.Click += handler;
            return b;
        }

        private Button MenuButton(string text, string key)
        {
            Button b = new Button();
            b.Text = text;
            b.Tag = key;
            b.Height = 48;
            b.FlatStyle = FlatStyle.Flat;
            b.FlatAppearance.BorderSize = 0;
            b.TextAlign = ContentAlignment.MiddleLeft;
            b.Padding = new Padding(14, 0, 0, 0);
            b.Font = F(10, FontStyle.Bold);
            b.ForeColor = key == selected ? Accent : MainText;
            b.BackColor = key == selected ? Color.FromArgb(42, 46, 56) : PanelBg;
            b.Click += MenuClick;
            return b;
        }

        private void RebuildMenu()
        {
            menu.Controls.Clear();

            foreach (Category cat in categories)
                menu.Controls.Add(MenuButton(cat.Name, cat.Name));

            Button adminButton = MenuButton("АДМИНИСТРАТОР", "__ADMIN__");
            adminButton.Margin = new Padding(0, 18, 0, 0);
            menu.Controls.Add(adminButton);

            AdaptiveLayout();
        }

        private void MenuClick(object sender, EventArgs e)
        {
            Button b = sender as Button;
            if (b == null) return;
            selected = b.Tag.ToString();
            RebuildMenu();
            RebuildBody();
        }

        private void RebuildBody()
        {
            body.Controls.Clear();

            if (selected == "__ADMIN__")
            {
                BuildAdminPage();
                AdaptiveLayout();
                return;
            }

            grid = new FlowLayoutPanel();
            grid.Dock = DockStyle.Fill;
            grid.AutoScroll = true;
            grid.WrapContents = true;
            grid.Padding = new Padding(16);
            grid.BackColor = Bg;
            body.Controls.Add(grid);

            foreach (Game g in games)
            {
                if (selected != "ВСЕ ИГРЫ" && g.Category != selected) continue;
                grid.Controls.Add(CreateGameCard(g));
            }

            AdaptiveLayout();
        }

        private Control CreateGameCard(Game g)
        {
            Panel card = new Panel();
            card.BackColor = CardBg;
            card.Cursor = Cursors.Hand;

            Label icon = new Label();
            icon.Dock = DockStyle.Fill;
            icon.Text = "▶";
            icon.TextAlign = ContentAlignment.MiddleCenter;
            icon.ForeColor = Accent;
            icon.Font = F(28, FontStyle.Bold);
            icon.BackColor = Color.FromArgb(28, 31, 38);

            Label name = new Label();
            name.Dock = DockStyle.Bottom;
            name.Height = 40;
            name.Text = g.Name;
            name.TextAlign = ContentAlignment.MiddleCenter;
            name.ForeColor = MainText;
            name.BackColor = Color.FromArgb(22, 25, 31);
            name.Font = F(9, FontStyle.Bold);

            EventHandler launch = delegate { Launch(g); };
            card.Click += launch;
            icon.Click += launch;
            name.Click += launch;

            card.MouseEnter += delegate { card.BackColor = CardHover; };
            card.MouseLeave += delegate { card.BackColor = CardBg; };

            card.Controls.Add(icon);
            card.Controls.Add(name);
            return card;
        }

        private void BuildAdminPage()
        {
            Panel center = new Panel();
            center.BackColor = PanelBg2;
            center.Size = new Size(460, 280);
            center.Tag = "adminCenter";
            body.Controls.Add(center);

            Label icon = new Label();
            icon.Text = "⚙";
            icon.AutoSize = false;
            icon.SetBounds(190, 24, 80, 58);
            icon.TextAlign = ContentAlignment.MiddleCenter;
            icon.ForeColor = Accent;
            icon.Font = F(28, FontStyle.Bold);
            center.Controls.Add(icon);

            Label title = new Label();
            title.Text = "АДМИНИСТРАТОР";
            title.AutoSize = false;
            title.SetBounds(20, 88, 420, 34);
            title.TextAlign = ContentAlignment.MiddleCenter;
            title.ForeColor = MainText;
            title.Font = F(15, FontStyle.Bold);
            center.Controls.Add(title);

            Label hint = new Label();
            hint.AutoSize = false;
            hint.SetBounds(30, 126, 400, 42);
            hint.TextAlign = ContentAlignment.MiddleCenter;
            hint.ForeColor = Muted;
            hint.Font = F(8, FontStyle.Regular);
            hint.Text = admin ? "Администратор уже вошёл в систему." : "Для изменения настроек клуба войдите с паролем администратора.";
            center.Controls.Add(hint);

            Button login = new Button();
            login.SetBounds(130, 188, 200, 48);
            login.FlatStyle = FlatStyle.Flat;
            login.FlatAppearance.BorderColor = Accent;
            login.BackColor = admin ? Color.FromArgb(54, 58, 68) : Accent;
            login.ForeColor = admin ? MainText : Color.FromArgb(20, 20, 22);
            login.Font = F(11, FontStyle.Bold);
            login.Text = admin ? "ВЫЙТИ" : "ВОЙТИ";
            login.Click += admin ? new EventHandler(AdminLogoutClick) : new EventHandler(AdminLoginClick);
            center.Controls.Add(login);
        }

        private void AdminLoginClick(object sender, EventArgs e)
        {
            string pass = AskPassword();
            if (pass == null) return;
            if (pass != "2000")
            {
                MessageBox.Show("Неверный пароль", "ЭПОХА", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }
            admin = true;
            RebuildBody();
            MessageBox.Show("Вход выполнен. В следующем этапе сюда добавим полноценные настройки вкладок, игр и клубного режима.", "ЭПОХА — Администратор");
        }

        private void AdminLogoutClick(object sender, EventArgs e)
        {
            admin = false;
            RebuildBody();
        }

        private string AskPassword()
        {
            Form f = new Form();
            f.Text = "ЭПОХА — Вход администратора";
            f.StartPosition = FormStartPosition.CenterScreen;
            f.FormBorderStyle = FormBorderStyle.FixedDialog;
            f.Width = 390;
            f.Height = 155;
            f.MaximizeBox = false;
            f.MinimizeBox = false;
            f.Font = F(9, FontStyle.Regular);

            Label l = new Label();
            l.Text = "Пароль администратора:";
            l.SetBounds(14, 14, 340, 22);
            f.Controls.Add(l);

            TextBox t = new TextBox();
            t.UseSystemPasswordChar = true;
            t.SetBounds(14, 40, 345, 25);
            f.Controls.Add(t);

            Button ok = new Button();
            ok.Text = "Войти";
            ok.DialogResult = DialogResult.OK;
            ok.SetBounds(200, 76, 75, 30);
            f.Controls.Add(ok);

            Button cancel = new Button();
            cancel.Text = "Отмена";
            cancel.DialogResult = DialogResult.Cancel;
            cancel.SetBounds(284, 76, 75, 30);
            f.Controls.Add(cancel);

            f.AcceptButton = ok;
            f.CancelButton = cancel;
            return f.ShowDialog() == DialogResult.OK ? t.Text : null;
        }

        private void Launch(Game g)
        {
            if (String.IsNullOrEmpty(g.Exe))
            {
                MessageBox.Show("Ярлык «" + g.Name + "» пока тестовый. Путь к игре добавим через админку.", "ЭПОХА");
                return;
            }
            try { Process.Start(g.Exe); }
            catch (Exception ex) { MessageBox.Show(ex.Message, "Ошибка запуска"); }
        }

        private void UpdateClock()
        {
            clock.Text = DateTime.Now.ToString("HH:mm:ss");
            footer.Text = "ЭПОХА 0.1.3  •  ПК №01  •  " + Environment.MachineName + "  •  тестовый режим";
            AdaptiveHeaderOnly();
        }

        private void AdaptiveLayout()
        {
            if (ClientSize.Width < 500) return;

            int w = ClientSize.Width;
            int h = ClientSize.Height;
            int sidebarWidth = Math.Max(230, Math.Min(320, (int)(w * 0.18)));
            sidebar.Width = sidebarWidth;
            brandPanel.Height = h < 800 ? 104 : 118;

            foreach (Control c in menu.Controls)
                c.Width = sidebarWidth - 24;

            if (sidebarWidth < 250)
            {
                brandLogo.SetBounds(12, 18, 42, 42);
                brandTitle.Font = F(15, FontStyle.Bold);
                brandTitle.Location = new Point(64, 17);
                brandSub.Font = F(7, FontStyle.Bold);
                brandSub.Location = new Point(65, 45);
                brandYears.Location = new Point(65, 66);
            }
            else
            {
                brandLogo.SetBounds(14, 18, 48, 48);
                brandTitle.Font = F(18, FontStyle.Bold);
                brandTitle.Location = new Point(74, 17);
                brandSub.Font = F(8, FontStyle.Bold);
                brandSub.Location = new Point(75, 48);
                brandYears.Location = new Point(75, 70);
            }

            header.Height = h < 800 ? 78 : 92;
            AdaptiveHeaderOnly();

            if (selected == "__ADMIN__")
            {
                foreach (Control c in body.Controls)
                {
                    if (c.Tag != null && c.Tag.ToString() == "adminCenter")
                    {
                        c.Left = Math.Max(20, (body.ClientSize.Width - c.Width) / 2);
                        c.Top = Math.Max(20, (body.ClientSize.Height - c.Height) / 2);
                    }
                }
                return;
            }

            if (grid == null) return;
            int available = Math.Max(480, body.ClientSize.Width - 32);
            int minCard = w < 1100 ? 140 : 160;
            int maxCard = w > 1900 ? 220 : 200;
            int columns = Math.Max(3, available / (minCard + 16));
            int cw = Math.Max(minCard, Math.Min(maxCard, (available - columns * 16) / columns));
            int ch = Math.Max(102, (int)(cw * 0.68));

            foreach (Control c in grid.Controls)
            {
                c.Width = cw;
                c.Height = ch;
                c.Margin = new Padding(8);
            }
        }

        private void AdaptiveHeaderOnly()
        {
            if (rightRoot == null || header == null || clock == null) return;
            int w = rightRoot.ClientSize.Width;
            if (w <= 0) return;

            clock.Left = Math.Max(10, (w - clock.PreferredWidth) / 2);
            clock.Top = header.Height < 85 ? 8 : 10;
            pc.Left = Math.Max(10, (w - pc.PreferredWidth) / 2);
            pc.Top = clock.Bottom + 1;

            int buttonWidth = w < 800 ? 105 : 130;
            shutdownButton.Width = buttonWidth;
            restartButton.Width = buttonWidth + 18;
            shutdownButton.Left = w - shutdownButton.Width - 14;
            shutdownButton.Top = (header.Height - shutdownButton.Height) / 2;
            restartButton.Left = shutdownButton.Left - restartButton.Width - 8;
            restartButton.Top = shutdownButton.Top;
        }

        private void RestartClick(object sender, EventArgs e)
        {
            if (MessageBox.Show("Перезагрузить компьютер?", "ЭПОХА", MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes)
                Process.Start(new ProcessStartInfo("shutdown.exe", "/r /t 0") { UseShellExecute = false, CreateNoWindow = true });
        }

        private void ShutdownClick(object sender, EventArgs e)
        {
            if (MessageBox.Show("Выключить компьютер?", "ЭПОХА", MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes)
                Process.Start(new ProcessStartInfo("shutdown.exe", "/s /t 0") { UseShellExecute = false, CreateNoWindow = true });
        }

        private void MainForm_KeyDown(object sender, KeyEventArgs e)
        {
            if (e.Control && e.Alt && e.KeyCode == Keys.E)
            {
                selected = "__ADMIN__";
                RebuildMenu();
                RebuildBody();
                string pass = AskPassword();
                if (pass == "2000") { admin = true; RebuildBody(); }
                else if (pass != null) MessageBox.Show("Неверный пароль", "ЭПОХА");
                e.SuppressKeyPress = true;
            }
        }
    }
}
