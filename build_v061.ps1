$ErrorActionPreference = "Stop"

function Replace-Exact([string]$text, [string]$old, [string]$new, [string]$name) {
    if (-not $text.Contains($old)) { throw ("Patch target not found: " + $name) }
    return $text.Replace($old, $new)
}

.\build_v060.ps1
$src = Get-Content ProgramV060Build.cs -Raw -Encoding UTF8
$src = $src.Replace('0.6.0', '0.6.1')

# One shared glass value for top header + left navigation.
$src = $src.Replace('ThemeWallpaper.SidebarTransparency=cfg.SidebarTransparency; ThemeWallpaper.CardTransparency=cfg.CardTransparency; ThemeWallpaper.HeaderTransparency=cfg.HeaderTransparency;', 'ThemeWallpaper.SidebarTransparency=cfg.HeaderTransparency; ThemeWallpaper.CardTransparency=cfg.CardTransparency; ThemeWallpaper.HeaderTransparency=cfg.HeaderTransparency;')
$src = $src.Replace('brandHeader.Transparency=cfg.HeaderTransparency; topHeader.Transparency=cfg.HeaderTransparency; footer.Transparency=cfg.HeaderTransparency;\n            navHost.Transparency=cfg.SidebarTransparency;', 'brandHeader.Transparency=cfg.HeaderTransparency; topHeader.Transparency=cfg.HeaderTransparency; footer.Transparency=cfg.HeaderTransparency;\n            navHost.Transparency=cfg.HeaderTransparency;')
$src = $src.Replace('navList.Transparency=cfg.SidebarTransparency;', 'navList.Transparency=cfg.HeaderTransparency;')

# Keep a dark tint even at maximum glass transparency so bright wallpapers never wash out the menu.
$src = $src.Replace('int alpha = (100 - t) * 235 / 100;', 'int alpha = 105 + (100 - t) * 130 / 100;')
$src = $src.Replace('int alpha=(100-t)*235/100;', 'int alpha=105+(100-t)*130/100;')
$src = $src.Replace('int a=(100-t)*235/100;', 'int a=105+(100-t)*130/100;')
$src = $src.Replace('int baseAlpha=(100-t)*185/100;', 'int baseAlpha=105+(100-t)*120/100;\n            using(SolidBrush baseShade=new SolidBrush(Color.FromArgb(baseAlpha,7,10,17)))e.Graphics.FillRectangle(baseShade,ClientRectangle);')

# Softer game cards: darker neutral borders, less bright chrome.
$src = $src.Replace('Color.FromArgb(78,92,122)', 'Color.FromArgb(52,64,88)')
$src = $src.Replace('using(Pen p2=new Pen(Color.FromArgb(150,Accent),2f))', 'using(Pen p2=new Pen(Color.FromArgb(105,Accent),1.4f))')

# Replace Appearance page with a simpler page: one shared header/sidebar glass control.
$appearancePattern = '(?s)        private void BuildAdminAppearance\(DbPanel p\)\s*\{.*?\r?\n        \}\r?\n\r?\n        private void ChooseWallpaper\(\)'
$appearanceReplacement = @'
        private void BuildAdminAppearance(DbPanel p)
        {
            Title(p,"\u0412\u043d\u0435\u0448\u043d\u0438\u0439 \u0432\u0438\u0434");

            FieldLabel(p,"\u041e\u0431\u043e\u0438",76);
            TextBox wall=new TextBox();wall.ReadOnly=true;wall.Text=String.IsNullOrEmpty(cfg.WallpaperPath)?"\u041d\u0435 \u0432\u044b\u0431\u0440\u0430\u043d\u044b":cfg.WallpaperPath;wall.SetBounds(30,98,510,24);p.Controls.Add(wall);
            ActionButton(p,"\u0412\u042b\u0411\u0420\u0410\u0422\u042c \u041e\u0411\u041e\u0418",30,132,150,34,delegate{ChooseWallpaper();ShowAdmin("\u0412\u043d\u0435\u0448\u043d\u0438\u0439 \u0432\u0438\u0434");});
            ActionButton(p,"\u0423\u0411\u0420\u0410\u0422\u042c \u041e\u0411\u041e\u0418",192,132,150,34,delegate{cfg.WallpaperPath="";cfg.Save();ApplyConfigToUi();ShowAdmin("\u0412\u043d\u0435\u0448\u043d\u0438\u0439 \u0432\u0438\u0434");});
            WallpaperPanel preview=new WallpaperPanel();preview.SetBounds(575,76,330,185);preview.Mode=cfg.WallpaperMode;preview.Dim=cfg.WallpaperDim;preview.LoadWallpaper(cfg.WallpaperPath);p.Controls.Add(preview);

            FieldLabel(p,"\u0420\u0435\u0436\u0438\u043c \u043e\u0431\u043e\u0435\u0432",190);
            ComboBox wm=new ComboBox();wm.DropDownStyle=ComboBoxStyle.DropDownList;wm.Items.AddRange(new object[]{"Fill","Stretch","Center"});wm.SelectedItem=cfg.WallpaperMode;wm.SetBounds(30,212,180,24);p.Controls.Add(wm);

            FieldLabel(p,"\u0426\u0432\u0435\u0442 \u0438\u043d\u0442\u0435\u0440\u0444\u0435\u0439\u0441\u0430",258);
            Panel swatch=new Panel();swatch.BackColor=Accent;swatch.SetBounds(30,282,42,26);p.Controls.Add(swatch);
            ActionButton(p,"\u0412\u042b\u0411\u0420\u0410\u0422\u042c \u0426\u0412\u0415\u0422",82,279,150,32,delegate{using(ColorDialog d=new ColorDialog()){d.Color=Accent;if(d.ShowDialog()==DialogResult.OK){cfg.AccentArgb=d.Color.ToArgb();cfg.Save();ApplyConfigToUi();BuildNav();ShowAdmin("\u0412\u043d\u0435\u0448\u043d\u0438\u0439 \u0432\u0438\u0434");}}});

            FieldLabel(p,"\u041f\u0440\u043e\u0437\u0440\u0430\u0447\u043d\u043e\u0441\u0442\u044c \u0448\u0430\u043f\u043a\u0438 \u0438 \u043c\u0435\u043d\u044e",334);
            TrackBar glass=new TrackBar();glass.Minimum=0;glass.Maximum=100;glass.TickFrequency=10;glass.Value=Math.Max(0,Math.Min(100,cfg.HeaderTransparency));glass.SetBounds(24,356,330,42);p.Controls.Add(glass);
            Label glassVal=ValueLabel(p,glass.Value+"%",365,364,70);

            FieldLabel(p,"\u0417\u0430\u0442\u0435\u043c\u043d\u0435\u043d\u0438\u0435 \u043e\u0431\u043e\u0435\u0432",410);
            TrackBar dim=new TrackBar();dim.Minimum=0;dim.Maximum=90;dim.TickFrequency=10;dim.Value=Math.Max(0,Math.Min(90,cfg.WallpaperDim));dim.SetBounds(24,432,330,42);p.Controls.Add(dim);
            Label dimVal=ValueLabel(p,dim.Value+"%",365,440,70);

            FieldLabel(p,"\u0420\u0430\u0437\u043c\u0435\u0440 \u043a\u0430\u0440\u0442\u043e\u0447\u0435\u043a \u0438\u0433\u0440",486);
            ComboBox cs=new ComboBox();cs.DropDownStyle=ComboBoxStyle.DropDownList;cs.Items.AddRange(new object[]{"\u041c\u0430\u043b\u0435\u043d\u044c\u043a\u0438\u0435","\u0421\u0440\u0435\u0434\u043d\u0438\u0435","\u0411\u043e\u043b\u044c\u0448\u0438\u0435"});cs.SelectedItem=cfg.CardSize;cs.SetBounds(30,508,180,24);p.Controls.Add(cs);

            CheckBox exeIcons=new CheckBox();exeIcons.Text="\u0418\u043a\u043e\u043d\u043a\u0430 EXE, \u0435\u0441\u043b\u0438 \u043d\u0435\u0442 \u043e\u0431\u043b\u043e\u0436\u043a\u0438";exeIcons.Checked=cfg.UseExeIcons;exeIcons.SetBounds(30,552,270,24);p.Controls.Add(exeIcons);
            CheckBox showCat=new CheckBox();showCat.Text="\u041f\u043e\u043a\u0430\u0437\u044b\u0432\u0430\u0442\u044c \u0436\u0430\u043d\u0440/\u0432\u043a\u043b\u0430\u0434\u043a\u0443";showCat.Checked=cfg.ShowCardCategory;showCat.SetBounds(315,552,250,24);p.Controls.Add(showCat);
            CheckBox showDate=new CheckBox();showDate.Text="\u0414\u0430\u0442\u0430";showDate.Checked=cfg.ShowDate;showDate.SetBounds(580,552,100,24);p.Controls.Add(showDate);
            CheckBox showSec=new CheckBox();showSec.Text="\u0421\u0435\u043a\u0443\u043d\u0434\u044b";showSec.Checked=cfg.ShowSeconds;showSec.SetBounds(690,552,120,24);p.Controls.Add(showSec);
            CheckBox showStatus=new CheckBox();showStatus.Text="\u0421\u0442\u0430\u0442\u0443\u0441 \u0441\u0435\u0430\u043d\u0441\u0430";showStatus.Checked=cfg.ShowStatusPanel;showStatus.SetBounds(30,582,180,24);p.Controls.Add(showStatus);

            glass.Scroll+=delegate{glassVal.Text=glass.Value+"%";ThemeWallpaper.HeaderTransparency=glass.Value;ThemeWallpaper.SidebarTransparency=glass.Value;brandHeader.Transparency=glass.Value;topHeader.Transparency=glass.Value;navHost.Transparency=glass.Value;navList.Transparency=glass.Value;brandHeader.Invalidate(true);topHeader.Invalidate(true);navHost.Invalidate(true);navList.Invalidate(true);};
            dim.Scroll+=delegate{dimVal.Text=dim.Value+"%";preview.Dim=dim.Value;preview.Invalidate();};

            ActionButton(p,"\u0421\u041e\u0425\u0420\u0410\u041d\u0418\u0422\u042c",30,628,170,38,delegate{
                cfg.WallpaperMode=wm.SelectedItem==null?"Fill":wm.SelectedItem.ToString();cfg.WallpaperDim=dim.Value;cfg.HeaderTransparency=glass.Value;cfg.SidebarTransparency=glass.Value;
                cfg.CardSize=cs.SelectedItem==null?"\u0421\u0440\u0435\u0434\u043d\u0438\u0435":cs.SelectedItem.ToString();cfg.UseExeIcons=exeIcons.Checked;cfg.ShowCardCategory=showCat.Checked;cfg.ShowDate=showDate.Checked;cfg.ShowSeconds=showSec.Checked;cfg.ShowStatusPanel=showStatus.Checked;
                cfg.Save();ApplyConfigToUi();BuildNav();ShowAdmin("\u0412\u043d\u0435\u0448\u043d\u0438\u0439 \u0432\u0438\u0434");
            });
        }

        private void ChooseWallpaper()
'@
$newSrc = [regex]::Replace($src,$appearancePattern,$appearanceReplacement,1)
if($newSrc -eq $src){throw "Appearance 0.6.1 patch failed"}
$src=$newSrc

Set-Content -Path ProgramV061Build.cs -Value $src -Encoding UTF8
