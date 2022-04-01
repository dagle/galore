<div align="center">

<img src="res/galore.svg" width=315>

<a href="https://github.com/neovim/neovim"> ![Requires](https://img.shields.io/badge/requires-neovim%200.6%2B-green?style=flat-square&logo=neovim) </a>

<a href="/LICENSE"> ![License](https://img.shields.io/badge/license-GPL%20v2-brightgreen?style=flat-square) </a>
<a href="#wip"> ![Status](https://img.shields.io/badge/status-WIP-informational?style=flat-square) </a>

# mail galore - A notmuch client for neovim

[Installation](#installation)
•
[Usage](#usage)
•
[Pictures](#pictures)

</div>

## Intro
Notmuch is a great way to index your email and neovim is great for viewing and editing
text. Combine the two and you have a great email client. 
The idea is to be more powerful than mutt but way easier to configure.

Other than the basic notmuch features Galore has support for: 
- cmp for address completion
- telescope for fuzzy searching emails
- encrypting and decrypting emails
- signing and verifying emails

## Installation
WIP, mail galore is under heavy development, expect crashes and thing changing.
Atm it's pre 0.1 software. If you don't intend to read code / write patches, you should wait.

Galore uses luajit and the C-bindings to do its magic, depending on notmuch and gmime.
To view html emails, you need a htmlviewer, by default it uses html2text.

You need to install neovim and notmuch.

Then using your favorite plugin-manager install galore.

With packer:
``` lua
use {'
	dagle/galore', run = 'make', 
	requires = {
      'nvim-telescope/telescope.nvim',
      'nvim-lua/popup.nvim',
	  'nvim-lua/plenary.nvim',
	  'nvim-telescope/telescope-file-browser.nvim',
	  'hrsh7th/nvim-cmp',
	}
}
```
You need to install **telescope** and **cmp** if you want support for that

For livesearch support in telescope you need to install [nm-livesearch](https://github.com/dagle/nm-livesearch)


## Usage
After installing galore, you need to add the following to init:
``` lua
local galore = require('galore')
galore.setup()
```
and when you want to launch galore do:
``` lua
galore.open 
```
or 
```
:Galore
```

By default, galore tries to read values from the notmuch config file.
You can also override options by passing values to setup, look in config.lua
for default values (will be documented in the future).

### Telescope
Galore exports the following telescope functions (require 'galore.telescope' to use them)
- notmuch_search
- load_draft
- attach_file (only works in compose)

### Cmp
add

``` lua
{name = 'notmuch_addr'}
```
to you sources and update your formating, to complete email addresses
(atm it only has support for notmuch)

## Pictures
Saved searches

<img src="res/saved.png" width=315>

Thread message browser

<img src="res/thread_message.png" width=315>

Message view

<img src="res/message_view.png" width=315>

Telescope

<img src="res/telescope.png" width=315>

And with a couple of windows together

<img src="res/overview.png" width=315>

## Customize

config values
-------------

views
-----
If you wanna customize how galore looks, you need to not only customize the 
the print functions but also the syntax files.
So if you want to customize the thread-viewer, you need to create your own
syntax/galore-threads.vim that matches your syntax.

## TODO:
See the todo-file, even the todo has stuff missing.

Tips and trix
-------------
You want a small gpg-ui to complement the email client?
That is easy, with a plugin like toggleterm and gpg-tui, we can make
a small popup window to manage your keys from 
``` lua
local terms = require("toggleterm.terminal")
local gpgtui = terms.Terminal:new({
  cmd = "gpg-tui",
  direction = "float",
  float_opts = {
    border = "single",
  },
})

local function gpgtui_toggle()
  gpgtui:toggle()
end

vim.keymap.set('n', '<leader>mg', gpgtui_toggle, {noremap = true, silent = true})
```
