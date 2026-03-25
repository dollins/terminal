FROM fedora:43-minimal

RUN microdnf install -y git curl jq bc nodejs npm openssh-server passwd && \
    microdnf clean all

RUN npm install -g @anthropic-ai/claude-code

RUN useradd -m -s /bin/bash petr && \
    echo "petr ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# SSH server setup
RUN ssh-keygen -A && \
    mkdir -p /run/sshd && \
    sed -i 's/#PermitUserEnvironment no/PermitUserEnvironment yes/' /etc/ssh/sshd_config

EXPOSE 22

USER petr
WORKDIR /home/petr

# Claude Code settings
RUN mkdir -p /home/petr/.claude
COPY statusline-command.sh /home/petr/.claude/statusline-command.sh
COPY settings.json /home/petr/.claude/settings.json

# Set remote host indicator for status line
RUN echo 'export CLAUDE_SSH_HOST="claude-work"' >> /home/petr/.bashrc

USER root
CMD ["/usr/sbin/sshd", "-D"]
