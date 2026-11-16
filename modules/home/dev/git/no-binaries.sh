# no-binaries: global pre-commit hook. newly added files git sees as binary
# (images excepted) get unstaged and written to .git/info/exclude
exclude="$(git rev-parse --git-path info/exclude)"
mkdir -p "$(dirname "$exclude")"

dropped=0
while IFS=$'\t' read -r -d '' added _ path
do
  [[ $added == "-" ]] || continue
  mime="$(git cat-file blob ":$path" | file -b --mime-type -)"
  [[ $mime == image/* ]] && continue

  git rm -q --cached -- "$path"
  grep -qxF "/$path" "$exclude" 2>/dev/null || printf '/%s\n' "$path" >> "$exclude"
  echo "no-binaries: ignored $path ($mime)" >&2
  dropped=1
done < <(git diff --cached --numstat --diff-filter=A --no-renames -z)

if (( dropped )) && git diff --cached --quiet
then
  echo "no-binaries: nothing left to commit" >&2
  exit 1
fi
