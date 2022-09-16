project('filter-reply', 'c',
  version : '0.1',
  default_options : ['warning_level=3'])

# subdir('src')

gnome = import('gnome')
source_c = [
  'galore-filter-reply.c',
  ]

source_h = [
  'galore-filter-reply.h',
  ]

deps = [
  dependency('gmime-3.0'),
  dependency('glib-2.0'),
  dependency('gobject-2.0'),
  dependency('gio-2.0'),
  # dependency('gobject-introspection-1.0')
]
filter_lib = library('Galore', source_c, dependencies : deps)

if true
  gir_args = [
    '--quiet',
    '--warn-all',
    ]

  filter_glib_gir = gnome.generate_gir(
    filter_lib,
    sources: source_c + source_h,
    namespace: 'Galore',
    nsversion: '0.1',
    symbol_prefix: ['galore'],
    includes: [ 'GObject-2.0', 'Gio-2.0', 'GMime-3.0'],
    header: 'gmime/gmime-filter.h',
    dependencies: deps,
    # install: true,
    # extra_args: gir_args,
    fatal_warnings: true,
    )
else
  # Just warn and quit
  json_glib_gir = []
endif
