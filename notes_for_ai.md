# Notes for AI / Future Maintainers

## Handling filenames safely in shell scripts

To avoid issues with special characters (e.g., German umlauts, spaces, quotes), always:

1. Use `mapfile -t array < filelist.txt` instead of `while read`.
2. Quote all variables: `"$var"`, not `$var`.
3. Use `-print0` with `find` and `xargs -0` to handle null-delimited filenames.
4. Prefer arrays over line-based iteration when possible.

This avoids bugs where valid filenames become corrupted or unfindable.