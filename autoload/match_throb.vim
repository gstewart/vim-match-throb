" File: match_throb.vim
" Author: g.stew
" Description: it throbs on search matches
" Last Modified: March 04, 2014

let s:save_cpo = &cpo
set cpo&vim


function! match_throb#GetThrobStep(count, time, hiColors, pattern)
  " add the part of the step that just runs once
  let sleep_cmd = printf('sleep %sms', a:time)
  let redraw_cmd = 'redraw'
  let matchdel_cmd = 'call matchdelete(r)'

  let _step = []
  call add(_step, 'highlight throbHL ' . a:hiColors)

  " add the part of the step that is repeatable
  let _rstep = []
  call add(_rstep, "let r = matchadd('throbHL', '" . a:pattern . "')")
  call add(_rstep, redraw_cmd)
  call add(_rstep, sleep_cmd)
  call add(_rstep, matchdel_cmd)
  call add(_rstep, redraw_cmd)
  call add(_rstep, sleep_cmd)

  return extend(_step, repeat(_rstep, a:count))
endfunction


function! match_throb#ThrobSequence(hlSequence, ...)
  let default_sequence_repeat = 1
  let default_sequence_sleep = 35

  let sequence_repeat = (a:0 >= 1) ? (a:1 + 0) : default_sequence_repeat
  let sequence_sleep = (a:0 >= 2) ? (a:2 + 0) : default_sequence_sleep

  let seq = (type(a:hlSequence) == type("")) ? [a:hlSequence] : a:hlSequence

  let param = getreg('/')
  let pos = getpos('.')
  let pattern = '\%'.pos[1].'l\%'.pos[2].'c'.param.'\c'

  " store the current matches so it can return to current state if aborted
  let save_matches = getmatches()

  let cmds = []

  for entry in seq
    if type(entry) == type({})
      call extend(cmds, match_throb#GetThrobStep(entry.count, entry.time, entry.hiColors, pattern ))
    else
      call extend(cmds, match_throb#GetThrobStep(sequence_repeat, sequence_sleep, entry, pattern))
    endif
  endfor

  " PPmsg cmds

  for cmd in cmds
    exec cmd

    " abort and reset matches to saved if a key is pressed during sequence
    if getchar(1) != 0
      echomsg 'match_throb#ThrobSequence: aborting and restoring previous saved matches'
      call setmatches(save_matches)
      break
    endif

  endfor

endfunction


" Blinks the first result when executing search command with / or ?
" don't really like this. not sure if it works right here.
function! match_throb#ThrobExpr(count, time, hiColors)
  let cmdtype = getcmdtype()
  if cmdtype == '/' || cmdtype == '?'
    return "\<CR>:call call(\"match_throb#ThrobSequence\", ".a:000.")\<CR>"
  endif
  return "\<CR>"
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo


