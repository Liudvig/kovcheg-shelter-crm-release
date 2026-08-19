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
        public static string LogPath = Path.Combine(Path.GetTempPath(), "EpohaShell-0.1.1.log");

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
        private readonly Color CardBg = Color.FromArgb(34, 38, 47);
        private readonly Color Accent = Color.FromArgb(217, 139, 40);
        private readonly Color MainText = Color.FromArgb(238, 238, 238);
        private readonly Color Muted = Color.FromArgb(160, 165, 175);

        private Panel header;
        private FlowLayoutPanel menu;
        private FlowLayoutPanel grid;
        private Label clock;
        private Label pc;
        private Label title;
        private Label subtitle;
        private Label years;
        private Label footer;
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
            InitData();
            BuildUi();
            timer = new Timer(); timer.Interval = 1000; timer.Tick += delegate { UpdateClock(); }; timer.Start();
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

        private void BuildUi()
        {
            header = new Panel(); header.Dock = DockStyle.Top; header.Height = 112; header.BackColor = PanelBg; Controls.Add(header);
            title = LabelOf("ЭПОХА", 28, FontStyle.Bold, Accent); header.Controls.Add(title);
            subtitle = LabelOf("КОМПЬЮТЕРНЫЙ КЛУБ", 11, FontStyle.Bold, MainText); header.Controls.Add(subtitle);
            years = LabelOf("2000—2015", 9, FontStyle.Regular, Muted); header.Controls.Add(years);
            clock = LabelOf("00:00", 16, FontStyle.Bold, MainText); header.Controls.Add(clock);
            pc = LabelOf("ПК №01", 9, FontStyle.Regular, Muted); header.Controls.Add(pc);
            Button adminButton = TopButton("АДМИН", AdminClick); adminButton.Tag = "admin"; header.Controls.Add(adminButton);
            Button restart = TopButton("ПЕРЕЗАГРУЗИТЬ", RestartClick); restart.Tag = "restart"; header.Controls.Add(restart);
            Button off = TopButton("ВЫКЛЮЧИТЬ", ShutdownClick); off.Tag = "off"; header.Controls.Add(off);

            Panel bottom = new Panel(); bottom.Dock = DockStyle.Bottom; bottom.Height = 34; bottom.BackColor = PanelBg; Controls.Add(bottom);
            footer = new Label(); footer.Dock = DockStyle.Fill; footer.TextAlign = ContentAlignment.MiddleLeft; footer.Padding = new Padding(16,0,0,0); footer.ForeColor = Muted; footer.Font = new Font("Segoe UI", 8); bottom.Controls.Add(footer);

            menu = new FlowLayoutPanel(); menu.Dock = DockStyle.Left; menu.FlowDirection = FlowDirection.TopDown; menu.WrapContents = false; menu.AutoScroll = true; menu.Padding = new Padding(10,14,10,10); menu.BackColor = PanelBg; Controls.Add(menu);
            grid = new FlowLayoutPanel(); grid.Dock = DockStyle.Fill; grid.AutoScroll = true; grid.WrapContents = true; grid.Padding = new Padding(16); grid.BackColor = Bg; Controls.Add(grid); grid.BringToFront();
            RebuildMenu(); RebuildGrid(); AdaptiveLayout();
        }

        private Label LabelOf(string text, float size, FontStyle style, Color color)
        {
            Label l = new Label(); l.Text = text; l.AutoSize = true; l.Font = new Font("Segoe UI", size, style); l.ForeColor = color; return l;
        }

        private Button TopButton(string text, EventHandler handler)
        {
            Button b = new Button(); b.Text = text; b.Height = 32; b.FlatStyle = FlatStyle.Flat; b.FlatAppearance.BorderColor = Color.FromArgb(70,74,84); b.BackColor = CardBg; b.ForeColor = MainText; b.Font = new Font("Segoe UI", 8, FontStyle.Bold); b.Click += handler; return b;
        }

        private void AdaptiveLayout()
        {
            if (ClientSize.Width < 400) return;
            int w = ClientSize.Width; int h = ClientSize.Height;
            header.Height = h < 800 ? 92 : 112;
            int left = Math.Max(170, Math.Min(280, (int)(w * 0.16))); menu.Width = left;
            foreach (Control c in menu.Controls) c.Width = left - 24;
            title.Font = new Font("Segoe UI", w < 1150 ? 20 : (w >= 1900 ? 30 : 26), FontStyle.Bold);
            int center = w / 2;
            title.Location = new Point(center - title.PreferredWidth / 2, 7);
            subtitle.Location = new Point(center - subtitle.PreferredWidth / 2, title.Bottom);
            years.Location = new Point(center - years.PreferredWidth / 2, subtitle.Bottom);
            clock.Location = new Point(w - clock.PreferredWidth - 18, 8);
            pc.Location = new Point(w - pc.PreferredWidth - 18, 38);
            int x = w - 16;
            Control off = FindTag("off"); Control restart = FindTag("restart"); Control adm = FindTag("admin");
            int bw = w < 1200 ? 92 : 118;
            if (off != null) { off.Width = bw; off.Left = x - off.Width; off.Top = header.Height - 40; x = off.Left - 6; }
            if (restart != null) { restart.Width = bw + 18; restart.Left = x - restart.Width; restart.Top = header.Height - 40; x = restart.Left - 6; }
            if (adm != null) { adm.Width = 78; adm.Left = x - adm.Width; adm.Top = header.Height - 40; }

            int available = Math.Max(480, w - left - 44);
            int minCard = w < 1100 ? 142 : 165;
            int maxCard = w > 1900 ? 230 : 205;
            int columns = Math.Max(3, available / (minCard + 16));
            int cw = Math.Max(minCard, Math.Min(maxCard, (available - columns * 16) / columns));
            int ch = Math.Max(105, (int)(cw * 0.68));
            foreach (Control c in grid.Controls) { c.Width = cw; c.Height = ch; c.Margin = new Padding(8); }
        }

        private Control FindTag(string tag)
        {
            foreach (Control c in header.Controls) if (c.Tag != null && c.Tag.ToString() == tag) return c;
            return null;
        }

        private void RebuildMenu()
        {
            menu.Controls.Clear();
            foreach (Category cat in categories)
            {
                Button b = new Button(); b.Text = cat.Name; b.Tag = cat.Name; b.Height = 46; b.FlatStyle = FlatStyle.Flat; b.FlatAppearance.BorderSize = 0; b.TextAlign = ContentAlignment.MiddleLeft; b.Padding = new Padding(13,0,0,0); b.Font = new Font("Segoe UI", 10, FontStyle.Bold); b.ForeColor = cat.Name == selected ? Accent : MainText; b.BackColor = cat.Name == selected ? Color.FromArgb(41,45,54) : PanelBg; b.Click += MenuClick; menu.Controls.Add(b);
            }
            AdaptiveLayout();
        }

        private void MenuClick(object sender, EventArgs e)
        {
            Button b = sender as Button; if (b == null) return; selected = b.Tag.ToString(); RebuildMenu(); RebuildGrid();
        }

        private void RebuildGrid()
        {
            grid.SuspendLayout(); grid.Controls.Clear();
            foreach (Game g in games)
            {
                if (selected != "ВСЕ ИГРЫ" && g.Category != selected) continue;
                Panel card = new Panel(); card.BackColor = CardBg; card.Cursor = Cursors.Hand;
                Label icon = new Label(); icon.Dock = DockStyle.Fill; icon.Text = "▶"; icon.TextAlign = ContentAlignment.MiddleCenter; icon.ForeColor = Accent; icon.Font = new Font("Segoe UI", 28, FontStyle.Bold); icon.BackColor = Color.FromArgb(28,31,38);
                Label name = new Label(); name.Dock = DockStyle.Bottom; name.Height = 38; name.Text = g.Name; name.TextAlign = ContentAlignment.MiddleCenter; name.ForeColor = MainText; name.BackColor = Color.FromArgb(22,25,31); name.Font = new Font("Segoe UI", 9, FontStyle.Bold);
                EventHandler launch = delegate { Launch(g); }; card.Click += launch; icon.Click += launch; name.Click += launch;
                card.Controls.Add(icon); card.Controls.Add(name); grid.Controls.Add(card);
            }
            grid.ResumeLayout(); AdaptiveLayout();
        }

        private void Launch(Game g)
        {
            if (String.IsNullOrEmpty(g.Exe)) { MessageBox.Show("Ярлык «" + g.Name + "» пока тестовый. Путь к игре добавим через админку в следующей сборке.", "ЭПОХА"); return; }
            try { Process.Start(g.Exe); } catch (Exception ex) { MessageBox.Show(ex.Message, "Ошибка запуска"); }
        }

        private void UpdateClock()
        {
            clock.Text = DateTime.Now.ToString("HH:mm");
            footer.Text = "ЭПОХА 0.1.1 SAFE  •  ПК №01  •  " + Environment.MachineName + "  •  клубные ограничения НЕ активны";
        }

        private void AdminClick(object sender, EventArgs e)
        {
            if (!admin)
            {
                string pass = AskPassword(); if (pass == null) return;
                if (pass != "2000") { MessageBox.Show("Неверный пароль", "ЭПОХА"); return; }
                admin = true;
            }
            MessageBox.Show("Администратор активен.\r\n\r\nЭто SAFE-сборка: блокировки Windows специально отключены до проверки запуска.\r\nСледующей сборкой вернём редактор вкладок, ярлыков и режим обслуживания.", "ЭПОХА — Администратор");
        }

        private string AskPassword()
        {
            Form f = new Form(); f.Text = "ЭПОХА — Вход администратора"; f.StartPosition = FormStartPosition.CenterScreen; f.FormBorderStyle = FormBorderStyle.FixedDialog; f.Width = 390; f.Height = 155; f.MaximizeBox = false; f.MinimizeBox = false;
            Label l = new Label(); l.Text = "Пароль администратора:"; l.SetBounds(14,14,340,22); f.Controls.Add(l);
            TextBox t = new TextBox(); t.UseSystemPasswordChar = true; t.SetBounds(14,40,345,25); f.Controls.Add(t);
            Button ok = new Button(); ok.Text = "Войти"; ok.DialogResult = DialogResult.OK; ok.SetBounds(200,76,75,30); f.Controls.Add(ok);
            Button cancel = new Button(); cancel.Text = "Отмена"; cancel.DialogResult = DialogResult.Cancel; cancel.SetBounds(284,76,75,30); f.Controls.Add(cancel); f.AcceptButton = ok; f.CancelButton = cancel;
            return f.ShowDialog() == DialogResult.OK ? t.Text : null;
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
            if (e.Control && e.Alt && e.KeyCode == Keys.E) { AdminClick(this, EventArgs.Empty); e.SuppressKeyPress = true; }
            if (e.KeyCode == Keys.Escape && admin) Close();
        }
    }
}
