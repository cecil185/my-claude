# my-claude
# Personal Claude Code configuration, scripts, and tooling.
#
# See 'just --list' for all available commands

# Show available commands
default:
    @just --list

# Install pre-commit hooks
pre-commit-install:
    pre-commit install --hook-type commit-msg --hook-type pre-commit

# Run pre-commit on all files
pre-commit-run:
    pre-commit run --all-files
