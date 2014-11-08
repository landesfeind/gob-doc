# gob-doc

Doxygen filter for GObject Builder 2 files

## Description

The doxygen filter parses `*.gob` files and produces C++ class definitions.
The given class definitions are not valid C++ but can be parsed by Doxygen to
generate a documentation as known from other projects.

## Installation

To compile `gob-doc` the following tools are required:
* a lexical Analyzer [flex](http://flex.sourceforge.net)
* a C99 compliant compiler [gcc](https://gcc.gnu.org)
* [make](http://www.gnu.org/software/make)

`gob-doc` consists of a single `*.l` file which is transformed by the
lexer to C code and subsequently compiled by the C compiler.

The binary file can be put in any path and does not require any libraries than the
default C libraries.

## Usage

To use `gob-doc`, generate a new Doxygen file as usual and change the

`INPUT_FILTER = `

to

`INPUT_FILTER = gob-doc`

Note: Do not adjust the `OPTIMIZE_OUTPUT_FOR_*` configuration parameters because `gob-doc` tries to
generate C++ code which is natively parsed by Doxygen.

## Caveats

As of today, `gob-doc` only supports a small subset of the syntax
from GOB2. However, so far it seems to be enough for valid Doxygen 
input.

## See also

* [GObject Builder](http://www.jirka.org/gob.html)
* [Doxygen](http://www.doxygen.org)

