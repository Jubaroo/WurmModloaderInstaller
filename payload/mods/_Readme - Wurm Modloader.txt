WURM UNLIMITED CLIENT MODLOADER
===============================

This folder is scanned by Ago's WurmClientModLauncher for client mods.
The installer ships no mods of its own: add your own here.

REQUIRED LAYOUT
---------------
Every mod normally consists of two parts:

  mods\<name>.properties
  mods\<name>\<name>.jar

<name>.properties holds the mod settings and marks the mod as installed.
<name>\<name>.jar holds the code.

A mod that only supplies a jar is also loaded when it lives at
mods\<name>\<name>.jar (without a .properties file).

ENABLING / DISABLING
--------------------
Renaming only the .properties file is not enough, because the loader also
scans the mods sub folders and loads any <folder>\<folder>.jar it finds.
To fully disable a mod, rename BOTH parts:

  <name>.properties   ->  <name>.properties.disabled
  <name>\             ->  <name>.disabled\

The "Manage installed mods" page of the installer does this for you.

REMOVING A MOD
--------------
Delete both the .properties file and the matching folder.

TROUBLESHOOTING
---------------
- The in-game console (usually F9) shows loader and mod errors.
- A broken mod can prevent the client from starting. Disable mods with the
  installer or rename them as shown above, then start the game again.
- Keep client.jar and client-patched.jar untouched. The patched client is
  the loader bootstrap; client-patched.jar is the original game client.

LOADER
------
Ago's WurmClientModLauncher v0.15
https://forum.wurmonline.com/index.php?/topic/159953-installer-for-agos-client-mod-loader-w-mods/
