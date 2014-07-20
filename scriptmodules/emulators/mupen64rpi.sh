rp_module_id="mupen64rpi"
rp_module_desc="N64 emulator MUPEN64Plus-RPi"
rp_module_menus="2+"

function sources_mupen64rpi() {
    gitPullOrClone "$rootdir/emulators/mupen64plus-rpi" https://github.com/ricrpi/mupen64plus-rpi
}

function build_mupen64rpi() {
    pushd "$rootdir/emulators/mupen64plus-rpi"
    ./m64p_build.sh
    if [[ ! -f "$rootdir/emulators/mupen64plus-rpi/test/mupen64plus" ]]; then
        __ERRMSGS="$__ERRMSGS Could not successfully compile Mupen 64 Plus RPi."
    fi
    popd
}

function configure_mupen64rpi() {
    mkdir -p "$romdir/n64"
}