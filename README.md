# dot-files

Configuration dot files

Supported environments:
- Git Bash for Windows
- GNU Linux

## Pre-requisites

Install [starship](https://starship.rs/) for the command prompt.

## Install

### Manual parts

1. Copy [`.gitattributes`](.gitattributes) to any git repositories you create.

2. If you install programs that require additions to your shell (i.e. adding aliases, appending to $PATH, etc.),
 you will need to add them to [`bash/system`](bash/system) (generated during [auto install](#auto-install-script) from [`templates/bash/system`](templates/bash/system)).
 As these vary greatly depending on what programs you install, this cannot be automatically done.

### Auto-install script

#### Git Bash for Windows

1. Run Git Bash as an administrator (this is required for symlinks to work properly)

2. Run [`install.bash`](install.bash)

#### Linux

1. Run [`install.bash`](install.bash) (may require root permissions)
