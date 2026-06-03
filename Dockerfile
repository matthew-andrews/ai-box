FROM node:22-bookworm

RUN apt-get update && apt-get install -y \
    openssh-server \
    git \
    curl \
    ripgrep \
    tmux \
    less \
    vim \
    python3 \
    build-essential \
    gh \
    jq \
    && rm -rf /var/lib/apt/lists/*

# glab isn't in Debian apt repos, install the official .deb from GitLab
RUN ARCH=$(dpkg --print-architecture) \
    && GLAB_TAG=$(curl -s "https://gitlab.com/api/v4/projects/gitlab-org%2Fcli/releases?per_page=1" | jq -r '.[0].tag_name') \
    && GLAB_VER=${GLAB_TAG#v} \
    && curl -sL "https://gitlab.com/gitlab-org/cli/-/releases/${GLAB_TAG}/downloads/glab_${GLAB_VER}_linux_${ARCH}.deb" -o /tmp/glab.deb \
    && dpkg -i /tmp/glab.deb \
    && rm /tmp/glab.deb

RUN npm install -g opencode-ai

RUN useradd -ms /bin/bash dev

RUN mkdir /var/run/sshd

RUN echo "PasswordAuthentication no" >> /etc/ssh/sshd_config

RUN mkdir -p /home/dev/.ssh && \
    chmod 700 /home/dev/.ssh

EXPOSE 22

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER dev

RUN git config --global push.default current && \
    echo 'alias agent="tmux new-session -A -s agent"' >> /home/dev/.bashrc && \
    echo 'pbcopy() { local input; input=$(cat); printf "\033]52;c;%s\a" "$(printf "%s" "$input" | base64 | tr -d "\n")"; }; pbpaste() { echo "pbpaste is not supported over OSC52"; }' >> /home/dev/.bashrc && \
    echo 'alias static="python3 -m http.server 8080"' >> /home/dev/.bashrc

RUN mkdir -p /home/dev/.vim/pack/plugins/start && \
    git clone --depth 1 https://github.com/pangloss/vim-javascript.git /home/dev/.vim/pack/plugins/start/vim-javascript && \
    git clone --depth 1 https://github.com/plasticboy/vim-markdown.git /home/dev/.vim/pack/plugins/start/vim-markdown && \
    git clone --depth 1 https://github.com/elzr/vim-json.git /home/dev/.vim/pack/plugins/start/vim-json && \
    git clone --depth 1 https://github.com/ekalinin/Dockerfile.vim.git /home/dev/.vim/pack/plugins/start/dockerfile && \
    git clone --depth 1 https://github.com/tpope/vim-fugitive.git /home/dev/.vim/pack/plugins/start/vim-fugitive && \
    git clone --depth 1 https://github.com/tpope/vim-commentary.git /home/dev/.vim/pack/plugins/start/vim-commentary && \
    git clone --depth 1 https://github.com/tpope/vim-surround.git /home/dev/.vim/pack/plugins/start/vim-surround && \
    git clone --depth 1 https://github.com/tpope/vim-repeat.git /home/dev/.vim/pack/plugins/start/vim-repeat && \
    git clone --depth 1 https://github.com/airblade/vim-gitgutter.git /home/dev/.vim/pack/plugins/start/vim-gitgutter && \
    git clone --depth 1 https://github.com/itchyny/lightline.vim.git /home/dev/.vim/pack/plugins/start/lightline && \
    rm -rf /home/dev/.vim/pack/plugins/start/*/.git

RUN cat > /home/dev/.vimrc << 'VIMRC'
syntax on
filetype plugin indent on
set number
set noexpandtab
set nofoldenable
VIMRC

RUN cat > /home/dev/.tmux.conf << 'TMUX'
set -g mouse on
set -g default-terminal "tmux-256color"
set -g set-clipboard on
set -g allow-passthrough on
set -g status-right "#{?session_grouped,alias ,}#S"
set -g status-interval 5
TMUX

RUN cat > /home/dev/.inputrc << 'INPUTRC'
set completion-ignore-case on
"\e[A": history-search-backward
"\e[B": history-search-forward
INPUTRC

WORKDIR /workspace

RUN npx skills add matthew-andrews/skills --skill github-autonomous-worker -g -a opencode -y && \
    npx skills add matthew-andrews/skills --skill autonomous-coding-agent -g -a opencode -y

USER root

ENTRYPOINT ["/entrypoint.sh"]
