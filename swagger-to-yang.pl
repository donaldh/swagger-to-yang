#!/usr/bin/env perl6

use v6;
use JSON::Tiny;

#| Translate a JSON Swagger specification into a YANG schema
sub MAIN(
    Str $json-file,                #= The input JSON Swagger specification
    Str :$module-prefix,           #= Set the YANG prefix - defaults to the module-name
    Str :$namespace,               #= Set the YANG namespace - defaults to urn:module-name
    Str :$org,                     #= Set the YANG organization - defaults to TODO
    Str :$date,                    #= Set the YANG revision date - defaults to today in YYYY-MM-DD format
    Str :$contact,                 #= Set the YANG contact information - defaults to TODO
    Str :$entity-prefix,           #= Provide a prefix for all YANG entity names - can help to avoid name clashes
    Bool :$preserve-names = False  #= Use the Swagger definition names unchanged - default is to convert to kebab-case
    ) {
    my $json = slurp $json-file;
    my %swagger = from-json($json);

    my $title = %swagger<info><title> // $json-file;
    my $y-module-name = $title.lc.trans(' .' => '-');
    my $y-module-prefix = $module-prefix // $y-module-name;
    my $y-description = %swagger<info><description> // "TODO";
    my $y-organization = $org // "TODO";
    my $y-contact-info = $contact // "TODO";
    my $y-module-namespace = $namespace // "urn:{$y-module-name}";
    my $y-revision-date = $date // Date.today;
    my $y-entity-prefix = $entity-prefix ?? $entity-prefix ~ '-' !! '';

    #
    # Write the module header
    #
    say qq:to/EOF/;
    module {$y-module-name} \{
      namespace "{$y-module-namespace}";
      prefix {$y-module-prefix};

      organization "{$y-organization}";
      contact
        "{$y-contact-info}";
      description
        "{$y-description}";

      revision {$y-revision-date} \{
        description
          "Generated from {$json-file}";
      \}
    EOF

    my $indent = '  ';

    #
    # Process paths and verbs to identify toplevel containers / lists.
    #
    for %swagger<paths>.keys -> $key {
        my %verbs = %swagger<paths>{$key};
        for %verbs.keys -> $verb {
            my %properties = %verbs{$verb};
            given $verb {
                when 'get' {
                    if %properties<parameters>[0]<in> ~~ 'path' {
			my $ref = %properties<responses><200><schema><$ref>
			          // %properties<responses><200><schema><items><$ref>;
			my $type = $ref.subst(/^.*\//, '');

			my $descr = %properties<description>;
			my $key = %properties<parameters>[0]<name>;

                        my Bool $emitKey = ! has-key($type, $key);

			container($type ~ '-list', $descr, $type, $key, $emitKey);
                    }
                }
                default {
                }
            }
        }
    }

    #
    # Process definitions to identify group definitions.
    #
    for %swagger<definitions>.keys -> $key {
        say "{$indent}grouping {yangify-name($key)} \{";
        my $properties = %swagger<definitions>{$key}<properties>;
        object($key, $properties, $indent) if $properties;
        say "{$indent}}";
    }

    #
    # Write the module footer
    #
    say '}';

    # Done

    sub yangify-name($name) {
        my $ret = $y-entity-prefix ~ $name;
        $ret = $ret.lc.trans('_' => '-') unless $preserve-names;
        $ret;
    }

    sub has-key($type, $key) {
        ?%swagger<definitions>{$type}<properties>{$key}
    }

    sub container($name, $descr, $type, $key, $emitKey) {
        my $y-type = yangify-name($type);
        say qq:to/EOF/;
          container {yangify-name($name)} \{
            description
	      "$descr";
            list $y-type \{
              uses $y-type;
              key "$key";
        EOF
        if $emitKey {
          say qq:to/EOF/;
              leaf $key \{
                type string;
              \}
        EOF
        }
        say qq:to/EOF/;
            \}
          \}
        EOF
    }

    sub object($name, %properties, $indent is rw) {
        temp $indent ~= '  ';

        for %properties.keys -> $key {
            my %value = %properties{$key};
            given %value<type> {
                when 'object' {
                    my $ref = %value<$ref>;
                    say "{$indent}container {yangify-name($key)} \{";
                    say "{$indent}  uses {$ref.subst(/^.*\//, '')};" if $ref;
                    try object($key, %value<properties>, $indent);
                    say "{$indent}\}";
                }
                when 'array' {
                    arr($key, %value, $indent);
                }
                when 'integer' {
                    leaf($key, 'int64', $indent);
                }
                when 'string' | 'integer' | 'boolean' {
                    leaf($key, %value<type>, $indent);
                }
                default {
                    say "{$indent}{%value<type>} {$key}";
                }
            }
        }
    }

    #
    # TODO - Is there a way to search for key to use, or maybe a heuristic?
    #
    sub arr($name, %value, $indent) {
        my $ref = %value<items><$ref>;
        my $uses = $ref.split('/').Array.pop;
        my $key = 'id';                                 # hard-coded key;
        say "{$indent}list {yangify-name($name)} \{";
        say "{$indent}  uses {yangify-name($uses)};";
        say "{$indent}  key \"{$key}\";";
        {
            say "{$indent}  leaf {$key} \{";
            say "{$indent}    type string;";
            say "{$indent}  \}";
        } unless has-key($uses, $key);
        say "{$indent}\}";
    }

    #
    # TODO - constraints?
    #
    sub leaf($name, $type, $indent) {
        say "{$indent}leaf {$name} \{";
        say "{$indent}  type {$type};";
        say "{$indent}\}";
    }
}
