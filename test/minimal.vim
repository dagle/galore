" Grabbing refactoring code
set rtp+=.

" Using local versions of plenary and nvim-treesitter if possible
" This is required for CI
set rtp+=../plenary.nvim
set rtp+=../nvim-treesitter
set rtp+=../telescope
set rtp+=../filebrowser
set rtp+=../notmuch-lua

" If you use vim-plug if you got it locally
set rtp+=~/.vim/plugged/plenary.nvim
set rtp+=~/.vim/plugged/nvim-treesitter
set rtp+=~/.vim/plugged/telescope.nvim
set rtp+=~/.vim/plugged/telescope-file-browser.nvim
set rtp+=~/.vim/plugged/notmuch-lua

" If you are using packer
set rtp+=~/.local/share/nvim/site/pack/packer/start/plenary.nvim
set rtp+=~/.local/share/nvim/site/pack/packer/start/nvim-treesitter
set rtp+=~/.local/share/nvim/site/pack/packer/start/telescope.nvim
set rtp+=~/.local/share/nvim/site/pack/packer/start/telescope-file-browser.nvim
set rtp+=~/.local/share/nvim/site/pack/packer/start/notmuch-lua

runtime! plugin/plenary.vim
runtime! plugin/nvim-treesitter.lua
runtime! plugin/telescope.lua

lua <<EOF
local galore = require('galore')
local dir = vim.fn.getcwd()

galore.setup({
	gpg_id = "Testi McTesti",
	nm_config = dir .. "/test/testdir/notmuch/notmuch-config",
	db_path = dir .. "/test/testdir/testdata/testmail"
})
EOF
