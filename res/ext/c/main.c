#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <strings.h>

int main() {
    for ( int i=0; i<10000; i++) {
	printf("%d bottles of beer on the wall...", i);
    }
}
pub const ColorC = union(enum(())) {
    black:    usize = 30,
    red:      usize = 31,
    green:    usize = 32,
    yellow:   usize = 33,
    blue:     usize = 34,
    magenta:  usize = 35,
    cyan:     usize = 36,
    bgray:    usize = 37,
    default:  usize = 39,
    gray:     usize = 90,
    bred:     usize = 91,
    bgreen:   usize = 92,
    byellow:  usize = 93,
    bblue:    usize = 94,
    bmagenta: u8 = 95,
    bcyan:    u8 = 96,
    white:    u8 = 97,
};
