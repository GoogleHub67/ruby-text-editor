# RubyCode++ Professional Text Editor

A modern, light, cross-platform **Tabbed Source Code Text Editor** built using Ruby and the native Tk GUI framework toolkit ecosystem.

## 🛠️ System Prerequisites

Your operating system must have a valid underlying **Tcl/Tk library installation** present before installing the Ruby library wrapper:

*   **macOS**: `brew install tcl-tk`
*   **Linux (Ubuntu/Debian)**: `sudo apt-get install tcl-dev tk-dev`
*   **Windows**: Included by default via standard RubyInstaller packages.

Official Project Documentation Resources:
*   Windows Package Setup: [RubyInstaller Portal](https://rubyinstaller.org/ "RubyInstaller for Windows")
*   Package Distribution: [RubyGems Library Service](https://rubygems.org/ "RubyGems.org")

## 🚀 Running the Project

1. Install project-level developer dependencies:
   ```bash
   bundle install
   ```
2. Start the interactive desktop application frame:
   ```bash
   bundle exec rake run
   ```

## 🧪 Testing Environment

Run style audits and verified unit tests via:
```bash
bundle exec rake
```
