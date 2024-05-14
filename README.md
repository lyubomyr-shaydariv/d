`d` is your ⭐ _fav dirs_ ⭐ in Bash.
It's even shorter than `cd` (well, why not?).

`d` can work in two modes:

- fully operational mode: it can run as a `source`d function named `d`;
- limited mode: it also can run as an externally executed script `d.sh` (in this mode `d` cannot change the parent shell current directory and it also cannot receive array-based configuration settings in full).

## Installation

### Fully operational mode

* copy `d.sh` to a whichever directory yor like;
* run `source d.sh` to enable `d` for the current shell (can be disabled with `unset d`);
* or, for permanent use, add `source d.sh` to your `~/.bashrc` (or whatever configuration file Bash picks up on your system).

Verify the installation with `type -t d`: the expected output is `function`.

### Limited mode

* copy `d.sh` to a whichever directory yor like, preferably to one specified in the `PATH` environment variable.

Verify the installation with `type -t d.sh`: the expected output is `file`.

## Usage

### Syntax

```
d [<COMMAND> [OPT...] [ARG...]]
```

or

```
d.sh [<COMMAND> [OPT...] [ARG...]]
```

### Command reference

| Command | Descripton |
| --- | --- |
| `add [-f\|--force] [dir...]` | add `pwd` or directories to the fav dirs file |
| `clear [-f\|--force]` | clear the fav dirs file |
| `config` | show effective configuration |
| `cd [-p\|--parents]` | change current directory (default)<br/>has no `cd` effect if d is executed as a script (not `source`d) |
| `edit` | edit the fav dirs file |
| `ls` | list the fav dirs file |
| `prune` | prune missing directories from the fav dirs file |
| `rm [dir...]` | remove directories from the fav dirs file |
| `help` | show this help |

### Configuration

`d` uses the following variables for its configuration:

| Variable | Bash type | Default | Description |
| --- | --- | --- | --- |
| `D_CONFIG_DIR` | string | `$HOME` | The default `d` home directory where it stores its data. |
| `D_FAV_DIRS_FILE` | string | `$HOME/.d` | The fav dirs file where favorite directories are stored in. |
| `D_PARENTS` | integer | `0` | A switch affecting the `cd` command: show parent directories recursively or not. |
| `D_SELECT_MANY` | array | `fzf` `--tac` `--multi` | Filter command to return arbitrary number of entries from the fav dirs file. |
| `D_SELECT_ONE` | array | `fzf` `--tac` | Filter command to return at most one entry from the fav dirs file. |

Note that array variables, when `export`ed, cannot be _fully_ passed to `d.sh` if it's executed as a child process.
his limitation makes `D_SELECT_MANY` and `D_SELECT_ONE` work only as single value variables (effectively, these can only target to a filter program without options being passed).
