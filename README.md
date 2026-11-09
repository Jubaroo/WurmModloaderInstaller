# Wurm Unlimited Client Modloader Installer

A Windows installer for [Ago's Wurm Unlimited client mod loader](https://github.com/ago1024/WurmClientModLauncher). It auto-detects the game, patches `client.jar` while keeping a full backup, manages existing mods, and uninstalls cleanly.

**No mods are bundled.** The installer ships only the loader; you add your own mods to the `mods` folder.

## Download

Download the latest setup from the [releases page](https://github.com/Jubaroo/ClientModloaderInstaller/releases/latest).

Support, feedback and translation corrections: [Wurm forum thread](https://forum.wurmonline.com/index.php?/topic/159953-installer-for-agos-client-mod-loader-w-mods/).

## Features

- **Automatic detection** of Steam installs, previous installs and common paths, with a manual folder picker as fallback. The server folder is detected and refused.
- **Environment check** before anything is written: folder, detection source, Java version and `client.jar` state.
- **Safe patching**: the original game client is kept as `client-patched.jar`, with options to restore it first or skip patching entirely.
- **Mod manager**: lists every mod as enabled/disabled, with toggle, enable all, disable all and open folder. Nothing is deleted.
- **30 languages**: the full UI, every custom page and the uninstaller.
- **Installation log** written to the game folder.
- **Clean uninstall**: restores the original `client.jar`, removes every loader file and keeps your mods unless you explicitly delete them.

## Requirements

- Windows 7 or newer
- Administrator rights
- Wurm Unlimited client (Steam installs are detected automatically)
- The Java runtime bundled with Wurm Unlimited (detected automatically)

## How patching works

After installation, `WurmLauncher` starts from `client.jar`, which is a small loader bootstrap. The untouched original game client is stored next to it as `client-patched.jar`. Do not rename or delete that file; it is the rollback copy.

## Silent install

```bat
setup.exe /S /D=C:\path\to\WurmLauncher
```

`/D=` must be the last parameter and is not quoted. With `/S`, the installer exits with code `2` if `client.jar` is not found at the target path.

| Option | Description |
| --- | --- |
| `/NOPATCH` | Install the loader, do not touch `client.jar` |
| `/NORESTORE` | Do not restore the original `client.jar` first |
| `/DISABLEMODS` | Disable all existing mods |
| `/ENABLEMODS` | Enable all existing mods |
| `/NOMODS` | Skip the mods folder layout guide |
| `/NOSTARTMENU` | No Start Menu shortcuts |
| `/DESKTOP` | Create a desktop shortcut |
| `/NODESKTOP` | No desktop shortcut |
| `/LOG=<file>` | Write the log to a specific file |
| `/NOLOG` | No log file |
| `/LANG=<id>` | Force the UI language |
| `/HELP` | Show the options |

## Languages

English, French, German, Spanish, Spanish (International), Portuguese, Portuguese (Brazil), Italian, Dutch, Danish, Swedish, Norwegian, Finnish, Polish, Czech, Slovak, Hungarian, Romanian, Croatian, Bulgarian, Russian, Ukrainian, Turkish, Greek, Simplified Chinese, Traditional Chinese, Japanese, Korean, Indonesian and Catalan.

## Loader version

This packages the client mod loader **v0.15**, the latest client release from Ago. The 0.47 releases are the **server** mod loader (`WurmServerModLauncher`) and are not part of this installer.

## Building from source

The installer is written in NSIS 3.13.

```bat
build.bat          :: release build (per machine, administrator)
build.bat test     :: test build (per user, separate registry keys)
```

Output is written to `build\`. The script is compiled with `/V3 /WX`, so warnings fail the build.

### Repository layout

```
WurmModloaderInstaller.nsi   installer and uninstaller script
build.bat                    build script
assets\                      icon and wizard bitmaps
payload\                     loader jars, patcher scripts, mods readme
lang\strings.nsh             generated language strings (do not edit)
tools\gen-lang.mjs           regenerates lang\strings.nsh from tools\lang\*.json
tools\lang\                  one JSON file per language
```

After editing a translation in `tools\lang\`, regenerate `lang\strings.nsh` with:

```bat
node tools\gen-lang.mjs
```

## Credits

- Client mod loader and patcher: [Ago](https://github.com/ago1024/WurmClientModLauncher)
- Installer, UI and mod management: this repository
