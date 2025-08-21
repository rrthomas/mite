# Mite release 2

by Reuben Thomas (rrt@sc3d.org)  


This package contains the design and implementation of Mite, a simple
general-purpose virtual machine. See {mite,iface,mit}.pdf for documentation.

The URL for the primary distribution is https://github.com/rrthomas/mite.


# License

Mite is distributed under the BSD license; see the file LICENSE.


# Quick start and extras

FIXME: Add pointers to sources of all the tools

Mite should work on almost any ISO C system (see the docs for the small
print). To build it you need a POSIX environment with a C99 compiler, gperf,
[Lua 5.3](https://www.lua.org/), and
[lua-stdlib](https://github.com/rrthomas/lua-stdlib/), most easily installed
using [LuaRocks](https://www.luarocks.org), a LaTeX system (including
`latexmk`), and HeVeA. To build from a source release:

    ./configure && make

The design is described in mite.tex; the API is in iface.tex.


# Bugs

Bug reports, especially of systems on which Mite doesn't work when it
should, are welcome. Please use the [GitHub issue tracker](https://github.com/rrthomas/mite).
