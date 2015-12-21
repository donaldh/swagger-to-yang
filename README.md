# swagger-to-yang

This is a utility to generate a YANG schema from a Swagger JSON specification. It is currently very rudimentary and has
only been tested with a few input files.

# Prerequisites

It is written in Perl 6 which is available for most platforms.

## MacOS X

The easiest way to install Perl 6 is by using Homebrew

    brew install rakudo-star

# Usage

```
% ./swagger-to-yang.pl 
Usage:
  swagger-to-yang.pl [--module-prefix=<Str>] [--namespace=<Str>] [--org=<Str>] [--date=<Str>] [--contact=<Str>]
                     [--entity-prefix=<Str>] [--preserve-names] <json-file>

      -- Translate a JSON Swagger specification into a YANG schema
  
    --date=<Str>             Set the YANG revision date - defaults to today in YYYY-MM-DD format
    --contact=<Str>          Set the YANG contact information - defaults to TODO
    --org=<Str>              Set the YANG organization - defaults to TODO
    --namespace=<Str>        Set the YANG namespace - defaults to urn:module-name
    --module-prefix=<Str>    Set the YANG prefix - defaults to the module-name
    <json-file>              The input JSON Swagger specification
    --preserve-names         Use the Swagger definition names unchanged - default is to convert to kebab-case
    --entity-prefix=<Str>    Provide a prefix for all YANG entity names - can help to avoid name clashes
```

`swagger-to-yang` prints the generated YANG schema to `stdout`.
