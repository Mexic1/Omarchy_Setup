# shellcheck shell=bash
# shellcheck disable=SC2086 # $SUDO is intentionally unquoted (empty when root)
# Transactions: every change install makes is journaled so it can be rolled back.
#
#   $STATE_DIR/
#     transactions/<id>/journal   one tab-separated line per change
#     transactions/<id>/backup/   originals of files replaced by links (paths relative to $HOME)
#     last -> transactions/<id>   most recent committed transaction
#     links.manifest              links owned by the repo after the last install
#     migrations.done             migrations already applied
#     profile                     profile used by the last install
#
# Journal ops: LINK dest src · UNLINK dest src · BACKUP dest backup · SERVICE scope unit

STATE_DIR=${DOTCTL_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/omarchy-setup}
TXN_ID='' TXN_DIR=''

txn_begin() {
  TXN_ID=$(date +%Y%m%d-%H%M%S)-$$
  TXN_DIR=$STATE_DIR/transactions/$TXN_ID
  ((DRY_RUN)) && return 0
  mkdir -p "$TXN_DIR/backup"
  : >"$TXN_DIR/journal"
}

txn_record() {
  ((DRY_RUN)) && return 0
  local IFS=$'\t'
  printf '%s\n' "$*" >>"$TXN_DIR/journal"
}

txn_commit() {
  ((DRY_RUN)) && return 0
  if [[ ! -s $TXN_DIR/journal ]]; then
    rm -rf "$TXN_DIR"
    return 0
  fi
  ln -sfn "transactions/$TXN_ID" "$STATE_DIR/last"
  info "transaction $TXN_ID saved (undo with: bin/dotctl rollback)"
}

# Replays a journal backwards. Packages are never uninstalled (see docs/updates-and-rollback.md).
txn_rollback() {
  local dir=$1 op a b
  [[ -f $dir/journal ]] || die "no journal in $dir"
  while IFS=$'\t' read -r op a b; do
    case $op in
      LINK)
        if [[ -L $a && $(readlink "$a") == "$b" ]]; then
          run rm -f "$a"
        elif [[ -e $a || -L $a ]]; then
          # Changed since install (e.g. a program rewrote it): keep that version too.
          local keep=$dir/displaced/${a#"$HOME"/}
          warn "~/${a#"$HOME"/} changed since install; saved it to $keep"
          run mkdir -p "$(dirname "$keep")" && run mv -Tf "$a" "$keep"
        fi
        ;;
      UNLINK) run mkdir -p "$(dirname "$a")" && run ln -sfn "$b" "$a" ;;
      BACKUP) run mkdir -p "$(dirname "$a")" && run mv -Tf "$b" "$a" ;;
      SERVICE)
        if [[ $a == user ]]; then
          run systemctl --user disable --now "$b" || true
        else
          run $SUDO systemctl disable --now "$b" || true
        fi
        ;;
    esac
    debug "undid $op $a"
  done < <(tac "$dir/journal")
  ((DRY_RUN)) || date -Is >"$dir/ROLLED_BACK"
}

txn_list() {
  local d
  for d in "$STATE_DIR"/transactions/*/; do
    [[ -d $d ]] || continue
    local id status=applied
    id=$(basename "$d")
    [[ -f $d/ROLLED_BACK ]] && status="rolled back"
    printf '  %s  %-12s %s journal entries\n' "$id" "$status" "$(wc -l <"$d/journal")"
  done
}

migrations_done() { [[ -f $STATE_DIR/migrations.done ]] && cat "$STATE_DIR/migrations.done"; }
