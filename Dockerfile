FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/usr/local/bin:/usr/bin:/bin"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        git \
        python3 \
        python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install gh from GitHub's official apt repo so the CLI stays up to date
# (Ubuntu's bundled package can lag well behind upstream).
RUN mkdir -p -m 755 /etc/apt/keyrings \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        -o /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh

RUN /usr/local/bin/uv tool install ruff

RUN curl -fsSL https://gh.io/copilot-install | bash

# ntfy.sh notification hooks. The topic is provided at *runtime* via the
# COPILOT_NTFY_TOPIC environment variable (see the copilot-container wrapper),
# so the image itself stays generic and shareable. When the variable is empty,
# both scripts are a no-op.
RUN mkdir -p /usr/local/bin/copilot-hooks \
    && printf '%s\n' \
        '#!/usr/bin/env bash' \
        '# Backgrounded so this never adds latency when used from a blocking hook (e.g. preToolUse).' \
        '[ -z "${COPILOT_NTFY_TOPIC:-}" ] && exit 0' \
        '(curl -fsS -d "Copilot is waiting for me" "https://ntfy.sh/${COPILOT_NTFY_TOPIC}" >/dev/null 2>&1 &) || true' \
        > /usr/local/bin/copilot-hooks/notify-waiting.sh \
    && printf '%s\n' \
        '#!/usr/bin/env bash' \
        '[ -z "${COPILOT_NTFY_TOPIC:-}" ] && exit 0' \
        'curl -fsS -d "Copilot is done" "https://ntfy.sh/${COPILOT_NTFY_TOPIC}" >/dev/null 2>&1 || true' \
        > /usr/local/bin/copilot-hooks/notify-done.sh \
    && chmod +x /usr/local/bin/copilot-hooks/notify-waiting.sh /usr/local/bin/copilot-hooks/notify-done.sh

WORKDIR /workspace
CMD ["bash"]
