# ProdinfoInjector
Allows you to create a custom Atmosphère build that spoofs another PRODINFO.  
This can be used to test NAND backups from other consoles.

## Notes and warnings (READ ALL OF THIS BEFORE USING)
### Operational Behavior
* **Overrides exosphere.ini:** This custom build of Atmosphère will spoof the PRODINFO on both SysNAND and EmuNAND. It will ignore any PRODINFO blanking settings in your exosphere.ini file.

* **No Permanent Overwrite:** The tool does **not** permanently overwrite the physical PRODINFO file stored on your console's internal memory. (This is a good thing)

### Mandatory Actions & Risks
* **Full Wipe is Required:** After installing this custom build, you must use TegraExplorer to perform a full wipe of the NAND you intend to use. The Switch operating system will not boot if this step is skipped.

* **Reverting Also Requires a Wipe:** You cannot switch back and forth between your console's original PRODINFO and a spoofed one. To revert, you must wipe with TegraExplorer first.

* **Backup Your Data:** A full NAND backup is essential. The mandatory wipe process will erase all user data, including games and save files.

* **Minimal Brick Risk:** If all steps are followed precisely, the risk of a permanent brick is minimal. However, caution and complete backups are still necessary.

### Compatibility
* **Limited Testing:** This tool was successfully tested by injecting an Erista (v1) PRODINFO onto another Erista console.

* **Unknown Behavior:** Functionality on Mariko (v2), Switch Lite, or OLED models is untested and not guaranteed. Use on these models is at your own risk. If you do try it, report successes and issues!

### Disclaimer
* **Not for Ban Evasion:** I will not promise that this tool is online-safe. It may later be detected by Nintendo telemetry. Use caution.

* **Use At Your Own Risk:** No guarantee of any specific outcome is provided. You are solely responsible for any damage, data loss, or console bans that may result from using this software.

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

