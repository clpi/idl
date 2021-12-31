#!/bin/bash
# set -e; set -u; set -o pipefail
R='\033[0;31m'; LR='\033[1;31m'; G='\033[0;32m'; LG='\033[1;32m'
P='\033[0;35m'; LP='\033[1;35m'; C='\033[0;36m'; LC='\033[1;36m'
Y='\033[0;33m'; LY='\033[1;33m'; B='\033[0;34m'; LB='\033[1;34m'; N='\033[0m'

echo -e "Running ${LP}./x.sh ${LG}cmd"

function build_wasm() {
    zig build-exe -target wasm32-wasi src/main.zig -O ReleaseFast --name idl
}
function build_c() {
    zig cc ext/c/main.c -o ext/c/main
}
function build_cpp() {
    zig cc ext/c/main.c -o ext/c/main
}

function print_help() {
    echo -e "${LP}./x.sh ${LG}USAGE"
    echo -e ""
    echo -e "${LG}COMMANDS"
    echo -e "    - ${LG}r   ${G}run\t\t\t\t${N}Just builds and runs the zig binary (${Y}the default cmd${N})"
    echo -e "    - ${LG}rc  ${G}runc ${Y}<CMD>\t\t\t${N}Runs given ${Y}<cmd> in ${P}iz (${LP}iz ${Y}<cmd>)"
    echo -e "    - ${LG}cl  ${G}clean\t\t\t\t${N}Clean any zig build/cache files"
    echo -e "    - ${LG}h   ${G}help\t\t\t\t${N}Print this help message"
    echo -e "    - ${LG}t   ${G}test\t\t\t\t${N}Perform all specified tests in src/"
    echo -e "    - ${LG}b   ${G}build ${Y}[fast|small|safe]\t${N}Build binary with specified optimization ${Y}(alt: f, sm, sa)"
    echo -e "    - ${LG}w   ${G}wasm \t\t\t\t${N}Build WASI WASM binary with default (fast) settings"
    echo -e "    - ${LG}p   ${G}publish\t\t\t${N}Publish wasm build to WAPM (currently not working)"
    echo -e "    - ${LG}c   ${G}clang\t\t\t\t${N}Commands for c language ext"
    echo -e "    - ${LG}cp  ${G}c++\t\t\t\t${N}Commands for c++ language ext"
    echo -e "    - ${LG}cb  ${G}cbuild\t\t\t${N}Commands for building c files"
    echo -e ""
    echo -e "${LB}FLAGS"
    echo -e "    - ${B}-h   --help ${Y}<CMD>\t\t\t${N}Prints this help message, or gets info about iz ${Y}<CMD>"
    echo -e "    - ${B}-d   --debug ${Y}<CMD>\t\t${N}Adds debug info${Y}<CMD>"
}

function build_small() {
    zig build -Drelease-small true
    # zig build -Dtarget wam32-wasi -Drelease-small true
}
function build_fast() {
    zig build -Drelease-fast true
    # zig build -Dtarget wam32-wasi -Drelease-fast true
}
function build_safe() {
    zig build -Drelease-safe true
    # zig build -Dtarget wam32-wasi -Drelease-safe true
}
function build_small_wasm_exe() {
    zig build-exe -target wasm32-wasi -O ReleaseSmall ./src/main.zig
}
function build_fast_wasm_exe() {
    zig build-exe -target wasm32-wasi -O ReleaseFast ./src/main.zig 
}

function clean() {
    rm -rf zig-out/bin/*
    rm -rf zig-cache
    rm -rf iz.wasm
}

function run() {
    zig build run
}

function test() {
    zig test src/main.zig
}

function run_wasm() {
    wasmer zig-out/bin/iz.wasm
}
function gpush() {
    git push gh master
}
function publish() {
    wapm publish
}


case $1 in
    r|run) 
	echo "run command"
	case $2 in
	    w|wasm) run_wasm;;
	    *) run;;
	esac
	;;
    t|test) 
	echo "test command"
	case $2 in
	    h|help)   zig test src/cli/help.zig;;
	    sh|shell) zig test src/cli/sh.zig;;
	    m|main)   zig test src/cli/main.zig ;;
	    t|term)   zig test src/term.zig ;;
	    *) test;;
	esac
	;;
    rc|runc) 
	case $2 in
	    h|help)    print_help ;;
	    n|new)     zig build run -- new ;;
	    l|log)     zig build run -- log ;;
	    ls|list)   zig build run -- ls ;;
	    rm|remove) zig build run -- rm ;;
	    R|repl)    zig build run -- repl ;;
	    i|init)    zig build run -- init ;;
	esac
	;;
    cl|clean) clean;;
    cc|ccache) rm -rf zig-cache;;
    gp|push) gpush;;
    p|publish) wapm_publish;;
    w|wasm) build_wasm;;
    cb|cbuild) build_c;;
    cp|c++|cp)
	echo "C++ command"
	case $2 in 
	    b|build) build_cpp;;
	esac
	;;
    c|clang) 
	echo "C command"
	case $2 in
	    b|build) build_c;;
	esac
	;;
    b|build) 
	echo "build command"
	case $2 in
	    f|fast) build_fast;;
	    sm|small) build_small;;
	    sa|safe) build_safe;;
	esac
	;;
    h|help|-h|--help) print_help ;;
    i|install) zig build -Drelease-fast true install;;
    u|uninstall) zig build uninstall

esac    
# ((!$#)) && main
