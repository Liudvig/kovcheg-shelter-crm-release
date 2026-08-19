using System;
using System.IO;
using System.Text;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Security.Principal;
using Microsoft.Win32;
using System.Windows.Forms;

namespace EpohaWin7SystemProbe
{
    static class Program
    {
        [DllImport("sfc.dll", CharSet = CharSet.Unicode)]
        static extern bool SfcIsFileProtected(IntPtr rpcHandle, string protectedFileName);

        [DllImport("kernel32.dll")]
        static extern ushort GetSystemDefaultUILanguage();

        [STAThread]
        static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            try
            {
                if (!IsAdministrator())
                {
                    ProcessStartInfo psi = new ProcessStartInfo(Application.ExecutablePath);
                    psi.UseShellExecute = true;
                    psi.Verb = "runas";
                    try { Process.Start(psi); } catch { }
                    return;
                }

                string stamp = DateTime.Now.ToString("yyyyMMdd-HHmmss");
                string desktop = Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory);
                string root = Path.Combine(desktop, "EPOHA-WIN7-PROBE-" + stamp);
                string bundle = Path.Combine(root, "bundle");
                Directory.CreateDirectory(bundle);

                StringBuilder report = new StringBuilder();
                report.AppendLine("EPOHA WIN7 SYSTEM PROBE 1.0");
                report.AppendLine("Created=" + DateTime.Now.ToString("s"));
                report.AppendLine("Machine=" + Environment.MachineName);
                report.AppendLine("User=" + Environment.UserName);
                report.AppendLine("OSVersion=" + Environment.OSVersion.ToString());
                report.AppendLine("Is64BitOS=" + Is64BitOperatingSystem().ToString());
                report.AppendLine("ProcessArchitecture=" + Environment.GetEnvironmentVariable("PROCESSOR_ARCHITECTURE"));
                report.AppendLine("InstalledUICulture=" + SafeCulture(CultureInfo.InstalledUICulture));
                report.AppendLine("CurrentUICulture=" + SafeCulture(CultureInfo.CurrentUICulture));
                report.AppendLine("SystemDefaultUILanguage=0x" + GetSystemDefaultUILanguage().ToString("X4"));
                report.AppendLine();

                DumpRegistry(report, Registry.LocalMachine, @"SOFTWARE\Microsoft\Windows NT\CurrentVersion", "HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion");
                DumpRegistry(report, Registry.LocalMachine, @"SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI", "HKLM\\...\\Authentication\\LogonUI");
                DumpRegistry(report, Registry.LocalMachine, @"SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\Background", "HKLM\\...\\LogonUI\\Background");
                DumpRegistry(report, Registry.LocalMachine, @"SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System", "HKLM\\...\\Policies\\System");
                DumpRegistry(report, Registry.LocalMachine, @"SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "HKLM\\...\\Winlogon");
                DumpRegistry(report, Registry.LocalMachine, @"SOFTWARE\Policies\Microsoft\Windows\System", "HKLM\\SOFTWARE\\Policies\\Microsoft\\Windows\\System");
                report.AppendLine();

                string win = Environment.GetEnvironmentVariable("WINDIR");
                string sys = Environment.GetFolderPath(Environment.SpecialFolder.System);
                report.AppendLine("WindowsDir=" + win);
                report.AppendLine("NativeSystemDir=" + sys);
                report.AppendLine();

                string[] core = new string[] {
                    "authui.dll", "LogonUI.exe", "winlogon.exe", "basebrd.dll", "imageres.dll", "credui.dll", "user32.dll", "winload.exe"
                };
                for (int i = 0; i < core.Length; i++) CollectFile(Path.Combine(sys, core[i]), bundle, "System32__" + core[i], report);

                string bootres = Path.Combine(Path.Combine(win, "Boot"), Path.Combine("Resources", "bootres.dll"));
                CollectFile(bootres, bundle, "Boot_Resources__bootres.dll", report);

                string[] muiNames = new string[] {
                    "authui.dll.mui", "LogonUI.exe.mui", "winlogon.exe.mui", "basebrd.dll.mui", "imageres.dll.mui", "credui.dll.mui", "user32.dll.mui", "winload.exe.mui"
                };
                CollectMuiFiles(sys, muiNames, bundle, report);

                string backgrounds = Path.Combine(sys, @"oobe\info\backgrounds");
                if (Directory.Exists(backgrounds))
                {
                    string[] bg = Directory.GetFiles(backgrounds);
                    for (int i = 0; i < bg.Length; i++) CollectFile(bg[i], bundle, "OOBE__" + Path.GetFileName(bg[i]), report);
                }

                CaptureCommand("dism.exe", "/online /Get-CurrentEdition", Path.Combine(bundle, "DISM_CurrentEdition.txt"), report);
                CaptureCommand("dism.exe", "/online /Get-Features /Format:Table", Path.Combine(bundle, "DISM_Features.txt"), report);
                CaptureCommand("bcdedit.exe", "/enum {current}", Path.Combine(bundle, "BCD_Current.txt"), report);

                string reportPath = Path.Combine(bundle, "probe-report.txt");
                File.WriteAllText(reportPath, report.ToString(), new UTF8Encoding(true));

                string cabPath = Path.Combine(desktop, "EPOHA-WIN7-PROBE-" + stamp + ".cab");
                string ddfPath = Path.Combine(root, "probe.ddf");
                BuildDdf(bundle, cabPath, ddfPath);
                Process p = Process.Start(new ProcessStartInfo("makecab.exe", "/F \"" + ddfPath + "\"") { UseShellExecute = false, CreateNoWindow = true });
                if (p != null) p.WaitForExit();

                if (File.Exists(cabPath))
                {
                    MessageBox.Show("\u041F\u0430\u043A\u0435\u0442 \u0441\u043E\u0431\u0440\u0430\u043D.\r\n\r\n" + cabPath + "\r\n\r\n\u041F\u0440\u0438\u0448\u043B\u0438 \u044D\u0442\u043E\u0442 CAB \u0432 \u0447\u0430\u0442. \u041F\u0440\u043E\u0433\u0440\u0430\u043C\u043C\u0430 \u043D\u0438\u0447\u0435\u0433\u043E \u0432 Windows \u043D\u0435 \u0438\u0437\u043C\u0435\u043D\u044F\u043B\u0430.", "EPOHA Win7 System Probe", MessageBoxButtons.OK, MessageBoxIcon.Information);
                }
                else
                {
                    MessageBox.Show("\u0424\u0430\u0439\u043B\u044B \u0441\u043E\u0431\u0440\u0430\u043D\u044B \u0432 \u043F\u0430\u043F\u043A\u0443:\r\n" + root + "\r\n\r\nCAB \u043D\u0435 \u0441\u043E\u0437\u0434\u0430\u043B\u0441\u044F. \u041F\u0430\u043F\u043A\u0430 \u043E\u0441\u0442\u0430\u043B\u0430\u0441\u044C \u043D\u0430 \u0440\u0430\u0431\u043E\u0447\u0435\u043C \u0441\u0442\u043E\u043B\u0435.", "EPOHA Win7 System Probe", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.ToString(), "EPOHA Win7 System Probe", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        static bool IsAdministrator()
        {
            try
            {
                WindowsIdentity id = WindowsIdentity.GetCurrent();
                WindowsPrincipal p = new WindowsPrincipal(id);
                return p.IsInRole(WindowsBuiltInRole.Administrator);
            }
            catch { return false; }
        }

        static bool Is64BitOperatingSystem()
        {
            if (IntPtr.Size == 8) return true;
            string a = Environment.GetEnvironmentVariable("PROCESSOR_ARCHITEW6432");
            return !String.IsNullOrEmpty(a);
        }

        static string SafeCulture(CultureInfo c)
        {
            try { return c.Name + " / " + c.DisplayName; } catch { return "?"; }
        }

        static void DumpRegistry(StringBuilder sb, RegistryKey hive, string path, string label)
        {
            sb.AppendLine("[REGISTRY " + label + "]");
            try
            {
                using (RegistryKey k = hive.OpenSubKey(path))
                {
                    if (k == null) { sb.AppendLine("<missing>"); return; }
                    string[] names = k.GetValueNames();
                    Array.Sort(names);
                    for (int i = 0; i < names.Length; i++)
                    {
                        object v = null; try { v = k.GetValue(names[i], null, RegistryValueOptions.DoNotExpandEnvironmentNames); } catch { }
                        sb.AppendLine(names[i] + "=" + (v == null ? "<null>" : v.ToString()));
                    }
                }
            }
            catch (Exception ex) { sb.AppendLine("ERROR=" + ex.Message); }
            sb.AppendLine();
        }

        static void CollectMuiFiles(string systemDir, string[] muiNames, string bundle, StringBuilder report)
        {
            try
            {
                string[] dirs = Directory.GetDirectories(systemDir);
                for (int d = 0; d < dirs.Length; d++)
                {
                    string lang = Path.GetFileName(dirs[d]);
                    if (lang.Length < 2 || lang.Length > 12) continue;
                    for (int i = 0; i < muiNames.Length; i++)
                    {
                        string p = Path.Combine(dirs[d], muiNames[i]);
                        if (File.Exists(p)) CollectFile(p, bundle, "MUI_" + Sanitize(lang) + "__" + muiNames[i], report);
                    }
                }
            }
            catch (Exception ex) { report.AppendLine("MUI_SCAN_ERROR=" + ex.Message); }
        }

        static void CollectFile(string source, string bundle, string destName, StringBuilder report)
        {
            report.AppendLine("[FILE] " + source);
            if (!File.Exists(source)) { report.AppendLine("Exists=0"); report.AppendLine(); return; }
            try
            {
                FileInfo fi = new FileInfo(source);
                FileVersionInfo vi = FileVersionInfo.GetVersionInfo(source);
                bool prot = false; try { prot = SfcIsFileProtected(IntPtr.Zero, source); } catch { }
                report.AppendLine("Exists=1");
                report.AppendLine("Size=" + fi.Length.ToString());
                report.AppendLine("FileVersion=" + vi.FileVersion);
                report.AppendLine("ProductVersion=" + vi.ProductVersion);
                report.AppendLine("Language=" + vi.Language);
                report.AppendLine("WRPProtected=" + prot.ToString());
                report.AppendLine("SHA256=" + Sha256(source));
                string dest = Path.Combine(bundle, Sanitize(destName));
                File.Copy(source, dest, true);
                report.AppendLine("CollectedAs=" + Path.GetFileName(dest));
            }
            catch (Exception ex) { report.AppendLine("ERROR=" + ex.Message); }
            report.AppendLine();
        }

        static string Sha256(string path)
        {
            using (FileStream fs = File.OpenRead(path))
            using (SHA256 sha = new SHA256Managed())
            {
                byte[] h = sha.ComputeHash(fs);
                StringBuilder s = new StringBuilder(h.Length * 2);
                for (int i = 0; i < h.Length; i++) s.Append(h[i].ToString("x2"));
                return s.ToString();
            }
        }

        static void CaptureCommand(string exe, string args, string output, StringBuilder report)
        {
            try
            {
                ProcessStartInfo psi = new ProcessStartInfo(exe, args);
                psi.UseShellExecute = false; psi.CreateNoWindow = true; psi.RedirectStandardOutput = true; psi.RedirectStandardError = true;
                Process p = Process.Start(psi);
                string so = p.StandardOutput.ReadToEnd(); string se = p.StandardError.ReadToEnd(); p.WaitForExit();
                File.WriteAllText(output, "EXIT=" + p.ExitCode + "\r\n" + so + "\r\n" + se, new UTF8Encoding(true));
                report.AppendLine("COMMAND " + exe + " " + args + " -> exit " + p.ExitCode);
            }
            catch (Exception ex) { report.AppendLine("COMMAND_ERROR " + exe + " " + args + " :: " + ex.Message); }
        }

        static string Sanitize(string s)
        {
            char[] bad = Path.GetInvalidFileNameChars();
            for (int i = 0; i < bad.Length; i++) s = s.Replace(bad[i], '_');
            return s.Replace('\\', '_').Replace('/', '_').Replace(':', '_');
        }

        static void BuildDdf(string bundle, string cabPath, string ddfPath)
        {
            StringBuilder ddf = new StringBuilder();
            ddf.AppendLine(".OPTION EXPLICIT");
            ddf.AppendLine(".Set CabinetNameTemplate=\"" + Path.GetFileName(cabPath) + "\"");
            ddf.AppendLine(".Set DiskDirectoryTemplate=\"" + Path.GetDirectoryName(cabPath) + "\"");
            ddf.AppendLine(".Set CompressionType=MSZIP");
            ddf.AppendLine(".Set Cabinet=on");
            ddf.AppendLine(".Set Compress=on");
            string[] files = Directory.GetFiles(bundle);
            Array.Sort(files);
            for (int i = 0; i < files.Length; i++) ddf.AppendLine("\"" + files[i] + "\" \"" + Path.GetFileName(files[i]) + "\"");
            File.WriteAllText(ddfPath, ddf.ToString(), Encoding.ASCII);
        }
    }
}
