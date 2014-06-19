"=============================================================================
" File: match_throb.vim
" Author: g.stew
" Version: 1.0
"=============================================================================

if exists('g:loaded_matchthrob')
  finish
endif
let g:loaded_matchthrob = 1

let s:old_cpo = &cpo
set cpo&vim


" let g:match_throb_default_repeat = 1
" let g:match_throb_default_sleep = 20

" let g:match_throb_default_colors = map(['#7295C2', '#5F8AC2', '#4C7FC2', '#3874C2', '#2569C2'], '"guibg=" . v:val')

" let g:match_throb_default_colors = map(['#7295C2', '#9272C2', '#C272AF', '#C27872', '#C2AD72'], '"guibg=" . v:val')

" let g:match_throb_default_colors = [
"       \ "guifg=#7295C2 guibg=#2569C2",
"       \ "guifg=#9272C2 guibg=#3874C2",
"       \ "guifg=#C272AF guibg=#4C7FC2",
"       \ "guifg=#C27872 guibg=#5F8AC2",
"       \ "guifg=#C2AD72 guibg=#7295C2"
"       \ ]
"

" let g:match_throb_colors = get(g:, 'match_throb_colors', g:match_throb_default_colors)


nnoremap <silent> <Plug>(match-throb-throb-sequence) :call match_throb#throb_sequence()<CR>

nnoremap <silent> <Plug>(match-throb-clear-matches) :call match_throb#clear_matches()<CR>


" nnoremap <silent> <Plug>(match-throb-throb-sequence) :call match_throb#throb_sequence(g:match_throb_colors)<CR>



