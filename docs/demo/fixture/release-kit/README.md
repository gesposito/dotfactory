# release-kit

Small shell scripts for cutting a release of any git repository.

| Command | What it does |
|---|---|
| `./changelog.sh <repo>` | Prints a changelog from the commits since the last tag. Only reads. |
| `./tag.sh <repo> <version>` | Creates the tag `v<version>` and pushes it. Changes the repository and its remote. |

Needs `git`. `tag.sh` also needs push access to the remote.
