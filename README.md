# copilot-container

Run the [GitHub Copilot CLI](https://github.com/github/copilot-cli) inside a
disposable container. Your current directory is mounted as `/workspace`, your
host Git identity and GitHub token are forwarded in, and the CLI runs with
`--allow-all` (safe, because it's confined to the container).

Works with **Docker or Podman** (auto-detected). No Nix required.

## Files

- `Dockerfile` — the container image.
- `copilot-container` — the host-side wrapper script that builds/runs the image.

## 1. Build the image

From the directory containing these files:

```bash
docker build . -f Dockerfile -t copilot-container
```

(Podman users: `podman build . -f Dockerfile -t copilot-container`.)

The wrapper also builds the image automatically on first run, so this step is
optional — but doing it once up front avoids a wait on your first invocation.

## 2. Install the wrapper

Copy the wrapper script somewhere on your `PATH` and make it executable:

```bash
install -Dm755 copilot-container ~/.local/bin/copilot-container
```

The wrapper looks for `Dockerfile` next to itself by default.
If you install the script elsewhere from the Dockerfile, point it at the
Dockerfile explicitly with `DOCKERFILE_PATH` (see below).

## 3. Add the alias

Add this one line to your `~/.bashrc` (or `~/.zshrc`) and restart your shell:

```bash
alias copilot='~/.local/bin/copilot-container'
```

## Usage

```bash
copilot                       # start an interactive Copilot session in $PWD
copilot "fix the failing test"  # one-shot prompt
copilot --resume              # resume from the persistent global-resume dir
copilot bash                  # drop into a shell inside the container
copilot update                # rebuild the image with --no-cache (keeps a backup tag)
```

## Authentication

The wrapper resolves a GitHub token in this order:

1. `COPILOT_GITHUB_TOKEN`
2. `GH_TOKEN`
3. `gh auth token` (i.e. your local `gh` login)

So if you already use the `gh` CLI, no extra setup is needed.

## Configuration

All optional, set as environment variables:

| Variable             | Default                          | Purpose                                            |
| -------------------- | -------------------------------- | -------------------------------------------------- |
| `IMAGE_NAME`         | `copilot-container`              | Image tag to build/run.                            |
| `CONTAINER_ENGINE`   | auto (`docker`, else `podman`)   | Force a specific container engine.                 |
| `DOCKERFILE_PATH`    | `Dockerfile` next to the wrapper | Where to find the Dockerfile.    |
| `HOST_COPILOT_HOME`  | `${XDG_DATA_HOME:-~/.local/share}/copilot-cli` | Host dir for persistent Copilot state. |
| `COPILOT_NTFY_TOPIC` | *(empty / disabled)*             | [ntfy.sh](https://ntfy.sh) topic for notifications.|
| `COPILOT_GITHUB_TOKEN` / `GH_TOKEN` | *(from `gh`)*     | GitHub token override.                             |

### Notifications (optional)

Set `COPILOT_NTFY_TOPIC` to an [ntfy.sh](https://ntfy.sh) topic to get a push
notification when Copilot is waiting for your input or has finished:

```bash
export COPILOT_NTFY_TOPIC="my-unique-topic-name"
```

Subscribe to the same topic in the ntfy app or at `https://ntfy.sh/my-unique-topic-name`.
Leave it unset to disable notifications entirely.

## Persistent state

Sessions, resume data, hooks, and settings are stored on the host under
`HOST_COPILOT_HOME` and mounted into the container at `/copilot-state`. On first
run the wrapper seeds:

- `settings.json` — auto-trusts `/workspace` so Copilot doesn't prompt on start.
- `hooks/notify.json` — wires up the ntfy notification hooks.
- `copilot-instructions.md` — instructs the agent to commit as your host Git
  identity (never as a tool/bot).

Delete that directory to reset all state.

## Notes

- The container runs as your host UID/GID, so files it creates in `/workspace`
  are owned by you.
- `--network=host` is used so the CLI can reach GitHub and ntfy directly.
- `--allow-all` is intentional: the CLI is sandboxed inside the container, not on
  your host.
