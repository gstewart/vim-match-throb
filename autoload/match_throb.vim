" File: match_throb.vim
" Author: g.stew
" Description: it throbs on search matches
" Last Modified: May 06, 2014

let s:save_cpo = &cpo
set cpo&vim


function! s:get_hl_IncSearch() "{{{
  let hl = {}
  call map(split(&highlight, ','), 'extend(hl, {v:val[0]: v:val[2:]})')

  return get(hl, 'i', 'IncSearch')
endfunction "}}}


function! match_throb#init() "{{{
  if exists('g:match_throb_init') && g:match_throb_init
    return
  endif
  let g:match_throb_init = 1

  let g:match_throb_debug_log = get(g:, 'match_throb_debug_log', 0)
  let g:match_throb_repeat = get(g:, 'match_throb_repeat', 1)
  let g:match_throb_sleep = get(g:, 'match_throb_sleep', 20)

  let g:match_throb_sticky = get(g:, 'match_throb_sticky', 1)

  let g:match_throb_hl_sequence = get(g:, 'match_throb_hl_sequence', [
        \ "guifg=#7295C2 guibg=#2569C2",
        \ "guifg=#9272C2 guibg=#3874C2",
        \ "guifg=#C272AF guibg=#4C7FC2",
        \ "guifg=#C27872 guibg=#5F8AC2",
        \ "guifg=#C2AD72 guibg=#7295C2"
        \ ])

  let g:match_throb_sticky_hl = get(g:, 'match_throb_sticky_hl', s:get_hl_IncSearch())

  let g:match_throb_hide_hlsearch = get(g:, 'match_throb_hide_hlsearch', 1)


  let g:match_throb_group = 'throbHL'

endfunction "}}}
call match_throb#init()





function! s:get_default_sticky_colors() "{{{
  let hl = {}
  call map(split(&highlight, ','), 'extend(hl, {v:val[0]: v:val[2:]})')

  let group = get(hl, 'i', get(g:, 'match_throb_default_sticky_group', 'IncSearch'))

  let synId = synIDtrans(hlID(group))

  let guifg = synIDattr(synId, "fg")
  let guibg = synIDattr(synId, "bg")

  return printf('guifg=%s guibg=%s', guifg, guibg)
endfunction "}}}


" commands "{{{
let s:commands = {
      \ 'redraw'   : 'redraw',
      \ 'matchdel' : 'call matchdelete(r)',
      \ 'clear'    : 'call match_throb#clear_matches()',
      \ 'hl'       : {
      \   'link' : 'highlight! link %s %s',
      \   'args' : 'highlight! %s %s'
      \   }
      \ }

function! s:commands.sleep(time) "{{{
  return printf('sleep %sms', a:time)
endfunction "}}}

function! s:commands.highlight(hlArg) "{{{
  let cmd_fmt = (hlexists(a:hlArg)) ? self.hl.link : self.hl.args

  return printf(cmd_fmt, g:match_throb_group, a:hlArg)
endfunction "}}}

function! s:commands.matchadd(pattern) "{{{
  return "let r = matchadd('" . g:match_throb_group . "', '" . a:pattern . "')"
endfunction "}}}

 "}}}


function! s:get_throb_step(count, time, hiColors, pattern) "{{{
  " add the part of the step that just runs once
  let _step = []
  call add(_step, s:commands.clear)
  call add(_step, s:commands.highlight(a:hiColors))

  " add the part of the step that is repeatable
  let _rstep = []
  call add(_rstep, s:commands.matchadd(a:pattern))
  call add(_rstep, s:commands.redraw)
  call add(_rstep, s:commands.sleep(a:time))
  call add(_rstep, s:commands.matchdel)
  call add(_rstep, s:commands.redraw)
  call add(_rstep, s:commands.sleep(a:time))

  return extend(_step, repeat(_rstep, a:count))
endfunction "}}}


function! s:get_sticky_step(hiColors, pattern) "{{{
  let _step = []

  call add(_step, s:commands.clear)
  call add(_step, s:commands.highlight(a:hiColors))
  call add(_step, s:commands.matchadd(a:pattern))
  call add(_step, s:commands.redraw)

  return _step
endfunction "}}}


" args
"   (hlSequence) single string with hiColors (repeat and sleep time use g:match_throb_repeat and g:match_throb_sleep
"   example: match_throb#throb_sequence("guifg=#1F1F1F" guibg=#2569C2")
"
"   hlSequence as string with highlight colors

function! match_throb#throb_sequence() "{{{
  call match_throb#do_throb_sequence(g:match_throb_hl_sequence)
endfunction "}}}


" hlSequence can be:
"   1. a string with highlight colors like 'guifg=#1F1F1F guibg=#2569C2'
"   2. a string with an existing highlight group name
"   3. a list of stings like 1 or 2
"   4. a list of dicts with keys (count, time, hiColors)

function! s:get_hl_sequence_arg(hlSequence, ...) "{{{
  let sequence_repeat = (a:0 >= 1) ? (a:1 + 0) : g:match_throb_repeat
  let sequence_sleep = (a:0 >= 2) ? (a:2 + 0) : g:match_throb_sleep

  if type(a:hlSequence) == type("")
    return [{'count': sequence_repeat, 'time': sequence_sleep, 'hiColors': a:hlSequence}]
  elseif type(a:hlSequence) == type([])
    if len(a:hlSequence) > 0
      let item_type = get(a:hlSequence, 0)

      if type(item_type) == type("")
        return map(a:hlSequence, '{"count": sequence_repeat, "time": sequence_sleep, "hiColors": v:val}')
      elseif type(item_type) == type({})
        return a:hlSequence
      else
        throw 'invalid type for hlSequence'
      endif
    else
      throw 'invalid list with no items for hlSequence'
    endif
  else
    throw 'invalid type for hlSequence'
  endif
endfunction "}}}


function! match_throb#do_throb_sequence(hlSequence, ...) "{{{
  " let sequence_repeat = (a:0 >= 1) ? (a:1 + 0) : g:match_throb_repeat
  " let sequence_sleep = (a:0 >= 2) ? (a:2 + 0) : g:match_throb_sleep
  "
  " let seq = (type(a:hlSequence) == type("")) ?
  "       \ [{'count': sequence_repeat, 'time': sequence_sleep, 'hiColors': a:hlSequence}] :
  "       \ ((type(a:hlSequence) == type([])) ?
  "       \ map(a:hlSequence, '{"count": sequence_repeat, "time": sequence_sleep, "hiColors": v:val}') : a:hlSequence)

  let seq = call('s:get_hl_sequence_arg', [a:hlSequence] + a:000)

  let param = substitute(getreg('/'), "'", "''", "g")
  let pos = getpos('.')
  let pattern = '\%'.pos[1].'l\%'.pos[2].'c'.param.'\c'

  " store the current matches so it can return to current state if aborted
  let save_matches = getmatches()
  let save_hlsearch = &hlsearch

  let cmds = []

  if g:match_throb_hide_hlsearch
    call add(cmds, 'set nohlsearch')
  endif


  " NOTE: shouldn't need now since it should always be list of dicts now
  " for entry in seq
  "   if type(entry) == type({})
  "     call extend(cmds, s:get_throb_step(entry.count, entry.time, entry.hiColors, pattern ))
  "   else
  "     call extend(cmds, s:get_throb_step(sequence_repeat, sequence_sleep, entry, pattern))
  "   endif
  " endfor
  for entry in seq
    call extend(cmds, s:get_throb_step(entry.count, entry.time, entry.hiColors, pattern))
  endfor


  if g:match_throb_hide_hlsearch
    call add(cmds, 'let &hlsearch = save_hlsearch')
  endif

  if g:match_throb_sticky
    " TODO: no way to pass this so always using the global var
    call extend(cmds, s:get_sticky_step(g:match_throb_sticky_hl, pattern))
  endif

  if g:match_throb_debug_log
    PPmsg cmds
  endif

  for cmd in cmds
    exec cmd

    " abort and reset matches to saved if a key is pressed during sequence
    if getchar(1) != 0
      if g:match_throb_debug_log
        echomsg 'match_throb#throb_sequence: aborting and restoring previous saved matches'
      endif
      call setmatches(save_matches)
      break
    endif

  endfor

  " reset hlsearch if it wasn't reset already 
  if g:match_throb_hide_hlsearch && &hlsearch != save_hlsearch
    let &hlsearch = save_hlsearch
  endif

endfunction "}}}


" Blinks the first result when executing search command with / or ?
" don't really like this. not sure if it works right here.
function! match_throb#throb_expr(count, time, hiColors) "{{{
  let cmdtype = getcmdtype()
  if cmdtype == '/' || cmdtype == '?'
    return "\<CR>:call call(\"match_throb#throb_sequence\", ".a:000.")\<CR>"
  endif
  return "\<CR>"
endfunction "}}}


function! match_throb#clear_matches() "{{{
  let group_matches = filter(getmatches(), "v:val.group =~? '" . g:match_throb_group . "'")
  let group_ids = map(group_matches, 'v:val.id')

  call map(group_ids, 'matchdelete(v:val)')
endfunction "}}}



let &cpo = s:save_cpo
unlet s:save_cpo


