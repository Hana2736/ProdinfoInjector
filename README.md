# ProdinfoInjector
Allows you to create a custom Atmosphère build that spoofs another PRODINFO.
This can be used to test NAND backups from other consoles.

# Notes and warnings
- This build of Atmosphère will spoof the PRODINFO on both SysMMC and EmuMMC, regardless of any PRODINFO blanking settings in `exosphere.ini` 
- You **must** use TegraExplorer to wipe the MMC, the Switch OS will not work after you change PRODINFOs unless you wipe!
- Make sure you have a MMC backup! This doens't physically overwrite your PRODINFO, but you want to keep your tickets and savedata safe!
- You can **not** go between your stock PRODINFO and other PRODINFOs without a TegraExplorer wipe!
- This was tested injecting an Erista PRODINFO into another Erista. This may or may not work for Mariko / Lite / OLED, I don't know!
- There is little to no permanent brick risk if all steps are followed properly, still be careful and take backups!!
- This tool is not made to evade bans. Nintendo telemetry may still detect this and ban both consoles!

# Usage
0. Take a complete SysMMC backup and save it on your PC or somewhere safe!
1. Install DevKitPro as well as all Switch dependencies (see [Atmosphère docs](https://github.com/Atmosphere-NX/Atmosphere/blob/master/docs/building.md)) into your favorite Linux distro (or WSL)
2. Download the injector into any folder on your machine
```bash
#Example, this can be placed anywhere
mkdir -p ~/Documents/Projects/prodinfo-injector
git clone https://github.com/Hana2736/ProdinfoInjector.git ~/Documents/Projects/prodinfo-injector
```
3. Place your decrypted `PRODINFO` file next to the `injector.sh` file, and rename it to `prod.info`
4. Run `./injector.sh`
5. Copy the output SD card files onto your SD card
6. Use [TegraExplorer](https://github.com/suchmememanyskill/TegraExplorer/releases) to fully wipe SysMMC. This is not optional!
7. Boot the console into Atmosphère.

