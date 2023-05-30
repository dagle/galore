source_c = [
  'galore.c',
  'galore-filter-reply.c',
  ]

source_h = [
  'galore.h',
  'galore-filter-reply.h',
  ]

deps = [
  dependency('gmime-3.0'),
  dependency('glib-2.0'),
  dependency('gobject-2.0'),
  dependency('gio-2.0'),
]
galore_lib = library('galore', source_c, dependencies : deps, install: true)
gnome = import('gnome')

if true
  gir_args = [
    '--quiet',
    '--warn-all',
    ]

  filter_glib_gir = gnome.generate_gir(
    galore_lib,
    sources: source_c + source_h,
    namespace: 'Galore',
    nsversion: '0.1',
    symbol_prefix: ['galore'],
    includes: [ 'GObject-2.0', 'Gio-2.0', 'GMime-3.0'],
    dependencies: deps,
    extra_args: gir_args,
    fatal_warnings: true,
    install: true,
    )
else
  # Just warn and quit
  json_glib_gir = []
endif
