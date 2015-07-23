prompt_end() {
  if [[ $UID -eq 0 ]]; then
    echo "%{%F{1}%} # %{%f%} "
  else
    if [[ ! -n "$VIRTUAL_ENV" ]]; then
      echo "%{%F{12}%} - %{%f%} "
    else
      echo "%{%F{1}%} - %{%f%} "
    fi
  fi
}
prompt_cwd() {
  # dir_limit, truncation and dir_sep can be configured
  local dir_limit="3"
  local truncation=".."
  local dir_sep="/"

  local first_char
  local part_count=0
  local formatted_cwd=""
  local cwd="${PWD/#$HOME/~}"

  # get first char of the path, i.e. tilde or slash
  [[ -n ${ZSH_VERSION-} ]] && first_char=$cwd[1,1] || first_char=${cwd::1}

  # remove leading tilde
  cwd="${cwd#\~}"

  while [[ "$cwd" == */* && "$cwd" != "/" ]]; do
    # pop off last part of cwd
    local part="${cwd##*/}"
    cwd="${cwd%/*}"

    formatted_cwd="$dir_sep$part$formatted_cwd"
    part_count=$((part_count+1))

    [[ $part_count -eq $dir_limit ]] && first_char="$truncation" && break
  done

  [[ "$formatted_cwd" != $first_char* ]] && formatted_cwd="$first_char$formatted_cwd"
  printf "%s" "$formatted_cwd"
}

prompt_remote() {
  if [[ -n "$SSH_CLIENT$SSH2_CLIENT$SSH_TTY" ]]; then
    echo -n "%{%K{3}%F{0}%} %m %{%f%k%}"
  fi
}
prompt_git() {
  local status_cmd
  local dirty=0
  if (( ! $+commands[git] )); then
    return 1
  fi
  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    branch="${$(git symbolic-ref HEAD 2> /dev/null)#refs/heads/}"
    if [[ -n $(git status -s --ignore-submodules=dirty 2> /dev/null) ]]; then
      echo -n "%{%K{6}%F{0}%} $branch %{%f%k%}"
    else
      echo -n "%{%K{13}%F{0}%} $branch %{%f%k%}"
    fi
  fi
}
prompt_dir() {
  local insert_indicator="%{%F{4}%}+%{%f%} "
  if [[ $PWD = $HOME ]] ; then
    echo "${${KEYMAP/vicmd/$insert_indicator}/(main|viins)/} %{%K{2}%F{0}%} ~ %{%f%k%}"
  else
    echo "${${KEYMAP/vicmd/$insert_indicator}/(main|viins)/} %{%K{10}%F{12}%} $(prompt_cwd | rev | cut -d / -f2- | rev | awk '{sub(ENVIRON["HOME"],"~");print}') %{%f%k%K{2}%F{0}%} %1~ %{%f%k%}"
  fi
}
prompt_status() {
  local symbols
  symbols=()
  [[ $UID -eq 0 ]] && symbols+="%{%F{yellow}%}⚡"
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{cyan}%}⚙"
  [[ $(tmux list-sessions 2> /dev/null | grep -cv attached) -gt 0 ]] && symbols+="%{%F{cyan}%}LOL"
  [[ -n "$symbols" ]] && echo -n "%F{1}$symbols%f"
}
build_prompt() {
  # prompt_status
  prompt_remote
  prompt_git
  prompt_end
}
PROMPT='$(build_prompt)'
RPS1='$(prompt_dir)'
