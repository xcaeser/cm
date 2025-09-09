# Cumul

`cm` is a fast CLI tool that concatenates text files in a directory into one output file, ideal for LLM context.

It respects `.gitignore`, skips binaries, dotfiles, and non-text formats (e.g., images).

Executable name: `cm`.

[![Zig Version](https://img.shields.io/badge/Zig_Version-0.16.0-orange.svg?logo=zig)](README.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-lightgrey.svg?logo=cachet)](LICENSE)
[![Built by xcaeser](https://img.shields.io/badge/Built%20by-@xcaeser-blue)](https://github.com/xcaeser)
[![Version](https://img.shields.io/badge/cumul-v0.1.7-green)](https://github.com/xcaeser/cm/releases)

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/xcaeser/cm/main/install.sh | bash
```

## Usage

### Basic

```bash
cm [directory]
```

Generates `<directory-name>-cumul.txt` with file headers

> running only `cm` scans the current directory

### Options

- `-p, --prefix <string>`: Prefix output filename (e.g., `cm -p my` → `my-<dir>-cumul.txt`).
- `-e, --exclude <string>`: Comma-separated exclusions (e.g., `cm -e .json,.md,LICENSE,.sh,lib/utils.ts` etc...).
- `-v, --version`: Show version.
- `-h, --help`: Show help.

Outputs summary: files cumulated, lines, size.

## Features

- Concatenates files with headers.
- Integrates `.gitignore` (wildcards supported).
- Filters non-text/dotfiles/output.
- Custom exclusions.

## Installation from Source

```bash
zig build install
```

Installs `cm` to `$HOME/.local/bin`.
