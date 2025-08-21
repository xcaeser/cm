# Release v0.1.0 - Initial Release

Public release of **Cumul**!

`cumul` is a simple yet powerful command-line utility, written in Zig, designed to help developers and researchers consolidate source code and text files into a single file.

This is especially useful for providing large amounts of context to Large Language Models (LLMs) for analysis, review, or training.

This initial version lays the foundation for a fast and reliable developer tool that streamlines your workflow with AI.

## ✨ Key Features

- **File Concatenation**: Recursively scans a directory and combines all valid text files into a single, well-formatted `...-cumul.txt` file.
- **Smart `.gitignore` Integration**: Automatically respects the rules in your project's `.gitignore` file, ensuring that ignored files and build artifacts are not included in the output.
- **Intelligent Filtering**: Skips binary files (like images), hidden dotfiles, and other non-essential files to keep the output clean and relevant.
- **Simple & Fast CLI**: A straightforward command-line interface (`cm`) that gets the job done quickly.
- **Customizable Output**: Use the `-p` or `--prefix` flag to add a custom prefix to the output filename, making it easier to manage multiple contexts.
- **Cross-Platform**: Binaries are provided for Linux and macOS on both `x86_64` (Intel) and `aarch64` (Apple Silicon, ARM) architectures.

## 🚀 Installation

You can easily install `cumul` using our automated script. It will detect your operating system and architecture and install the correct binary into `/usr/local/bin`.

```sh
curl -sSfL https://raw.githubusercontent.com/xcaeser/cm/main/install.sh | sh
```

## Usage Examples

1.  **Run in the current directory:**

    ```sh
    cm
    ```

    _This will generate a file like `my-project-cumul.txt`._

2.  **Specify a target directory:**

    ```sh
    cm ../path/to/another-project
    ```

3.  **Add a prefix to the output file:**
    ````sh
    cm -p feature-branch .
    ```    *This will generate a file named `feature-branch-my-project-cumul.txt`.*
    ````

## Binaries Included in this Release

- `cumul-linux-x86_64.tar.gz`
- `cumul-linux-aarch64.tar.gz`
- `cumul-macos-x86_64.tar.gz`
- `cumul-macos-aarch64.tar.gz`

Thank you for checking out the project.

Contributions are welcome.
