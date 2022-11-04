FROM ubuntu:latest

# Make code directory
RUN mkdir -p code/galore

# update, software-properties-common, git
RUN apt-get update && \
    apt install -y software-properties-common && \
    apt install -y git && \
    apt install -y curl && \
    apt install -y build-essential && \
    apt install -y luarocks &&\
    apt install -y notmuch &&\
    apt install -y libnotmuch-dev &&\
	apt install -y gobject-introspection &&\
	apt install -y libgirepository1.0-dev &&\
	apt install -y libgmime-3.0-dev &&\
	apt install -y meson

RUN add-apt-repository --yes ppa:neovim-ppa/unstable && \
    apt-get install -y neovim

# RUN luarocks install argparse && luarocks install luacheck
RUN luarocks install luacheck
RUN luarocks --lua-version 5.1 install lgi
RUN mkdir -p /tmp/
WORKDIR /tmp

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

RUN cargo install stylua
RUN cargo install lemmy-help --features=cli

# 'nvim-lua/popup.nvim',

# 'hrsh7th/nvim-cmp', -- optional
# 'dagle/cmp-notmuch', -- optional
# 'dagle/cmp-mates', -- optional

# Clone dependencies
RUN git clone https://github.com/nvim-lua/plenary.nvim.git /code/plenary.nvim
RUN git clone https://github.com/nvim-treesitter/nvim-treesitter.git /code/nvim-treesitter
RUN git clone https://github.com/nvim-telescope/telescope.nvim.git /code/telescope
RUN git clone https://github.com/nvim-telescope/telescope-file-browser.nvim.git /code/filebrowser
RUN git clone https://github.com/dagle/notmuch-lua.git /code/notmuch-lua

# Run tests when run container
# CMD bash
CMD cd /code/galore && \
    make test
    # make lint && \
    # make stylua && \
    # make emmy && \
