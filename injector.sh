#!/bin/bash

replace_text() {
    local search_string="$1"
    local replacement_string="$2"
    local file_path="$3"

    # Check basic requirements
    if [ ! -f "$file_path" ]; then
        echo "Error: File not found"
        return 1
    fi

    # Check if the string exists using grep with fixed strings
    if ! grep -q -F -- "$search_string" "$file_path"; then
        echo "No matches found for the string in '$file_path'"
        exit 1
        return 1
    fi

    # Create a temporary file
    local temp_file=$(mktemp)
    
    # Replace \n with actual newlines in the replacement string
    # We use echo -e for this purpose
    local processed_replacement=$(echo -e "${replacement_string}")
    
    # Perform replacement with simple while loop reading line by line
    while IFS= read -r line || [ -n "$line" ]; do
        # If the search string is in this line
        if [[ "$line" == *"$search_string"* ]]; then
            # Replace the string in the current line and properly handle newlines
            echo "${line//"$search_string"/"$processed_replacement"}" >> "$temp_file"
        else
            # Keep the line as is
            echo "$line" >> "$temp_file"
        fi
    done < "$file_path"
    
    # If the file has changes, apply them
    if ! cmp -s "$file_path" "$temp_file"; then
        mv "$temp_file" "$file_path"
        #echo "Successfully replaced text"
        return 0
    else
        rm "$temp_file"
        echo "String found but no changes were made"
        return 1
    fi
}


#replace_text "/* Set blocks. */" "/* Set blocks. *//*" "/home/hana/Desktop/test.txt"
#exit
#Check installed dotnet (C#) version and check if 9.0.X is installed
echo "Checking for .NET 9.0.X" 
if !($(~/.dotnet/dotnet --list-sdks | grep -q "9.0.")); then
    echo ".NET 9 not installed! Installing from Microsoft."
    #Download dotnet installer from microsoft
    wget https://dot.net/v1/dotnet-install.sh -O ./Data/dotnet-install.sh
	chmod +x ./Data/dotnet-install.sh
	#Install dotnet 9.0.X
	./Data/dotnet-install.sh --channel 9.0
	#Restart the script, now that it's installed
	./injector.sh
	exit 0
fi
echo "Checking prod.info and offsets file..."
if [ ! -f "./prod.info" ] || [ ! -f "./Data/Offsets.csv" ]; then
    echo "Save prodinfo as 'prod.info' and check prodinfo 'Offsets.csv'"
    exit 1
fi
echo "Checking if git is installed..."
if !(git 2>&1 | grep -q "See 'git help git' for an overview of the system."); then
    echo "Install git to use this tool."
    exit 1
fi
echo "Checking if dkp-pacman is installed..."
if !($(dkp-pacman -V 2>&1 | grep -q "Pacman Development Team")); then
    echo "Install dkp-pacman to use this tool."
    exit 1
fi
echo "Checking if dkp-ARM is installed..."
if !($(echo "$DEVKITARM" 2>&1 | grep -q "devkitpro")); then
    echo "Install devkit pro packages for Switch development!"
    echo "See https://github.com/Atmosphere-NX/Atmosphere/blob/master/docs/building.md#instructions"
    exit 1
fi
echo "Cleanup..."
rm -rf ./Data/Atmosphere/ > /dev/null 2>&1
mkdir -p ./Data/Atmosphere
rm patched_atmosphere.zip > /dev/null 2>&1
rm ./Data/device_id.txt > /dev/null 2>&1
rm ./Data/dotnet-install.sh > /dev/null 2>&1
rm -rf ./Data/prodinfoparser/build/ > /dev/null 2>&1
rm -rf ./sd_Card/ > /dev/null 2>&1
mkdir -p ./sd_Card/
mkdir -p ./Data/prodinfoparser/build/
echo "Building prodinfo parser..."
prodinfoParser=./Data/prodinfoparser/build/ProdinfoParser
~/.dotnet/dotnet build -o ./Data/prodinfoparser/build/ --self-contained ./Data/prodinfoparser/source/ProdinfoParser.csproj > /dev/null 2>&1
if !($($prodinfoParser | grep -q "bool:getDeviceId")); then
    echo "Prodinfo parser build failed! Check .NET manually"
    exit 1
fi
prodinfoPath=\"$(realpath ./prod.info)\"
offsetsPath=\"$(realpath ./Data/Offsets.csv)\"
$prodinfoParser $prodinfoPath $offsetsPath true > ./Data/device_id.txt 2>&1
if !($(cat ./Data/device_id.txt | grep -q "0x00")); then
    echo "Could not find device ID in prodinfo!"
    exit 1
fi
deviceID=$(cat ./Data/device_id.txt)
echo "Found device ID:" $deviceID
echo "Downloading Atmosphere..."
git clone https://github.com/Atmosphere-NX/Atmosphere.git ./Data/Atmosphere/ > /dev/null 2>&1
echo "Patching Atmosphere..."
#read no_thanks  
echo "Patching stratosphere makefile"
search='export SETTINGS    = $(ATMOSPHERE_SETTINGS) $(ATMOSPHERE_OPTIMIZATION_FLAG) -Wextra -Werror -Wno-missing-field-initializers'
replace='export SETTINGS    = $(ATMOSPHERE_SETTINGS) $(ATMOSPHERE_OPTIMIZATION_FLAG) -Wextra -Wno-missing-field-initializers'
file='./Data/Atmosphere/libraries/config/templates/stratosphere.mk'
if !($(md5sum "$file" | grep -q "32c54e507360825865dcd497c83d450a")); then
    echo "$file was modified in Atmosphere!"
    exit 1
fi
replace_text "$search" "$replace" "$file"
echo "Patching ams::fuse device ID"
search='        return (y_coord <<  0) |'
replace='        return (((y_coord <<  0) |'
file='./Data/Atmosphere/libraries/libexosphere/source/fuse/fuse_api.cpp'
if !($(md5sum "$file" | grep -q "770a07751fa2382d653d91c596c7f4e9")); then
    echo "$file was modified in Atmosphere!"
    exit 1
fi
replace_text "$search" "$replace" "$file"
search='               (fab     << 50);'
replace="               (fab     << 50))*0)+$deviceID"
replace_text "$search" "$replace" "$file"
echo "Patching exosphere device ID"
search='        u64 device_id;'
replace="        u64 device_id = $deviceID"
file='./Data/Atmosphere/libraries/libstratosphere/source/ams/ams_exosphere_api.cpp'
if !($(md5sum "$file" | grep -q "88cb8c0ea16e04c09472576473f26670")); then
    echo "$file was modified in Atmosphere!"
    exit 1
fi
replace_text "$search" "$replace" "$file"
search='        R_ABORT_UNLESS(spl::impl::GetConfig(std::addressof(device_id), spl::ConfigItem::DeviceId));'
replace='//nuked read call'
replace_text "$search" "$replace" "$file"
echo "Generating prodinfo patch..."
generatedPath=$(realpath ./Data/generated_code.inc)
$prodinfoParser $prodinfoPath $offsetsPath false > $generatedPath
echo "Patching prodinfo utils"
search='            info.header.body_size   = sizeof(info.body);'
replace="            info.header.body_size   = sizeof(info.body); unsigned char* prodInfoPtr = reinterpret_cast<unsigned char*>(&info); unsigned char* prodInfoWritePtr = prodInfoPtr;\n#include <$generatedPath>"
file='./Data/Atmosphere/stratosphere/ams_mitm/source/amsmitm_prodinfo_utils.cpp'
if !($(md5sum "$file" | grep -q "adf4645f99f8e9a5b259d30f6b596f89")); then
    echo "$file was modified in Atmosphere!"
    exit 1
fi
replace_text "$search" "$replace" "$file"
#echo "printed header bs"
search='/* Set blocks. */'
replace='/* Set blocks. *//*'
replace_text "$search" "$replace" "$file"
#echo "printed blocks bs"
search='/* Set header hash. */'
replace='*//* Set header hash. */'
replace_text "$search" "$replace" "$file"
#echo "printed hash bs"
search='const bool should_blank = exosphere::ShouldBlankProdInfo();'
replace='const bool should_blank = true;'
replace_text "$search" "$replace" "$file"
search='bool allow_writes = exosphere::ShouldAllowWritesToProdInfo();'
replace='bool allow_writes = true;'
replace_text "$search" "$replace" "$file"
search='if (allow_writes && !has_secure_backup) {'
replace='if (false) {'
replace_text "$search" "$replace" "$file"
search='AMS_ABORT_UNLESS(!allow_writes || has_secure_backup);'
replace='//delete abort'
replace_text "$search" "$replace" "$file"
search='g_allow_writes      = allow_writes;'
replace='g_allow_writes      = true;'
replace_text "$search" "$replace" "$file"
search='g_has_secure_backup = has_secure_backup;'
replace='g_has_secure_backup = true;'
replace_text "$search" "$replace" "$file"
search='if (should_blank) {'
replace='if (true) {'
replace_text "$search" "$replace" "$file"
search='AMS_ABORT_UNLESS(should_blank == static_ca'
replace='//nuke abort'
replace_text "$search" "$replace" "$file"
echo "Patching complete! Compiling AMS..."	
toolDir=$(realpath ./)
cd ./Data/Atmosphere
make -j$(nproc)
cd $toolDir
echo "########################################################################"
echo "Done! See above logs for info!"
echo "THIS ATMOSPHERE BUILD WILL SPOOF YOUR PRODINFO ON SysMMC AND EmuMMC,"
echo "REGARDLESS OF EXOSPHERE.INI PRODINFO BLANKING SETTING"
echo ""
echo "YOU *MUST* USE TEGRAEXPLORER TO FULLY WIPE SAVEDATA BEFORE BOOTING"
echo "TO GO BACK TO YOUR ORIGINAL PRODINFO, JUST INSTALL NORMAL ATMOSPHERE"
echo "MAKE SURE TO BACKUP THE MMC YOU ARE USING THIS ON"
echo "YOU CANNOT GO BACK/FORTH BETWEEN PRODINFOS WITHOUT A FULL WIPE"
echo ""
echo "I RECOMMEND WIPING EmuMMC AND ONLY USING THIS BUILD ON EmuMMC"
echo "THAT WAY YOU DO NOT NEED TO WIPE YOUR SysMMC"
echo ""
echo "THIS BUILD DOES NOT PHYSICALLY OVERWRITE YOUR PRODINFO ON DISK"
echo "STILL, SYSTEM SERVICES BREAK IF PRODINFO IS CHANGED WITHOUT A WIPE"
echo ""
echo "I DO NOT KNOW HOW THIS BEHAVES ON MARIKO/OLED"
echo "USE CAUTION MIXING PRODINFO MODELS"
echo "YOU MAY STILL BE BANNED, THERE IS NO INSURANCE OR PROMISE THIS IS SAFE :)"
echo "########################################################################"
# Define the directory where the zip file is located
ZIP_DIR="./Data/Atmosphere/out/nintendo_nx_arm64_armv8a/release/"

# Define the directory where you want to unzip the contents
DEST_DIR="./sd_Card/"

# Find the zip file ending with "-dirty.zip"
ZIP_FILE=$(find "$ZIP_DIR" -maxdepth 1 -name "*-dirty.zip")

# Check if the zip file was found
if [ -n "$ZIP_FILE" ]; then
  # Create the destination directory if it doesn't exist
  mkdir -p "$DEST_DIR"

  # Unzip the file into the specified directory
  unzip "$ZIP_FILE" -d "$DEST_DIR"

  echo "Successfully unzipped '$ZIP_FILE' into '$DEST_DIR'"
else
  echo "No zip file found in '$ZIP_DIR' ending with '-dirty.zip'"
fi
