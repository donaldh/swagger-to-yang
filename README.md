# swagger-to-yang

This is a utility to generate a YANG schema from a Swagger JSON specification. It is currently very rudimentary and has
only been tested with a few input files.

# Prerequisites

It is written in Perl 6 which is available for most platforms.

## MacOS X

The easiest way to install Perl 6 is by using Homebrew

    brew install rakudo-star

# Usage

    % ./swagger-to-yang.pl 
    Usage:
      ./swagger-to-yang.pl [--prefix=<Any>] [--namespace=<Any>] [--org=<Any>] [--date=<Any>] [--contact=<Any>] <json-file> 

`swagger-to-yang` prints the generated YANG schema to `stdout`.
