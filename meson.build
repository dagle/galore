project('galore', 'c',
  version : '0.1',
  default_options : ['warning_level=3'])
subdir('src')

# install_data('res/galore.svg', install_dir: '/home/dagle/.local/share/applications')
meson.add_install_script('linux_install.sh')
# install_data('galore.desktop')
# run_command('update-desktop-database', '~/.local/share/applications')

# run_command('install', 'res/galore.svg', 
