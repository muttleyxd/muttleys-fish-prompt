# name: sashimi
function _get_username
  set display_hostname ""
  if test -n "$SSH_CONNECTION"
    set display_hostname (printf '@%s' (cat /etc/hostname))
  end
  printf '%s%s' $USER $display_hostname
end

function _get_path
  echo (string replace "$HOME" "~" "$PWD")
end

function _git_status
  git status --porcelain 2>/dev/null
end

function _separator
  if test "$argv" -gt 0
    echo "|"
  end
end

function _get_staged
  set added 0
  set modified 0
  set deleted 0
  
  for line in $argv
    switch $line
      case "A *"
        set added (math $added + 1)
      case "M *"
        set modified (math $modified + 1)
      case "D *"
        set deleted (math $deleted + 1)
    end
  end

  set -l yellow (set_color -o yellow)
  set -l red (set_color -o red)
  set -l green (set_color -o green)
  set -l normal (set_color normal)
  set -l output_str ""
  if test "$added" -gt 0
    set output_str (echo -s -n $output_str $green "A" $added $normal)
  end
  if test "$modified" -gt 0
    set output_str (echo -s -n $output_str (_separator (math $added)) $yellow "M" $modified $normal)
  end
  if test "$deleted" -gt 0
    set output_str (echo -s -n $output_str (_separator (math $added + $modified)) $red "D" $deleted $normal)
  end

  if test "$output_str" = ""
    echo ""
  else
    echo -s $green ☑ $normal \($output_str\)
  end
end

function _get_unstaged
  set added 0
  set modified 0
  set deleted 0
  set new 0
  
  for line in $argv
    switch $line
      case " A*"
        set added (math $added + 1)
      case " M*"
        set modified (math $modified + 1)
      case " D*"
        set deleted (math $deleted + 1)
      case "??*"
        set new (math $new + 1)
    end
  end

  set -l yellow (set_color -o yellow)
  set -l red (set_color -o red)
  set -l green (set_color -o green)
  set -l normal (set_color normal)
  
  set -l output_str ""
  if test "$added" -gt 0
    set output_str (echo -s -n $output_str $green "A" $added $normal)
  end
  if test "$modified" -gt 0
    set output_str (echo -s -n $output_str (_separator (math $added)) $yellow "M" $modified $normal)
  end
  if test "$deleted" -gt 0
    set output_str (echo -s -n $output_str (_separator (math $added + $modified)) $red "D" $deleted $normal)
  end
  if test "$new" -gt 0
    set output_str (echo -s -n $output_str (_separator (math $added + $modified + $deleted)) $yellow "+" $new $normal)
  end

  if test "$output_str" = ""
    echo ""
  else    
    echo -s $yellow ☐ $normal \($output_str\)
  end
end

function _git_dirty_info
  set -l staged (_get_staged $argv)
  set -l unstaged (_get_unstaged $argv)

  if test "$staged" != ""
    echo -s " " $staged
  end
  if test "$unstaged" != ""
    echo -s " " $unstaged
  end
end

function _git_ahead_behind
  set -l commits (command git rev-list --left-right '@{upstream}...HEAD' ^/dev/null)
  if [ $status != 0 ]
    return
  end
  set -l behind (count (for arg in $commits; echo $arg; end | grep '^<'))
  set -l ahead  (count (for arg in $commits; echo $arg; end | grep -v '^<'))

  set -l cyan (set_color -o cyan)
  set -l normal (set_color normal)

  if test "$behind" -gt 0
    echo -s "▼" $behind
  end
  if test "$ahead" -gt 0
    echo -s "▲" $ahead
  end
end

function _is_git
  # UNCOMMENT IF LAGGY return 1
  if test "$argv" -eq 0
    return 0
  else
    return 1
  end
end

function _git_stash_size
  set -l stash_size (git stash list | wc -l)
  if test "$stash_size" -eq 0
    return
  end
  
  set -l brcyan (set_color -o brcyan)
  set -l normal (set_color normal)
  echo -s -n " " $brcyan ⚑ $stash_size $normal
end

function _git_head_name
  git rev-parse --abbrev-ref HEAD 2>/dev/null
end

function _git_prompt
  set -l git_status (_git_status)
  if not _is_git $status
    return
  end
  
  set -l whitespace " "
  set -l cyan (set_color -o cyan)
  set -l white (set_color -o white)
  set -l normal (set_color normal)
  
  echo -s -n " git:(" $cyan (_git_head_name) $normal (_git_ahead_behind) (_git_dirty_info $git_status) (_git_stash_size) ") "
end

function fish_prompt
  set -l last_status $status
  set -l cyan (set_color -o cyan)
  set -l yellow (set_color -o yellow)
  set -l red (set_color -o red)
  set -l blue (set_color -o blue)
  set -l green (set_color -o green)
  set -l bryellow (set_color -o bryellow)
  set -l normal (set_color normal)

  set -l whitespace ' '

  if test $last_status = 0
    set initial_indicator "$green◆$normal"
    set status_indicator "$normal\$"
  else
    set initial_indicator "$red◆ $last_status$normal"
    set status_indicator "$red\$$normal"
  end

  set path_str (echo -s -n $bryellow (_get_path) $normal)

  echo -n -s (_get_username) $whitespace $initial_indicator $whitespace $path_str (_git_prompt) $status_indicator $whitespace
end
