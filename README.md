# Cumul

`cumul` is a fast, simple command-line utility written in Zig that concatenates all files in a directory into a single text file. This is particularly useful for providing context to Large Language Models (LLMs).

The tool scans a specified directory, respects the patterns in your `.gitignore` file, and intelligently skips binary files and other non-text formats (and node-modules).

## Features

- **File Concatenation**: Combines multiple files into a single output file.
- **`.gitignore` Integration**: Automatically ignores files and directories listed in `.gitignore`.
- **Smart Filtering**: Skips dotfiles, common image formats, and the output file itself.
- **Customizable Output**: Use a prefix for the generated filename.

## Installation

### From bash:

```bash
curl -sSfL https://raw.githubusercontent.com/xcaeser/cm/main/install.sh | sh
```

### From source:

You can build and install `cumul` using the Zig build system.

```bash
zig build install
```

This will place the `cm` executable in your `usr/local/bin` directory.

## Usage

The executable is named `cm`.

You can run `cm --help` or `cm -h`

### Basic Usage

To cumulate all files in the current directory, simply run:

```bash
cm
```

This will generate a file named `<directory-name>-cumul.txt`.

### Specifying a Directory

You can specify a target directory to scan:

```bash
cm path/to/your/project
```

### Adding a Prefix

You can add a prefix to the output filename using the `-p` or `--prefix` flag:

```bash
cm -p my-project .
```

This will create a file named `my-project-<directory-name>-cumul.txt`.

### Options

- `-p, --prefix <string>`: Add a prefix to the generated filename.
- `-v, --version`: Show the CLI version.
- `-h, --help`: Show help of the cumul command line interface.
