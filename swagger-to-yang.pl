#!/usr/bin/env perl6

use v6;
use JSON::Tiny;

sub MAIN($json-file, :$prefix, :$namespace, :$org, :$date, :$contact) {
    my $json = slurp $json-file;
    my %swagger = from-json($json);

    my $title = %swagger<info><title> // $json-file;
    my $module-name = $title.lc.trans(' .' => '-');
    my $module-prefix = $prefix // $module-name;
    my $description = %swagger<info><description> // "TODO";
    my $organization = $org // "TODO";
    my $contact-info = $contact // "TODO";
    my $module-namespace = $namespace // "urn:{$module-name}";
    my $revision-date = $date // Date.today;

    #
    # Write the module header
    #
    say qq:to/EOF/;
    module {$module-name} \{
      namespace "{$module-namespace}";
      prefix {$module-prefix};

      organization "{$organization}";
      contact
        "{$contact-info}";
      description
        "{$description}";

      revision {$revision-date} \{
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

                        my Bool $emitKey = ! %swagger<definitions>{$type}<properties>{$key};

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
        say "{$indent}grouping {$key} \{";
        my $properties = %swagger<definitions>{$key}<properties>;
        object($key, $properties, $indent) if $properties;
        say "{$indent}}";
    }

    #
    # Write the module footer
    #
    say '}';

    # Done

    sub container($name, $descr, $type, $key, $emitKey) {
        say qq:to/EOF/;
          container $name \{
            description
	      "$descr";
            list $type \{
              uses $type;
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
                    say "{$indent}container {$key} \{";
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
    # TODO - need to search for key to use
    #
    sub arr($name, %value, $indent) {
        my $ref = %value<items><$ref>;
        my $uses = $ref.split('/').Array.pop;
        say "{$indent}list {$name} \{";
        say "{$indent}  uses {$uses};";
        say "{$indent}  key \"id\";";
        say "{$indent}  leaf id \{";
        say "{$indent}    type string;";
        say "{$indent}  \}";
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
