#!/usr/bin/env bash

#
#  (c) Copyright 2012-2014  Florian Müller (contact@petrockblock.com)
#
#  RetroPie-Setup homepage: https://github.com/petrockblog/RetroPie-Setup
#
#  Permission to use, copy, modify and distribute this work in both binary and
#  source form, for non-commercial purposes, is hereby granted without fee,
#  providing that this license information and copyright notice appear with
#  all copies and any derived work.
#
#  This software is provided 'as-is', without any express or implied
#  warranty. In no event shall the authors be held liable for any damages
#  arising from the use of this software.
#
#  RetroPie-Setup is freeware for PERSONAL USE only. Commercial users should
#  seek permission of the copyright holders first. Commercial use includes
#  charging money for RetroPie-Setup or software derived from RetroPie-Setup.
#
#  The copyright holders request that bug fixes and improvements to the code
#  should be forwarded to them so everyone can benefit from the modifications
#  in future versions.
#
#  Many, many thanks go to all people that provide the individual packages!!!
#



# 301, PackageRepository ---------------------

function install_PackageRepository() {
    # install repository helper package
    rps_checkNeededPackages reprepro

    # Create repository
    mkdir -p RetroPieRepo/conf
    cat >> RetroPieRepo/conf/distributions << _EOF_
Origin: apt.petrockblock.com
Label: apt repository
Codename: wheezy/rpi
Architectures: armhf other source
Components: main
Description: RetroPie Raspbian package repository
SignWith: yes
Pull: wheezy/rpi
_EOF_
}

# 302, SDL 2.0.1

function depen_sdl() {
    rps_checkNeededPackages libudev-dev libasound2-dev libdbus-1-dev libraspberrypi0 libraspberrypi-bin libraspberrypi-dev
}

function sources_sdl() {
    # These packages are listed in SDL2's "README-raspberrypi.txt" file as build dependencies.
    # If libudev-dev is not installed before compiling, the keyboard will mysteriously not work!
    # The rest should already be installed, but just to be safe, include them all.

    wget http://libsdl.org/release/SDL2-2.0.1.tar.gz
    mkdir -p "$rootdir/supplementary/"
    tar xvfz SDL2-2.0.1.tar.gz -C "$rootdir/supplementary/"
    rm SDL2-2.0.1.tar.gz || return 1
}

function build_sdl() {
    pushd "$rootdir/supplementary/SDL2-2.0.1" || return 1
    ./configure || return 1
    make || return 1
    popd || return 1
}

function install_sdl() {
    pushd "$rootdir/supplementary/SDL2-2.0.1" || return 1
    make install || return 1
    popd || return 1
}


# 303, Emulation Station ----------------------
function depen_emulationstation() {
    rps_checkNeededPackages \
        libboost-system-dev libboost-filesystem-dev libboost-date-time-dev \
        libfreeimage-dev libfreetype6-dev libeigen3-dev libcurl4-openssl-dev \
        libasound2-dev cmake g++-4.7
}

function sources_EmulationStation() {
    # sourced of EmulationStation
    gitPullOrClone "$rootdir/supplementary/EmulationStation" "https://github.com/Aloshi/EmulationStation" || return 1
    pushd "$rootdir/supplementary/EmulationStation" || return 1
    git pull || return 1
    git checkout unstable || return 1
    popd
}

function build_EmulationStation() {
    # EmulationStation
    pushd "$rootdir/supplementary/EmulationStation" || return 1
    cmake -D CMAKE_CXX_COMPILER=g++-4.7 . || return 1
    make || return 1
    popd
}

function install_EmulationStation() {
    cat > /usr/bin/emulationstation << _EOF_
#!/bin/bash

es_bin="$rootdir/supplementary/EmulationStation/emulationstation"

nb_lock_files=\$(find /tmp -name ".X?-lock" | wc -l)
if [ \$nb_lock_files -ne 0 ]; then
    echo "X is running. Please shut down X in order to mitigate problems with loosing keyboard input. For example, logout from LXDE."
    exit 1
fi

\$es_bin "\$@"
_EOF_
    chmod +x /usr/bin/emulationstation

    if [[ -f "$rootdir/supplementary/EmulationStation/emulationstation" ]]; then
        return 0
    else
        return 1
    fi

    # make sure that ES has enough GPU memory
    ensureKeyValueBootconfig "gpu_mem" 256 "/boot/config.txt"
    ensureKeyValueBootconfig "overscan_scale" 1 "/boot/config.txt"
}

function configure_EmulationStation() {
    if [[ $__netplayenable == "E" ]]; then
         local __tmpnetplaymode="-$__netplaymode "
         local __tmpnetplayhostip_cfile=$__netplayhostip_cfile
         local __tmpnetplayport="--port $__netplayport "
         local __tmpnetplayframes="--frames $__netplayframes"
     else
         local __tmpnetplaymode=""
         local __tmpnetplayhostip_cfile=""
         local __tmpnetplayport=""
         local __tmpnetplayframes=""
     fi

    mkdir -p "/etc/emulationstation"

    cat > "/etc/emulationstation/es_systems.cfg" << _EOF_
<systemList>

    <system>
        <fullname>Amiga</fullname>
        <name>amiga</name>
        <path>~/RetroPie/roms/amiga</path>
        <extension>.adf .ADF</extension>
        <command>$rootdir/emulators/uae4rpi/startAmigaDisk.sh %ROM%</command>
        <platform>amiga</platform>
        <theme>amiga</theme>
    </system>

    <system>
        <fullname>Apple II</fullname>
        <name>apple2</name>
        <path>~/RetroPie/roms/apple2</path>
        <extension>.txt</extension>
        <command>$rootdir/emulators/linapple-src_2a/Start.sh</command>
        <platform>apple2</platform>
        <theme>apple2</theme>
    </system>

    <system>
        <fullname>Atari 800</fullname>
        <name>atari800</name>
        <path>~/RetroPie/roms/atari800</path>
        <extension>.xex .XEX</extension>
        <command>$rootdir/supplementary/runcommand/runcommand.sh 1 "$rootdir/emulators/atari800-3.0.0/installdir/bin/atari800 %ROM%"</command>
        <platform>atari800</platform>
        <theme>atari800</theme>
    </system>

    <system>
        <fullname>Atari 2600</fullname>
        <name>atari2600</name>
        <path>~/RetroPie/roms/atari2600</path>
        <extension>.a26 .A26 .bin .BIN .rom .ROM .zip .ZIP .gz .GZ</extension>
        <!-- alternatively: <command>$rootdir/supplementary/runcommand/runcommand.sh 1 "stella %ROM%"</command> -->
        <command>$rootdir/supplementary/runcommand/runcommand.sh 1 "$rootdir/emulators/RetroArch/installdir/bin/retroarch -L `find $rootdir/emulatorcores/stella-libretro/ -name "*libretro*.so" | head -1` --config $rootdir/configs/all/retroarch.cfg --appendconfig $rootdir/configs/atari2600/retroarch.cfg $__tmpnetplaymode$__tmpnetplayhostip_cfile$__tmpnetplayport$__tmpnetplayframes %ROM%"</command>
        <platform>atari2600</platform>
        <theme>atari2600</theme>
    </system>

    <system>
        <fullname>Atari ST/STE/Falcon</fullname>
        <name>atariststefalcon</name>
        <path>~/RetroPie/roms/atariststefalcon</path>
        <extension>.st .ST .img .IMG .rom .ROM .ipf .IPF</extension>
        <command>$rootdir/supplementary/runcommand/runcommand.sh 1 "hatari %ROM%"</command>
        <platform>atarist</platform>
        <theme>atarist</theme>
    </system>

    <system>
        <fullname>Apple Macintosh</fullname>
        <name>macintosh</name>
        <path>~/RetroPie/roms/macintosh</path>
        <extension>.txt</extension>
        <!-- alternatively: <command>sudo modprobe snd_pcm_oss && xinit $rootdir/emulators/basiliskii/installdir/bin/BasiliskII</command> -->
        <!-- ~/.basilisk_ii_prefs: Setup all and everything under X, enable fullscreen and disable GUI -->
        <command>xinit $rootdir/emulators/basiliskii/installdir/bin/BasiliskII</command>
        <theme>macintosh</theme>
    </system>

    <system>
        <fullname>C64</fullname>
        <name>c64</name>
        <path>~/RetroPie/roms/c64</path>
        <extension>.crt .CRT .d64 .D64 .g64 .G64 .t64 .T64 .tap .TAP .x64 .X64 .zip .ZIP</extension>
        <command>$rootdir/supplementary/runcommand/runcommand.sh 4 "$rootdir/emulators/vice-2.4/installdir/bin/x64 -sdlbitdepth 16 %ROM%"</command>
        <platform>c64</platform>
        <theme>c64</theme>
    </system>

    <system>
        <fullname>Amstrad CPC</fullname>
        <name>amstradcpc</name>
        <path>~/RetroPie/roms/amstradcpc</path>
        <extension>.cpc .CPC .dsk .DSK</extension>
        <command>$rootdir/emulators/cpc4rpi-1.1/cpc4rpi %ROM%</command>
        <theme>amstradcpc</theme>
    </system>

    <system>
        <fullname>Final Burn Alpha</fullname>
        <name>fba</name>
        <path>~/RetroPie/roms/fba</path>
        <extension>.zip .ZIP .fba .FBA</extension>
        <command>$rootdir/supplementary/runcommand/runcommand.sh 1 "$rootdir/emulators/pifba/fba2x %ROM%" </command>
        <!-- alternatively: <command>$rootdir/supplementary/runcommand/runcommand.sh 1 "$rootdir/emulators/RetroArch/installdir/bin/retroarch -L `find $rootdir/emulatorcores/fba-libretro/ -name "*libretro*.so" | head -1` --config $rootdir/configs/all/retroarch.cfg --appendconfig $rootdir/configs/fba/retroarch.cfg $__tmpnetplaymode$__tmpnetplayhostip_cfile$__tmpnetplayport$__tmpnetplayframes %ROM%"</command> -->
        <platform>arcade</platform>
        <theme></theme>
    </system>

    <system>
        <fullname>Game Boy</fullname>
        <name>gb</name>
        <path>~/RetroPie/roms/gb</path>
        <extension>.gb .GB</extension>
        <command>$rootdir/supplementary/runcommand/runcommand.sh 1 "$rootdir/emulators/RetroArch/installdir/bin/retroarch -L `find $rootdir/emulatorcores/gambatte-libretro/libgambatte/ -name "*libretro*.so" | head -1` --config $rootdir/configs/all/retroarch.cfg --appendconfig $rootdir/configs/gb/retroarch.cfg %ROM%"</command>
        <platform>gb</platform>
        <theme>gb</theme>
    </system>

    <system>
        <fullname>Game Boy Advance</fullname>
        <name>gba</name>
        <path>~/RetroPie/roms/gba</path>
        <extension>.gba .GBA</extension>
        <command>$rootdir/supplementary/runcommand/runcommand.sh 4 "$rootdir/emulators/gpsp/raspberrypi/gpsp %ROM%"</command>
        <platform>gba</platform>
        <theme>gba</theme>
    </system>

    <system>
        <fullname>Game Boy Color</fullname>
        <name>gbc</name>
        <path>~/RetroPie/roms/gbc</path>
        <extension>.gbc .GBC</extension>
        <command>$rootdir/supplementary/runcommand/runcommand.sh 1 "$rootdir/emulators/RetroArch/installdir/bin/retroarch -L `find $rootdir/emulatorcores/gambatte-libretro/libgambatte/ -name "*libretro*.so" | head -1` --config $rootdir/configs/all/retroarch.cfg --appendconfig $rootdir/configs/gbc/retroarch.cfg %ROM%"</command>
        <platform>gbc</platform>
        <theme>gbc</theme>
    </system>

    <system>
        <fullname>Sega Game Gear</fullname>
        <name>gamegear</name>
        <path>~/RetroPie/roms/gamegear</path>
        <extension>.gg .GG</extension>
        <command>$rootdir/emulators/osmose-0.8.1+rpi20121122/osmose %ROM% -joy -tv -fs</command>
        <platform>gamegear</platform>
        <theme>gamegear</theme>
    </system>

    <system>
        <fullname>Intellivision</fullname>
        <name>intellivision</name>
        <path>~/RetroPie/roms/intellivision</path>
        <extension>.int .INT .bin .BIN</extension>
        <command>$rootdir/emulators/jzintv-1.0-beta4/bin/jzintv -z1 -f1 -q %ROM%</command>
        <platform>intellivision</platform>
        <theme></theme>
    </system>

    <system>
        <fullname>MAME</fullname>
        <name>mame</name>
        <path>~/RetroPie/roms/mame</path>
        <extension>.zip .ZIP</extension>
        <command>$rootdir/supplementary/runcommand/runcommand.sh 4 "$rootdir/emulators/mame4all-pi/mame %BASENAME%"</command>
        <!-- alternatively: <command>$rootdir/emulators/RetroArch/installdir/bin/retroarch -L `find $rootdir/emulatorcores/imame4all-libretro/ -name "*libretro*.so" | head -1` --config $rootdir/configs/all/retroarch.cfg --appendconfig $rootdir/configs/mame/retroarch.cfg %ROM% </command> -->
        <platform>arcade</platform>
        <theme>mame</theme>
    </system>

    <system>
        <fullname>MSX</fullname>
        <name>msx</name>
        <path>~/RetroPie/roms/msx</path>
        <extension>.rom .ROM</extension>
        <command>$rootdir/supplementary/runcommand/runcommand.sh 4 "$rootdir/emulators/openmsx-0.10.0/derived/arm-linux-opt/bin/openmsx %BASENAME%"</command>
        <platform></platform>
        <theme>msx</theme>
    </system>

    <system>
        <fullname>PC (x86)</fullname>
        <name>pc</name>
        <path>~/RetroPie/roms/pc</path>
        <extension>.txt</extension>
        <command>$rootdir/emulators/rpix86/Start.sh</command>
        <platform>pc</platform>
        <theme>pc</theme>
    </system>

    <system>
        <fullname>NeoGeo</fullname>
        <name>neogeo</name>
        <path>~/RetroPie/roms/neogeo</path>
        <extension>.zip .ZIP .fba .FBA</extension>
        <command>$rootdir/supplementary/runcommand/runcommand.sh 1 "$rootdir/emulators/pifba/fba2x %ROM%" </command>
        <!-- alternatively: <command>$rootdir/emulators/gngeo-pi-0.85/installdir/bin/arm-linux-gngeo -i $rootdir/roms/neogeo -B $rootdir/emulators/gngeo-pi-0.85/neogeobios %ROM%</command> -->
        <platform>neogeo</platform>
        <theme>neogeo</theme>
    </system>

    <system>
        <fullname>Nintendo Entertainment System</fullname>
        <name>nes</name>
        <path>~/RetroPie/roms/nes</path>
        <extension>.nes .NES</extension>
        <command>$rootdir/supplementary/runcommand/runcommand.sh 4 "$rootdir/emulators/RetroArch/installdir/bin/retroarch -L `find $rootdir/emulatorcores/fceu-next/fceumm-code/ -name "*libretro*.so" | head -1` --config $rootdir/configs/all/retroarch.cfg --appendconfig $rootdir/configs/nes/retroarch.cfg $__tmpnetplaymode$__tmpnetplayhostip_cfile$__tmpnetplayport$__tmpnetplayframes %ROM%"</command>
        <platform>nes</platform>
        <theme>nes</theme>
    </system>

    <system>
        <fullname>Nintendo 64</fullname>
        <name>n64</name>
        <path>~/RetroPie/roms/n64</path>
        <extension>.z64 .Z64 .n64 .N64 .v64 .V64</extension>
        <command>$rootdir/supplementary/runcommand/runcommand.sh 1 "cd $rootdir/emulators/mupen64plus-rpi/test/ && ./mupen64plus %ROM%"</command>
        <platform>n64</platform>
        <theme>n64</theme>
    </system>

    <system>
        <fullname>TurboGrafx 16 (PC Engine)</fullname>
        <name>pcengine</name>
        <path>~/RetroPie/roms/pcengine</path>
        <extension>.pce .PCE</extension>
        <command>$rootdir/supplementary/runcommand/runcommand.sh 1 "$rootdir/emulators/RetroArch/installdir/bin/retroarch -L `find $rootdir/emulatorcores/mednafen-pce-libretro/ -name "*libretro*.so" | head -1` --config $rootdir/configs/all/retroarch.cfg --appendconfig $rootdir/configs/pcengine/retroarch.cfg %ROM%"</command>
        <!-- alternatively: <command>$rootdir/supplementary/runcommand/runcommand.sh 1 "$rootdir/emulators/RetroArch/installdir/bin/retroarch -L `find $rootdir/emulatorcores/mednafenpcefast/ -name "*libretro*.so" | head -1` --config $rootdir/configs/all/retroarch.cfg --appendconfig $rootdir/configs/pcengine/retroarch.cfg %ROM%"</command> -->
        <platform>pcengine</platform>
        <theme>pcengine</theme>
    </system>

    <system>
        <fullname>Ports</fullname>
        <name>ports</name>
        <path>~/RetroPie/roms/ports</path>
        <extension>.sh .SH</extension>
        <command>%ROM%</command>
        <platformid>pc</platformid>
        <theme>ports</theme>
    </system>

    <system>
        <fullname>ScummVM</fullname>
        <name>scummvm</name>
        <path>~/RetroPie/roms/scummvm</path>
        <extension>.exe .EXE</extension>
        <command>scummvm</command>
        <platform>pc</platform>
        <theme>scummvm</theme>
    </system>

    <system>
        <fullname>Sega Master System / Mark III</fullname>
        <name>mastersystem</name>
        <path>~/RetroPie/roms/mastersystem</path>
        <extension>.sms .SMS</extension>
        <command>$rootdir/supplementary/runcommand/runcommand.sh 4 "$rootdir/emulators/RetroArch/installdir/bin/retroarch -L `find $rootdir/emulatorcores/picodrive/ -name "*libretro*.so" | head -1` --config $rootdir/configs/all/retroarch.cfg --appendconfig $rootdir/configs/mastersystem/retroarch.cfg $__tmpnetplaymode$__tmpnetplayhostip_cfile$__tmpnetplayport$__tmpnetplayframes %ROM%"</command>
        <!-- alternatively: <command>$rootdir/emulators/osmose-0.8.1+rpi20121122/osmose %ROM% -joy -tv -fs</command> -->
        <platform>mastersystem</platform>
        <theme>mastersystem</theme>
    </system>

    <system>
        <fullname>Sega Mega Drive / Genesis</fullname>
        <name>megadrive</name>
        <path>~/RetroPie/roms/megadrive</path>
        <extension>.smd .SMD .bin .BIN .gen .GEN .md .MD .zip .ZIP</extension>
        <command>$rootdir/supplementary/runcommand/runcommand.sh 4 "$rootdir/emulators/RetroArch/installdir/bin/retroarch -L `find $rootdir/emulatorcores/picodrive/ -name "*libretro*.so" | head -1` --config $rootdir/configs/all/retroarch.cfg --appendconfig $rootdir/configs/megadrive/retroarch.cfg $__tmpnetplaymode$__tmpnetplayhostip_cfile$__tmpnetplayport$__tmpnetplayframes %ROM%"</command>
        <!-- alternatively: <command>$rootdir/supplementary/runcommand/runcommand.sh 1 "$rootdir/emulators/dgen-sdl/installdir/bin/dgen -f -r $rootdir/configs/all/dgenrc %ROM%"</command> -->
        <!-- alternatively: <command>export LD_LIBRARY_<path>"$rootdir/supplementary/dispmanx/SDL12-kms-dispmanx/build/.libs"; $rootdir/emulators/dgen-sdl/dgen %ROM%</path></command> -->
        <platform>genesis,megadrive</platform>
        <theme>megadrive</theme>
    </system>

    <system>
        <fullname>Sega CD</fullname>
        <name>segacd</name>
        <path>~/RetroPie/roms/segacd</path>
        <extension>.smd .SMD .bin .BIN .md .MD .zip .ZIP .iso .ISO</extension>
        <command>$rootdir/supplementary/runcommand/runcommand.sh 1 "$rootdir/emulators/RetroArch/installdir/bin/retroarch -L $rootdir/emulatorcores/picodrive/picodrive_libretro.so --config $rootdir/configs/all/retroarch.cfg --appendconfig $rootdir/configs/segacd/retroarch.cfg  %ROM%"</command>
        <!-- <command>$rootdir/supplementary/runcommand/runcommand.sh 1 "$rootdir/emulators/dgen-sdl/dgen -f -r $rootdir/configs/all/dgenrc %ROM%"</command> -->
        <!-- <command>export LD_LIBRARY_<path>"$rootdir/supplementary/dispmanx/SDL12-kms-dispmanx/build/.libs"; $rootdir/emulators/dgen-sdl/dgen %ROM%</path></command> -->
        <platform>segacd</platform>
        <theme>segacd</theme>
    </system>

    <system>
        <fullname>Sega 32X</fullname>
        <name>sega32x</name>
        <path>~/RetroPie/roms/sega32x</path>
        <extension>.32x .32X .smd .SMD .bin .BIN .md .MD .zip .ZIP</extension>
        <command>$rootdir/supplementary/runcommand/runcommand.sh 1 "$rootdir/emulators/RetroArch/installdir/bin/retroarch -L $rootdir/emulatorcores/picodrive/picodrive_libretro.so --config $rootdir/configs/all/retroarch.cfg --appendconfig $rootdir/configs/sega32x/retroarch.cfg  %ROM%"</command>
        <!-- <command>$rootdir/supplementary/runcommand/runcommand.sh 1 "$rootdir/emulators/dgen-sdl/dgen -f -r $rootdir/configs/all/dgenrc %ROM%"</command> -->
        <!-- <command>export LD_LIBRARY_<path>"$rootdir/supplementary/dispmanx/SDL12-kms-dispmanx/build/.libs"; $rootdir/emulators/dgen-sdl/dgen %ROM%</path></command> -->
        <platform>sega32x</platform>
        <theme>sega32x</theme>
    </system>

    <system>
        <fullname>Sony Playstation 1</fullname>
        <name>psx</name>
        <path>~/RetroPie/roms/psx</path>
        <extension>.img .IMG .7z .7Z .pbp .PBP .bin .BIN .cue .CUE</extension>
        <command>$rootdir/supplementary/runcommand/runcommand.sh 1 "$rootdir/emulators/RetroArch/installdir/bin/retroarch -L `find $rootdir/emulatorcores/pcsx_rearmed/ -name "*libretro*.so" | head -1` --config $rootdir/configs/all/retroarch.cfg --appendconfig $rootdir/configs/psx/retroarch.cfg %ROM%"</command>
        <platform>psx</platform>
        <theme>psx</theme>
    </system>

    <system>
        <fullname>Super Nintendo</fullname>
        <name>snes</name>
        <path>~/RetroPie/roms/snes</path>
        <extension>.smc .sfc .fig .swc .SMC .SFC .FIG .SWC</extension>
        <command>$rootdir/supplementary/runcommand/runcommand.sh 4 "$rootdir/emulators/RetroArch/installdir/bin/retroarch -L `find $rootdir/emulatorcores/pocketsnes-libretro/ -name "*libretro*.so" | head -1` --config $rootdir/configs/all/retroarch.cfg --appendconfig $rootdir/configs/snes/retroarch.cfg $__tmpnetplaymode$__tmpnetplayhostip_cfile $__tmpnetplayport$__tmpnetplayframes %ROM%"</command>
        <!-- alternatively: <command>$rootdir/emulators/snes9x-rpi/snes9x %ROM%</command> -->
        <!-- alternatively: <command>$rootdir/emulators/pisnes/snes9x %ROM%</command> -->
        <platform>snes</platform>
        <theme>snes</theme>
    </system>

    <system>
        <fullname>ZX Spectrum</fullname>
        <name>zxspectrum</name>
        <path>~/RetroPie/roms/zxspectrum</path>
        <extension>.z80 .Z80 .ipf .IPF</extension>
        <command>xinit fuse</command>
        <!-- alternatively: <command>$rootdir/emulators/fbzx-2.10.0/fbzx %ROM%</command> -->
        <platform>zxspectrum</platform>
        <theme>zxspectrum</theme>
    </system>

    <system>
        <fullname>Input Configuration</fullname>
        <name>esconfig</name>
        <path>~/RetroPie/roms/esconfig</path>
        <extension>.py .PY</extension>
        <command>%ROM%</command>
        <platform>ignore</platform>
        <theme>esconfig</theme>
    </system>

</systemList>
_EOF_
chmod 755 "/etc/emulationstation/es_systems.cfg"

}

function package_EmulationStation() {
    local PKGNAME

    rps_checkNeededPackages reprepro

    printMsg "Building package of EmulationStation"

#   # create Raspbian package
#   $PKGNAME="retropie-supplementary-emulationstation"
#   mkdir $PKGNAME
#   mkdir $PKGNAME/DEBIAN
#   cat >> $PKGNAME/DEBIAN/control << _EOF_
# Package: $PKGNAME
# Priority: optional
# Section: devel
# Installed-Size: 1
# Maintainer: Florian Mueller
# Architecture: armhf
# Version: 1.0
# Depends: libboost-system-dev libboost-filesystem-dev libboost-date-time-dev libfreeimage-dev libfreetype6-dev libeigen3-dev libcurl4-openssl-dev libasound2-dev cmake g++-4.7
# Description: This package contains the front-end EmulationStation.
# _EOF_

#   mkdir -p $PKGNAME/usr/share/RetroPie/supplementary/EmulationStation
#   cd
#   cp -r $rootdir/supplementary/EmulationStation/emulationstation $PKGNAME$rootdir/supplementary/EmulationStation/

#   # create package
#   dpkg-deb -z8 -Zgzip --build $PKGNAME

#   # sign Raspbian package
#   dpkg-sig --sign builder $PKGNAME.deb

#   # add package to repository
#   cd RetroPieRepo
#   reprepro --ask-passphrase -Vb . includedeb wheezy /home/pi/$PKGNAME.deb

}

# 304, install_ESThemeSimple
function install_ESThemeSimple() {
    wget -O themesDownload.tar.bz2 http://blog.petrockblock.com/?wpdmdl=7118

    tar xvfj themesDownload.tar.bz2
    rm themesDownload.tar.bz2
    if [[ ! -d "/etc/emulationstation/themes" ]]; then
        mkdir -p "/etc/emulationstation/themes"
    fi
    rmDirExists "/etc/emulationstation/themes/simple"
    mv -f simple/ "/etc/emulationstation/themes/"

    chmod -R 755 "/etc/emulationstation/themes/"
}

function install_runcommand() {
    mkdir -p "$rootdir/supplementary/runcommand/"
    cp $scriptdir/supplementary/runcommand.sh "$rootdir/supplementary/runcommand/"
    chmod +x "$rootdir/supplementary/runcommand/runcommand.sh"
}

function sources_snesdev() {
    gitPullOrClone "$rootdir/supplementary/SNESDev-Rpi" git://github.com/petrockblog/SNESDev-RPi.git
}

function build_snesdev() {
    pushd "$rootdir/supplementary/SNESDev-Rpi"
    ./build.sh
    popd
}

function install_snesdev() {
    if [[ ! -f "$rootdir/supplementary/SNESDev-Rpi/SNESDev" ]]; then
        __ERRMSGS="$__ERRMSGS Could not successfully compile SNESDev."
    else
        service SNESDev stop
        cp "$rootdir/supplementary/SNESDev-Rpi/SNESDev" /usr/local/bin/
    fi
    cp "$rootdir/supplementary/SNESDev-Rpi/supplementary/snesdev.cfg" /etc/
}

# start SNESDev on boot and configure RetroArch input settings
function sup_enableSNESDevAtStart()
{
    clear
    printMsg "Enabling SNESDev on boot."

    if [[ ! -f "/etc/init.d/SNESDev" ]]; then
        if [[ ! -f "$rootdir/supplementary/SNESDev-Rpi/SNESDev" ]]; then
            dialog --backtitle "PetRockBlock.com - RetroPie Setup. Installation folder: $rootdir for user $user" --msgbox "Cannot find SNESDev binary. Please install SNESDev." 22 76
            return
        else
            echo "Copying service script for SNESDev to /etc/init.d/ ..."
            chmod +x "$rootdir/supplementary/SNESDev-Rpi/scripts/SNESDev"
            cp "$rootdir/supplementary/SNESDev-Rpi/scripts/SNESDev" /etc/init.d/
        fi
    fi

    echo "Copying SNESDev to /usr/local/bin/ ..."
    cp "$rootdir/supplementary/SNESDev-Rpi/SNESDev" /usr/local/bin/

    case $1 in
      1)
        ensureKeyValueBootconfig "button_enabled" "0" "/etc/snesdev.cfg"
        ensureKeyValueBootconfig "gamepad1_enabled" "1" "/etc/snesdev.cfg"
        ensureKeyValueBootconfig "gamepad2_enabled" "1" "/etc/snesdev.cfg"
        ;;
      2)
        ensureKeyValueBootconfig "button_enabled" "1" "/etc/snesdev.cfg"
        ensureKeyValueBootconfig "gamepad1_enabled" "0" "/etc/snesdev.cfg"
        ensureKeyValueBootconfig "gamepad2_enabled" "0" "/etc/snesdev.cfg"
        ;;
      3)
        ensureKeyValueBootconfig "button_enabled" "1" "/etc/snesdev.cfg"
        ensureKeyValueBootconfig "gamepad1_enabled" "1" "/etc/snesdev.cfg"
        ensureKeyValueBootconfig "gamepad2_enabled" "1" "/etc/snesdev.cfg"
        ;;
      *)
        echo "[sup_enableSNESDevAtStart] I do not understand what is going on here."
        ;;
    esac

    # This command installs the init.d script so it automatically starts on boot
    update-rc.d SNESDev defaults
    # This command starts the daemon now so no need for a reboot
    service SNESDev start
}

# disable start SNESDev on boot and remove RetroArch input settings
function sup_disableSNESDevAtStart()
{
    clear
    printMsg "Disabling SNESDev on boot."

    # This command stops the daemon now so no need for a reboot
    service SNESDev stop

    # This command installs the init.d script so it automatically starts on boot
    update-rc.d SNESDev remove
}

function configure_snesdev() {
    cmd=(dialog --backtitle "PetRockBlock.com - RetroPie Setup. Installation folder: $rootdir for user $user" --menu "Choose the desired boot behaviour." 22 86 16)
    options=(1 "Disable SNESDev on boot and SNESDev keyboard mapping."
             2 "Enable SNESDev on boot and SNESDev keyboard mapping (polling pads and button)."
             3 "Enable SNESDev on boot and SNESDev keyboard mapping (polling only pads)."
             4 "Enable SNESDev on boot and SNESDev keyboard mapping (polling only button).")
    choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    if [ "$choices" != "" ]; then
        case $choices in
            1) sup_disableSNESDevAtStart
               dialog --backtitle "PetRockBlock.com - RetroPie Setup. Installation folder: $rootdir for user $user" --msgbox "Disabled SNESDev on boot." 22 76
                            ;;
            2) sup_enableSNESDevAtStart 3
               dialog --backtitle "PetRockBlock.com - RetroPie Setup. Installation folder: $rootdir for user $user" --msgbox "Enabled SNESDev on boot (polling pads and button)." 22 76
                            ;;
            3) sup_enableSNESDevAtStart 1
               dialog --backtitle "PetRockBlock.com - RetroPie Setup. Installation folder: $rootdir for user $user" --msgbox "Enabled SNESDev on boot (polling only pads)." 22 76
                            ;;
            4) sup_enableSNESDevAtStart 2
               dialog --backtitle "PetRockBlock.com - RetroPie Setup. Installation folder: $rootdir for user $user" --msgbox "Enabled SNESDev on boot (polling only button)." 22 76
                            ;;
        esac
    else
        break
    fi
}

function sources_xarcade2jstick() {
    gitPullOrClone "$rootdir/supplementary/Xarcade2Jstick/" https://github.com/petrockblog/Xarcade2Joystick.git
}

function build_xarcade2jstick() {
    pushd "$rootdir/supplementary/Xarcade2Jstick/"
    make
    popd
}

function install_xarcade2jstick() {
    pushd "$rootdir/supplementary/Xarcade2Jstick/"
    make install
    popd
}

function sup_checkInstallXarcade2Jstick() {
    if [[ ! -d $rootdir/supplementary/Xarcade2Jstick ]]; then
        sources_xarcade2jstick
        build_xarcade2jstick
        install_xarcade2jstick
    fi
}

function configure_xarcade2jstick() {
    cmd=(dialog --backtitle "PetRockBlock.com - RetroPie Setup. Installation folder: $rootdir for user $user" --menu "Choose the desired boot behaviour." 22 86 16)
    options=(1 "Disable Xarcade2Jstick service."
             2 "Enable Xarcade2Jstick service." )
    choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    if [ "$choices" != "" ]; then
        case $choices in
            1) sup_checkInstallXarcade2Jstick
               pushd "$rootdir/supplementary/Xarcade2Jstick/"
               make uninstallservice
               popd
               dialog --backtitle "PetRockBlock.com - RetroPie Setup. Installation folder: $rootdir for user $user" --msgbox "Disabled Xarcade2Jstick." 22 76
                            ;;
            2) sup_checkInstallXarcade2Jstick
               pushd "$rootdir/supplementary/Xarcade2Jstick/"
               make installservice
               popd
               dialog --backtitle "PetRockBlock.com - RetroPie Setup. Installation folder: $rootdir for user $user" --msgbox "Enabled Xarcade2Jstick service." 22 76
                            ;;
        esac
    else
        break
    fi
}

function install_retroarchautoconf() {
    if [[ ! -d "$rootdir/emulators/RetroArch/configs/" ]]; then
        mkdir -p "$rootdir/emulators/RetroArch/configs/"
    fi
    cp $scriptdir/supplementary/RetroArchConfigs/*.cfg "$rootdir/emulators/RetroArch/configs/"
}

function install_bashwelcometweak() {
    printMsg "Installing Bash Welcome Tweak"

    if [[ -z `cat "/home/$user/.bashrc" | grep "# RETROPIE PROFILE START"` ]]; then
        cat $scriptdir/supplementary/ProfileTweak >> "/home/$user/.bashrc"
    fi
}

function set_ensureEntryInSMBConf()
{
    comp=`cat /etc/samba/smb.conf | grep "\[$1\]"`
    if [ "$comp" == "[$1]" ]; then
      echo "$1 already contained in /etc/samba/smb.conf."
    else
    tee -a /etc/samba/smb.conf <<_EOF_
[$1]
comment = $1
path = $2
writeable = yes
guest ok = yes
create mask = 0644
directory mask = 0755
force user = $user
_EOF_
    fi
}

function install_sambashares() {
    rps_checkNeededPackages samba samba-common-bin
}

function configure_sambashares() {
    # remove old configs
    sed -i '/\[[A-Z]\]*/,$d' /etc/samba/smb.conf

    set_ensureEntryInSMBConf "roms" "$romdir"

    # enforce rom directory permissions - root:$user for roms folder with the sticky bit set,
    # and root:$user for first level subfolders with group writable. This allows them to be
    # writable by the pi user, yet avoid being deleted by accident
    chown root:$user "$romdir" "$romdir"/*
    chmod g+w "$romdir"/*
    chmod +t "$romdir"

    printMsg "Resetting ownershop on existing files to user: $user"
    chown -R $user:$user "$romdir"/*/*

    /etc/init.d/samba restart
}

function install_usbromservice() {
    # install usbmount package
    rps_checkNeededPackages usbmount
}

function configure_usbromservice() {
    # install hook in usbmount sub-directory
    cp $scriptdir/supplementary/01_retropie_copyroms /etc/usbmount/mount.d/
    sed -i -e "s/USERTOBECHOSEN/$user/g" /etc/usbmount/mount.d/01_retropie_copyroms
    chmod +x /etc/usbmount/mount.d/01_retropie_copyroms
}

function set_enableSplashscreenAtStart()
{
    clear
    printMsg "Enabling custom splashscreen on boot."

    rps_checkNeededPackages fbi

    chmod +x "$scriptdir/supplementary/asplashscreen/asplashscreen"
    cp "$scriptdir/supplementary/asplashscreen/asplashscreen" "/etc/init.d/"

    echo $(find $scriptdir/supplementary/splashscreens/retropieproject2014/ -type f) > /etc/splashscreen.list

    # This command installs the init.d script so it automatically starts on boot
    update-rc.d asplashscreen defaults

    # not-so-elegant hack for later re-enabling the splashscreen
    update-rc.d asplashscreen enable

#     # ===========================================
#     # TODO Alternatively use plymouth. However, this does not work completely. So there is still some work to be done here ...
#     # instructions at https://github.com/notro/fbtft/wiki/FBTFT-shield-image#bootsplash
#     apt-get install -y plymouth-drm

#     echo "export FRAMEBUFFER=/dev/fb1" | tee /etc/initramfs-tools/conf.d/fb1

#     if [[ ! -f /boot/$(uname -r) ]]; then
#         update-initramfs -c -k $(uname -r)
#     else
#         update-initramfs -u -k $(uname -r)
#     fi
#     imgname=$(echo "update-initramfs: Generating /boot/initrd.img-3.12.20+" | sed "s|update-initramfs: Generating /boot/||g")
#     echo "initramfs=$imgname" >> /boot/config.txt

#     echo "splash quiet plymouth.ignore-serial-consoles $(cat /boot/cmdline.txt)" > tempcmdline.txt
#     cp /boot/cmdline.txt /boot/cmdline.txt.bak
#     mv tempcmdline.txt /boot/cmdline.txt

#     mkdir -p "/usr/share/plymouth/themes/retropie"
#     cat > "/usr/share/plymouth/themes/retropie/retropie.plymouth" << _EOF_
# [Plymouth Theme]
# Name=RetroPie Theme
# Description=RetroPie Theme
# ModuleName=script

# [script]
# ImageDir=/usr/share/plymouth/themes/retropie
# ScriptFile=/usr/share/plymouth/themes/retropie/retropie.script
# _EOF_

#     cat > "/usr/share/plymouth/themes/retropie/retropie.script" << _EOF_
# # only PNG is supported
# pi_image = Image("splashscreen.png");

# screen_ratio = Window.GetHeight() / Window.GetWidth();
# pi_image_ratio = pi_image.GetHeight() / pi_image.GetWidth();

# if (screen_ratio > pi_image_ratio)
#   {  # Screen ratio is taller than image ratio, we will match the screen width
#      scale_factor =  Window.GetWidth() / pi_image.GetWidth();
#   }
# else
#   {  # Screen ratio is wider than image ratio, we will match the screen height
#      scale_factor =  Window.GetHeight() / pi_image.GetHeight();
#   }

# scaled_pi_image = pi_image.Scale(pi_image.GetWidth()  * scale_factor, pi_image.GetHeight() * scale_factor);
# pi_sprite = Sprite(scaled_pi_image);

# # Place in the centre
# pi_sprite.SetX(Window.GetWidth()  / 2 - scaled_pi_image.GetWidth () / 2);
# pi_sprite.SetY(Window.GetHeight() / 2 - scaled_pi_image.GetHeight() / 2);
# _EOF_

#     plymouth-set-default-theme -R retropie
#     # =============================
}

function set_disableSplashscreenAtStart()
{
    clear
    printMsg "Disabling custom splashscreen on boot."

    update-rc.d asplashscreen disable

    # # TODO plymouth command. Not used yet ...
    # sed -i 's|splash quiet plymouth.ignore-serial-consoles ||g' /boot/cmdline.txt
}

function configure_splashenable() {
    cmd=(dialog --backtitle "PetRockBlock.com - RetroPie Setup. Installation folder: $rootdir for user $user" --menu "Choose the desired boot behaviour." 22 86 16)
    options=(1 "Disable custom splashscreen on boot."
             2 "Enable custom splashscreen on boot")
    choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    if [ "$choices" != "" ]; then
        case $choices in
            1) set_disableSplashscreenAtStart
               dialog --backtitle "PetRockBlock.com - RetroPie Setup. Installation folder: $rootdir for user $user" --msgbox "Disabled custom splashscreen on boot." 22 76
                            ;;
            2) set_enableSplashscreenAtStart
               dialog --backtitle "PetRockBlock.com - RetroPie Setup. Installation folder: $rootdir for user $user" --msgbox "Enabled custom splashscreen on boot." 22 76
                            ;;
        esac
    else
        break
    fi
}

function configure_splashscreen() {
    printMsg "Configuring splashscreen"

    local options
    local ctr

    ctr=0
    pushd $scriptdir/supplementary/splashscreens/ > /dev/null
    options=()
    dirlist=()
    for splashdir in $(find . -type d | sort) ; do
        if [[ $splashdir != "." ]]; then
            options+=($ctr "${splashdir:2}")
            dirlist+=(${splashdir:2})
            ctr=$((ctr + 1))
        fi
    done
    popd > /dev/null
    cmd=(dialog --backtitle "PetRockBlock.com - RetroPie Setup. Installation folder: $rootdir for user $user" --menu "Choose splashscreen." 22 76 16)
    __ERRMSGS=""
    __INFMSGS=""
    choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    splashdir=${dirlist[$choices]}
    if [ "$choices" != "" ]; then
        rm /etc/splashscreen.list
        find $scriptdir/supplementary/splashscreens/$splashdir/ -type f | sort | while read line; do
            echo $line >> /etc/splashscreen.list
        done
        dialog --backtitle "PetRockBlock.com - RetroPie Setup. Installation folder: $rootdir for user $user" --msgbox "Splashscreen set to '$splashdir'." 20 60
    fi
}

function configure_retronetplay() {
    ipaddress_int=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
    ipaddress_ext=$(curl http://ipecho.net/plain; echo)
    while true; do
        cmd=(dialog --backtitle "PetRockBlock.com - RetroPie Setup. Installation folder: $rootdir for user $user" --menu "Configure RetroArch Netplay.\nInternal IP: $ipaddress_int\nExternal IP: $ipaddress_ext" 22 76 16)
        options=(1 "(E)nable/(D)isable RetroArch Netplay. Currently: $__netplayenable"
                 2 "Set mode, (H)ost or (C)lient. Currently: $__netplaymode"
                 3 "Set port. Currently: $__netplayport"
                 4 "Set host IP address (for client mode). Currently: $__netplayhostip"
                 5 "Set delay frames. Currently: $__netplayframes" )
        choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        if [ "$choices" != "" ]; then
            case $choices in
                 1) rps_retronet_enable ;;
                 2) rps_retronet_mode ;;
                 3) rps_retronet_port ;;
                 4) rps_retronet_hostip ;;
                 5) rps_retronet_frames ;;
            esac
        else
            break
        fi
    done
}

function rps_retronet_enable() {
    cmd=(dialog --backtitle "PetRockBlock.com - RetroPie Setup. Installation folder: $rootdir for user $user" --menu "Enable or disable RetroArch's Netplay mode." 22 76 16)
    options=(1 "ENABLE netplay"
             2 "DISABLE netplay" )
    choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    if [ "$choices" != "" ]; then
        case $choices in
             1) __netplayenable="E"
                ;;
             2) __netplayenable="D"
                ;;
        esac
        rps_retronet_saveconfig
        sup_generate_esconfig
    fi
}

function rps_retronet_mode() {
    cmd=(dialog --backtitle "PetRockBlock.com - RetroPie Setup. Installation folder: $rootdir for user $user" --menu "Please set the netplay mode." 22 76 16)
    options=(1 "Set as HOST"
             2 "Set as CLIENT" )
    choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    if [ "$choices" != "" ]; then
        case $choices in
             1) __netplaymode="H"
                __netplayhostip_cfile=""
                ;;
             2) __netplaymode="C"
                __netplayhostip_cfile="$__netplayhostip"
                ;;
        esac
        rps_retronet_saveconfig
        sup_generate_esconfig
    fi
}

function rps_retronet_port() {
    cmd=(dialog --backtitle "PetRockBlock.com - RetroPie Setup. Installation folder: $rootdir for user $user" --inputbox "Please enter the port to be used for netplay (default: 55435)." 22 76 $__netplayport)
    choices=$("${cmd[@]}" 2>&1 >/dev/tty)
    if [ "$choices" != "" ]; then
        __netplayport=$choices
        rps_retronet_saveconfig
        sup_generate_esconfig
    fi
}

function rps_retronet_hostip() {
    cmd=(dialog --backtitle "PetRockBlock.com - RetroPie Setup. Installation folder: $rootdir for user $user" --inputbox "Please enter the IP address of the host." 22 76 $__netplayhostip)
    choices=$("${cmd[@]}" 2>&1 >/dev/tty)
    if [ "$choices" != "" ]; then
        __netplayhostip=$choices
        if [[ $__netplaymode == "H" ]]; then
            __netplayhostip_cfile=""
        else
            __netplayhostip_cfile="$__netplayhostip"
        fi
        rps_retronet_saveconfig
        sup_generate_esconfig
    fi
}

function rps_retronet_frames() {
    cmd=(dialog --backtitle "PetRockBlock.com - RetroPie Setup. Installation folder: $rootdir for user $user" --inputbox "Please enter the number of delay frames for netplay (default: 15)." 22 76 $__netplayframes)
    choices=$("${cmd[@]}" 2>&1 >/dev/tty)
    if [ "$choices" != "" ]; then
        __netplayframes=$choices
        rps_retronet_saveconfig
        sup_generate_esconfig
    fi
}

function rps_retronet_saveconfig() {
    echo -e "__netplayenable=\"$__netplayenable\"\n__netplaymode=\"$__netplaymode\"\n__netplayport=\"$__netplayport\"\n__netplayhostip=\"$__netplayhostip\"\n__netplayhostip_cfile=\"$__netplayhostip_cfile\"\n__netplayframes=\"$__netplayframes\"" > $scriptdir/configs/retronetplay.cfg
}

function install_modules() {
    modprobe uinput
    modprobe joydev

    for module in uinput joydev; do
        if ! grep -q "$module" /etc/modules; then
            addLineToFile "$module" "/etc/modules"
        else
            echo -e "$module module already contained in /etc/modules"
        fi
    done
}

function install_setavoidsafemode() {
    ensureKeyValueBootconfig "avoid_safe_mode" 1 "/boot/config.txt"
}

function install_disabletimeouts() {
    sed -i 's/BLANK_TIME=30/BLANK_TIME=0/g' /etc/kbd/config
    sed -i 's/POWERDOWN_TIME=30/POWERDOWN_TIME=0/g' /etc/kbd/config
}

function install_handleaptpackages() {
    # remove PulseAudio since this is slowing down the whole system significantly. Cups is also not needed
    apt-get remove -y pulseaudio cups wolfram-engine
    apt-get -y autoremove
}

function configure_autostartemustat() {
    cmd=(dialog --backtitle "PetRockBlock.com - RetroPie Setup. Installation folder: $rootdir for user $user" --menu "Choose the desired boot behaviour." 22 76 16)
    options=(1 "Original boot behaviour"
             2 "Start Emulation Station at boot.")
    choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    if [ "$choices" != "" ]; then
        case $choices in
            1) sed /etc/inittab -i -e "s|1:2345:respawn:/bin/login -f $user tty1 </dev/tty1 >/dev/tty1 2>&1|1:2345:respawn:/sbin/getty --noclear 38400 tty1|g"
               sed /etc/profile -i -e "/emulationstation/d"
               dialog --backtitle "PetRockBlock.com - RetroPie Setup. Installation folder: $rootdir for user $user" --msgbox "Enabled original boot behaviour. ATTENTION: If you still have the custom splash screen enabled (via this script), you need to jump between consoles after booting via Ctrl+Alt+F2 and Ctrl+Alt+F1 to see the login prompt. You can restore the original boot behavior of the RPi by disabling the custom splash screen with this script." 22 76
                            ;;
            2) sed /etc/inittab -i -e "s|1:2345:respawn:/sbin/getty --noclear 38400 tty1|1:2345:respawn:\/bin\/login -f $user tty1 \<\/dev\/tty1 \>\/dev\/tty1 2\>\&1|g"
               update-rc.d lightdm disable 2 # taken from /usr/bin/raspi-config
               if [ -z $(egrep -i "emulationstation$" /etc/profile) ]
               then
                   echo "[ -n \"\${SSH_CONNECTION}\" ] || emulationstation" >> /etc/profile
               fi
               dialog --backtitle "PetRockBlock.com - RetroPie Setup. Installation folder: $rootdir for user $user" --msgbox "Emulation Station is now starting on boot." 22 76
                            ;;
        esac
    else
        break
    fi
}

function set_installps3controller() {
    rps_checkNeededPackages bluez-utils bluez-compat bluez-hcidump checkinstall libusb-dev libbluetooth-dev joystick
    apt-get remove -y cups
    apt-get autoremove -y
    dialog --backtitle "PetRockBlock.com - RetroPie Setup. Installation folder: $rootdir for user $user" --msgbox "Please make sure that your Bluetooth dongle is connected to the Raspberry Pi and press ENTER." 22 76
    if [[ -z `hciconfig | grep BR/EDR` ]]; then
        dialog --backtitle "PetRockBlock.com - RetroPie Setup. Installation folder: $rootdir for user $user" --msgbox "Cannot find the Bluetooth dongle. Please try to (re-)connect it and try again." 22 76
        break
     fi

    wget http://www.pabr.org/sixlinux/sixpair.c
    mkdir -p $rootdir/supplementary/sixpair/
    mv sixpair.c $rootdir/supplementary/sixpair/
    pushd $rootdir/supplementary/sixpair/
    gcc -o sixpair sixpair.c -lusb
    dialog --backtitle "PetRockBlock.com - RetroPie Setup. Installation folder: $rootdir for user $user" --msgbox "Please connect your PS3 controller via USB-CABLE and press ENTER." 22 76
    if [[ -z `./sixpair | grep "Setting master"` ]]; then
        dialog --backtitle "PetRockBlock.com - RetroPie Setup. Installation folder: $rootdir for user $user" --msgbox "Cannot find the PS3 controller via USB-connection. Please try to (re-)connect it and try again." 22 76
        break
    fi
    popd

    pushd $rootdir/supplementary/
    wget -O QtSixA.tar.gz http://sourceforge.net/projects/qtsixa/files/QtSixA%201.5.1/QtSixA-1.5.1-src.tar.gz
    tar xfvz QtSixA.tar.gz
    cd QtSixA-1.5.1/sixad
    make CXX="g++-4.6"
    mkdir -p /var/lib/sixad/profiles
    checkinstall -y
    update-rc.d sixad defaults
    rm QtSixA.tar.gz
    popd

    dialog --backtitle "PetRockBlock.com - RetroPie Setup. Installation folder: $rootdir for user $user" --msgbox "The driver and configuration tools for connecting PS3 controllers have been installed. Please visit https://github.com/petrockblog/RetroPie-Setup/wiki/Setting-up-a-PS3-controller for further information." 22 76
}

function set_install_xboxdrv() {
    rps_checkNeededPackages xboxdrv
    if [[ -z `cat /etc/rc.local | grep "xboxdrv"` ]]; then
        sed -i -e '13,$ s|exit 0|xboxdrv --daemon --id 0 --led 2 --deadzone 4000 --silent --trigger-as-button --next-controller --id 1 --led 3 --deadzone 4000 --silent --trigger-as-button --dbus disabled --detach-kernel-driver \&\nexit 0|g' /etc/rc.local
    fi
    ensureKeyValueBootconfig "dwc_otg.speed" "1" "/boot/config.txt"
    dialog --backtitle "PetRockBlock.com - RetroPie Setup. Installation folder: $rootdir for user $user" --msgbox "Installed xboxdrv and adapted /etc/rc.local. It will be started on boot." 22 76
}

function set_RetroarchJoyconfig() {
    local configfname
    local numJoypads

    dialog --backtitle "PetRockBlock.com - RetroPie Setup. Installation folder: $rootdir for user $user" --msgbox "Connect ONLY the controller to be registered for RetroArch to the Raspberry Pi." 22 76
    clear
    # todo Find number of first joystick device in /dev/input
    numJoypads=$(ls -1 /dev/input/js* | head -n 1)
    $rootdir/emulators/RetroArch/installdir/bin/retroarch-joyconfig --autoconfig "$rootdir/emulators/RetroArch/configs/tempconfig.cfg" --timeout 4 --joypad ${numJoypads:13}
    configfname=`grep "input_device = \"" $rootdir/emulators/RetroArch/configs/tempconfig.cfg`
    configfname=`echo ${configfname:16:-1} | tr -d ' '`
    mv $rootdir/emulators/RetroArch/configs/tempconfig.cfg $rootdir/emulators/RetroArch/configs/$configfname.cfg
    chown $user:$user $rootdir/emulators/RetroArch/configs/
    dialog --backtitle "PetRockBlock.com - RetroPie Setup. Installation folder: $rootdir for user $user" --msgbox "The configuration file has been saved as $configfname.cfg and will be used by RetroArch from now on whenever that controller is connected." 22 76
}

function install_libsdlbinaries() {
    rps_checkNeededPackages libudev-dev libasound2-dev libdbus-1-dev libraspberrypi0 libraspberrypi-bin libraspberrypi-dev

    wget -O libsdlbinaries.tar.gz http://downloads.petrockblock.com/libsdl2.0.1.tar.gz
    tar xvfz libsdlbinaries.tar.gz
    rm libsdlbinaries.tar.gz
    cp libsdl2.0.1/* /usr/local/lib/
    rm -rf libsdl2.0.1/
}

function configure_audiosettings() {
    cmd=(dialog --backtitle "PetRockBlock.com - RetroPie Setup. Installation folder: $rootdir for user $user" --menu "Set audio output." 22 86 16)
    options=(1 "Auto"
             2 "Headphones - 3.5mm jack"
             3 "HDMI"
             4 "Reset to default")
    choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    if [ "$choices" != "" ]; then
        case $choices in
            1) amixer cset numid=3 0
               alsactl store
               ###set
               dialog --backtitle "PetRockBlock.com - RetroPie Setup. Installation folder: $rootdir for user $user" --msgbox "Set audio output to auto" 22 76
                            ;;
            2) amixer cset numid=3 1
               alsactl store
               ###set
               dialog --backtitle "PetRockBlock.com - RetroPie Setup. Installation folder: $rootdir for user $user" --msgbox "Set audio output to headphones / 3.5mm jack " 22 76
                            ;;
            3) amixer cset numid=3 2
               alsactl store
               ###set
               dialog --backtitle "PetRockBlock.com - RetroPie Setup. Installation folder: $rootdir for user $user" --msgbox "Set audio output to HDMI" 22 76
                            ;;
            4) /etc/init.d/alsa-utils reset
               alsactl store
                 ###set
               dialog --backtitle "PetRockBlock.com - RetroPie Setup. Installation folder: $rootdir for user $user" --msgbox "Audio settings reset to defaults" 22 76
                            ;;
        esac
    else
        break
    fi
}

function configure_esconfig()
{
    cp "$scriptdir/supplementary/settings.xml" "$rootdir/supplementary/ES-config/"
    sed -i -e "s|/home/pi/RetroPie|$rootdir|g" "$rootdir/supplementary/ES-config/settings.xml"
    if [[ ! -d $romdir/esconfig ]]; then
        mkdir -p $romdir/esconfig
    fi
    # generate new startup scripts for ES-config
    cp "$scriptdir/supplementary/scripts"/*/*.py "$rootdir/roms/esconfig/"
    chmod +x "$rootdir/roms/esconfig"/*.py
    # add some information
    cat > ~/.emulationstation/gamelists/esconfig/gamelist.xml << _EOF_
<?xml version="1.0"?>
<gameList>
    <game>
        <path>$romdir/esconfig/esconfig.py</path>
        <name>Start ES-Config</name>
        <desc>[DGen]
Old Genesis/Megadrive emulator

[RetroArch]
GB,GBC,NES,SNES,MASTERSYSTEM,GENESIS/MEGADRIVE,PSX

[GnGeo]
Old NeoGeo emulator
GNGEO 0.7</desc>
    </game>
    <game>
        <path>$romdir/esconfig/basic.py</path>
        <name>Update Retroarch Autoconfig (Keyboard necessary)</name>
        <desc>Joypad config will be stored under /opt/retropie/emulators/RetroArch/configs.</desc>
    </game>
    <game>
        <path>$romdir/esconfig/autoon.py</path>
        <name>Enable RetroArch Autoconfig</name>
    </game>
    <game>
        <path>$romdir/esconfig/autooff.py</path>
        <name>Disable RetroArch Autoconfig</name>
    </game>
    <game>
        <path>$romdir/esconfig/rgui.py</path>
        <name>Open RGUI</name>
        <desc>RetroArch Menu. (X = ok, Y/Z = cancel). Select "Save On Exit" to store changes.</desc>
    </game>
    <game>
        <path>$romdir/esconfig/showip.py</path>
        <name>Show current IP address</name>
    </game>
</gameList>
_EOF_
chown $user:$user "$romdir/esconfig/"*
}

function install_esconfig()
{
    rmDirExists "$rootdir/supplementary/ES-config"
    gitPullOrClone "$rootdir/supplementary/ES-config" git://github.com/Aloshi/ES-config.git
    pushd "$rootdir/supplementary/ES-config"
    sed -i -e "s/apt-get install/apt-get install -y --force-yes/g" get_dependencies.sh
    ./get_dependencies.sh
    make
    popd

    if [[ ! -f "$rootdir/supplementary/ES-config/es-config" ]]; then
        __ERRMSGS="$__ERRMSGS Could not successfully compile ES-config."
    fi
}

function install_gamecondriver() {
    GAMECON_VER=0.9
    DB9_VER=0.7
    DOWNLOAD_LOC="http://www.niksula.hut.fi/~mhiienka/Rpi"

    clear

    dialog --title " GPIO gamepad drivers installation " --clear \
    --yesno "GPIO gamepad drivers require that most recent kernel (firmware)\
    is installed and active. Continue with installation?" 22 76
    case $? in
      0)
        echo "Starting installation.";;
      *)
        return 0;;
    esac

    #install dkms
    rps_checkNeededPackages dkms

    #reconfigure / install headers (takes a a while)
    if [ "$(dpkg-query -W -f='${Version}' linux-headers-$(uname -r))" = "$(uname -r)-2" ]; then
        dpkg-reconfigure linux-headers-`uname -r`
    else
        wget ${DOWNLOAD_LOC}/linux-headers-rpi/linux-headers-`uname -r`_`uname -r`-2_armhf.deb
        dpkg -i linux-headers-`uname -r`_`uname -r`-2_armhf.deb
        rm linux-headers-`uname -r`_`uname -r`-2_armhf.deb
    fi

    #install gamecon
    if [ "`dpkg-query -W -f='${Version}' gamecon-gpio-rpi-dkms`" = ${GAMECON_VER} ]; then
        #dpkg-reconfigure gamecon-gpio-rpi-dkms
        echo "gamecon is the newest version"
    else
        wget ${DOWNLOAD_LOC}/gamecon-gpio-rpi-dkms_${GAMECON_VER}_all.deb
        dpkg -i gamecon-gpio-rpi-dkms_${GAMECON_VER}_all.deb
        rm gamecon-gpio-rpi-dkms_${GAMECON_VER}_all.deb
    fi

    #install db9 joystick driver
    if [ "`dpkg-query -W -f='${Version}' db9-gpio-rpi-dkms`" = ${DB9_VER} ]; then
        echo "db9 is the newest version"
    else
        wget ${DOWNLOAD_LOC}/db9-gpio-rpi-dkms_${DB9_VER}_all.deb
        dpkg -i db9-gpio-rpi-dkms_${DB9_VER}_all.deb
        rm db9-gpio-rpi-dkms_${DB9_VER}_all.deb
    fi

    #test if gamecon installation is OK
    if [[ -n $(modinfo -n gamecon_gpio_rpi | grep gamecon_gpio_rpi.ko) ]]; then
        dialog --backtitle "PetRockBlock.com - RetroPie Setup. Installation folder: $rootdir for user $user" --msgbox "`cat /usr/share/doc/gamecon_gpio_rpi/README.gz | gzip -d -c`" 22 76
    else
        dialog --backtitle "PetRockBlock.com - RetroPie Setup. Installation folder: $rootdir for user $user" --msgbox "Gamecon GPIO driver installation FAILED"\
        22 76
    fi

    #test if db9 installation is OK
    if [[ -n $(modinfo -n db9_gpio_rpi | grep db9_gpio_rpi.ko) ]]; then
            dialog --backtitle "PetRockBlock.com - RetroPie Setup. Installation folder: $rootdir for user $user" --msgbox "Db9 GPIO driver successfully installed. \
        Use 'zless /usr/share/doc/db9_gpio_rpi/README.gz' to read how to use it." 22 76
    else
        dialog --backtitle "PetRockBlock.com - RetroPie Setup. Installation folder: $rootdir for user $user" --msgbox "Db9 GPIO driver installation FAILED"\
        22 76
    fi
}

function configure_gamecondriver() {
    if [ "`dpkg-query -W -f='${Status}' gamecon-gpio-rpi-dkms`" != "install ok installed" ]; then
        dialog --msgbox "gamecon_gpio_rpi not found, install it first" 22 76
        return 0
    fi

    REVSTRING=`cat /proc/cpuinfo |grep Revision | cut -d ':' -f 2 | tr -d ' \n' | tail -c 4`
    case "$REVSTRING" in
          "0002"|"0003")
             GPIOREV=1
             ;;
          *)
             GPIOREV=2
             ;;
    esac

dialog --msgbox "\
__________\n\
         |          ### Board gpio revision $GPIOREV detected ###\n\
    + *  |\n\
    * *  |\n\
    1 -  |          The driver is set to use the following configuration\n\
    2 *  |          for 2 SNES controllers:\n\
    * *  |\n\
    * *  |\n\
    * *  |          + = power\n\
    * *  |          - = ground\n\
    * *  |          C = clock\n\
    C *  |          L = latch\n\
    * *  |          1 = player1 pad\n\
    L *  |          2 = player2 pad\n\
    * *  |          * = unconnected\n\
         |\n\
         |" 22 76

    if [[ -n $(lsmod | grep gamecon_gpio_rpi) ]]; then
        rmmod gamecon_gpio_rpi
    fi

    if [ $GPIOREV = 1 ]; then
        modprobe gamecon_gpio_rpi map=0,1,1,0
    else
        modprobe gamecon_gpio_rpi map=0,0,1,0,0,1
    fi

    dialog --title " Update $rootdir/configs/all/retroarch.cfg " --clear \
        --yesno "Would you like to update button mappings \
    to $rootdir/configs/all/retroarch.cfg ?" 22 76

      case $? in
       0)
        if [ $GPIOREV = 1 ]; then
                ensureKeyValue "input_player1_joypad_index" "0" "$rootdir/configs/all/retroarch.cfg"
                ensureKeyValue "input_player2_joypad_index" "1" "$rootdir/configs/all/retroarch.cfg"
        else
            ensureKeyValue "input_player1_joypad_index" "1" "$rootdir/configs/all/retroarch.cfg"
            ensureKeyValue "input_player2_joypad_index" "0" "$rootdir/configs/all/retroarch.cfg"
        fi

            ensureKeyValue "input_player1_a_btn" "0" "$rootdir/configs/all/retroarch.cfg"
            ensureKeyValue "input_player1_b_btn" "1" "$rootdir/configs/all/retroarch.cfg"
            ensureKeyValue "input_player1_x_btn" "2" "$rootdir/configs/all/retroarch.cfg"
            ensureKeyValue "input_player1_y_btn" "3" "$rootdir/configs/all/retroarch.cfg"
            ensureKeyValue "input_player1_l_btn" "4" "$rootdir/configs/all/retroarch.cfg"
            ensureKeyValue "input_player1_r_btn" "5" "$rootdir/configs/all/retroarch.cfg"
            ensureKeyValue "input_player1_start_btn" "7" "$rootdir/configs/all/retroarch.cfg"
            ensureKeyValue "input_player1_select_btn" "6" "$rootdir/configs/all/retroarch.cfg"
            ensureKeyValue "input_player1_left_axis" "-0" "$rootdir/configs/all/retroarch.cfg"
            ensureKeyValue "input_player1_up_axis" "-1" "$rootdir/configs/all/retroarch.cfg"
            ensureKeyValue "input_player1_right_axis" "+0" "$rootdir/configs/all/retroarch.cfg"
            ensureKeyValue "input_player1_down_axis" "+1" "$rootdir/configs/all/retroarch.cfg"

            ensureKeyValue "input_player2_a_btn" "0" "$rootdir/configs/all/retroarch.cfg"
            ensureKeyValue "input_player2_b_btn" "1" "$rootdir/configs/all/retroarch.cfg"
            ensureKeyValue "input_player2_x_btn" "2" "$rootdir/configs/all/retroarch.cfg"
            ensureKeyValue "input_player2_y_btn" "3" "$rootdir/configs/all/retroarch.cfg"
            ensureKeyValue "input_player2_l_btn" "4" "$rootdir/configs/all/retroarch.cfg"
            ensureKeyValue "input_player2_r_btn" "5" "$rootdir/configs/all/retroarch.cfg"
            ensureKeyValue "input_player2_start_btn" "7" "$rootdir/configs/all/retroarch.cfg"
            ensureKeyValue "input_player2_select_btn" "6" "$rootdir/configs/all/retroarch.cfg"
            ensureKeyValue "input_player2_left_axis" "-0" "$rootdir/configs/all/retroarch.cfg"
            ensureKeyValue "input_player2_up_axis" "-1" "$rootdir/configs/all/retroarch.cfg"
            ensureKeyValue "input_player2_right_axis" "+0" "$rootdir/configs/all/retroarch.cfg"
            ensureKeyValue "input_player2_down_axis" "+1" "$rootdir/configs/all/retroarch.cfg"
        ;;
       *)
        ;;
      esac

    dialog --title " Enable SNES configuration permanently " --clear \
        --yesno "Would you like to permanently enable SNES configuration?\
        " 22 76

    case $? in
      0)
    if [[ -z $(cat /etc/modules | grep gamecon_gpio_rpi) ]]; then
    if [ $GPIOREV = 1 ]; then
                addLineToFile "gamecon_gpio_rpi map=0,1,1,0" "/etc/modules"
    else
        addLineToFile "gamecon_gpio_rpi map=0,0,1,0,0,1" "/etc/modules"
    fi
    fi
    ;;
      *)
        #TODO: delete the line from /etc/modules
        ;;
    esac

    dialog --backtitle "PetRockBlock.com - RetroPie Setup. Installation folder: $rootdir for user $user" --msgbox \
    "Gamecon GPIO driver enabled with 2 SNES pads." 22 76
}

