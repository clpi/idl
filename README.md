# idlang + idlspec in zig

## About
- CLI and associated lib for idlang and idlspec, in zig (as an experiment and exercise for myself)

## Installing
- `wapm install clpi/idl`
    - For installing the wasm-built binary

## Commands
- `idl sh|shell`: Runs the REPL
- `idl r|run <FILE>`: Runs the idlang or idlspec file
- `idl b|build <FILE>`: Builds the idlspec or idlang file
- `idl h|help|-h|--help`: Prints out the help/usage

## Build utility script
- `./x.sh wasm`: Builds idl.wasm to root directory
- `./x.sh wasmr <RT>`: Builds idl.wasm and runs with RT 
    - `RT=wasmer`: Builds with wasmer
    - `RT=wasm3`: Builds with wasm3
- `./x.sh run`: Builds and runs
- `./x.sh build`: Builds to zig-out
- `./x.sh shell`: Builds and then runs the shell

## More info
- Go to [my site](http://clp.is/projects/idl) for more info
- For more info about idl (the engine) go [here](http://is.idl.li)
