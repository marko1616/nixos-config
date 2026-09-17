function abyss-greeting() {
  emulate -L zsh

  local greeting_file="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/greeting.txt"

  [[ -r "$greeting_file" ]] || return 1

  print -r -- "$(< "$greeting_file")"
}

if [[ -o interactive && -t 0 && -t 1 && "${TERM-}" != dumb &&
      "${ABYSS_GREETING_TTY-}" != "$TTY" ]]; then
  if abyss-greeting; then
    export ABYSS_GREETING_TTY="$TTY"
  fi
fi
