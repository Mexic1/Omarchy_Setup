# shellcheck shell=bash
# Symlink plan: every file under features/<name>/home/ and profiles/<name>/home/
# is linked to the same path under $HOME. Files are linked one by one (never
# whole directories), so Omarchy's own files next to them are left alone.
# A path may belong to only one feature; a profile overlay may override it.

declare -gA LINK_PLAN=()  # dest -> src
declare -gA LINK_OWNER=() # dest -> feature/profile that provides it

# link_collect OWNER DIR [override]
link_collect() {
  local owner=$1 root=$2 override=${3:-} src rel dest
  [[ -d $root ]] || return 0
  while IFS= read -r -d '' src; do
    rel=${src#"$root"/}
    dest=$HOME/$rel
    if [[ -n ${LINK_PLAN[$dest]:-} && -z $override ]]; then
      die "$rel is provided by both ${LINK_OWNER[$dest]} and $owner (one owner per file; use a profile overlay to override)"
    fi
    LINK_PLAN[$dest]=$src
    LINK_OWNER[$dest]=$owner
  done < <(find "$root" \( -type f -o -type l \) ! -name '.gitkeep' -print0)
}

# State of one planned link: ok | missing | identical (regular file, same content) |
# drifted (regular file, different content) | foreign (link elsewhere) | blocked (directory)
link_state() {
  local dest=$1 src=$2
  if [[ -L $dest ]]; then
    [[ $(readlink "$dest") == "$src" ]] && echo ok || echo foreign
  elif [[ -d $dest ]]; then
    echo blocked
  elif [[ -e $dest ]]; then
    cmp -s "$dest" "$src" && echo identical || echo drifted
  else
    echo missing
  fi
}

# Replaces DEST with a link to SRC atomically: the original is copied to the
# transaction backup first, then a temp link is renamed over it, so DEST is
# never missing even if the run is interrupted.
link_apply_one() {
  local dest=$1 src=$2 state
  state=$(link_state "$dest" "$src")
  case $state in
    ok) return 0 ;;
    blocked) die "$dest is a directory; expected a file" ;;
  esac
  changed
  info "link ~/${dest#"$HOME"/} ($state)"
  ((DRY_RUN)) && return 0

  mkdir -p "$(dirname "$dest")"
  if [[ $state != missing ]]; then
    local backup=$TXN_DIR/backup/${dest#"$HOME"/}
    mkdir -p "$(dirname "$backup")"
    cp -a "$dest" "$backup"
    txn_record BACKUP "$dest" "$backup"
  fi
  local tmp="$dest.dotctl-tmp.$$"
  ln -sfn "$src" "$tmp"
  mv -Tf "$tmp" "$dest"
  txn_record LINK "$dest" "$src"
}

# Removes links from a previous install that no feature provides any more.
link_prune() {
  local manifest=$STATE_DIR/links.manifest dest
  [[ -f $manifest ]] || return 0
  while IFS= read -r dest; do
    [[ -n ${LINK_PLAN[$dest]:-} ]] && continue
    [[ -L $dest && $(readlink "$dest") == "$REPO_DIR"/* ]] || continue
    changed
    info "unlink ~/${dest#"$HOME"/} (no longer provided)"
    txn_record UNLINK "$dest" "$(readlink "$dest")"
    run rm -f "$dest"
  done <"$manifest"
}

link_apply_all() {
  local dest
  local -a dests
  mapfile -t dests < <(link_dests)
  for dest in "${dests[@]}"; do
    link_apply_one "$dest" "${LINK_PLAN[$dest]}"
  done
  if ((DRY_RUN)); then
    ((PARTIAL)) || link_prune
    return 0
  fi

  local manifest=$STATE_DIR/links.manifest
  if ((PARTIAL)); then
    # --only/--skip runs see just part of the plan: keep the other links.
    sort -u <(link_dests) "$manifest" 2>/dev/null >"$manifest.new" || link_dests >"$manifest.new"
  else
    link_prune
    link_dests >"$manifest.new"
  fi
  mv -f "$manifest.new" "$manifest"
}

link_dests() {
  ((${#LINK_PLAN[@]})) || return 0
  printf '%s\n' "${!LINK_PLAN[@]}" | sort
}
