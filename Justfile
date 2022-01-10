set dotenv-load := false

build-compiler:
    @echo "Building the core compiler"
    zig build run

build-delsh:
    @echo "Building the delsh shell..."
