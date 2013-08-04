" Vim indent file
" Language: Javascript
" Acknowledgement: Based off of vim-ruby maintained by Nikolai Weibull http://vim-ruby.rubyforge.org

" 0. Initialization {{{1
" =================

" Only load this indent file when no other was loaded.
if exists("b:did_indent")
  finish
endif
let b:did_indent = 1

setlocal nosmartindent

" Now, set up our indentation expression and keys that trigger it.
setlocal indentexpr=GetJavascriptIndent()
setlocal indentkeys=0{,0},0),0],0\,,!^F,o,O,e

" Only define the function once.
if exists("*GetJavascriptIndent")
  finish
endif

let s:cpo_save = &cpo
set cpo&vim

" 1. Variables {{{1
" ============

let s:line_term = '\s*\%(\%(\/\/\).*\)\=$'
let s:one_line_scope_regex = '\<\%(if\|else\|for\|while\)\>[^{;]*' . s:line_term

let s:comma_first = '^\s*,'
let s:comma_last = ',\s*$'

let s:ternary = '^\s\+[?|:]'
let s:ternary_q = '^\s\+?'

let s:multi_assign = '\s\+=\s\+\(.*\),$'

" 2. Auxiliary Functions {{{1
" ======================

" Find line above 'lnum' that isn't empty, in a comment, or in a string.
function s:PrevNonBlankNonString(lnum)
  let in_block = 0
  let lnum = prevnonblank(a:lnum)
  while lnum > 0
    " Go in and out of blocks comments as necessary.
    " If the line isn't empty (with opt. comment) or in a string, end search.
    let line = getline(lnum)
    if line =~ '/\*'
      if in_block
        let in_block = 0
      else
        break
      endif
    elseif !in_block && line =~ '\*/'
      let in_block = 1
    elseif !in_block && line !~ '^\s*\%(//\).*$' && !(s:IsInStringOrComment(lnum, 1) && s:IsInStringOrComment(lnum, strlen(line)))
      break
    endif
    let lnum = prevnonblank(lnum - 1)
  endwhile
  return lnum
endfunction

function s:findMatching(lnum, end_type)
  let lnum = prevnonblank(a:lnum - 1)
  let s:count = 0

  if a:end_type == '}'
    let s:start_type = '{'
  elseif a:end_type == ')'
    let s:start_type = '('
  else
    let s:start_type = '['
  endif

  while lnum > 0
    let line = getline(lnum)

    let s:matched_block_end = matchlist(line, s:block_end)[2]
    let s:matched_block_start = matchlist(line, s:block_start)[0]

    if line =~ s:block_start && s:matched_block_start == s:start_type
      if s:count == 0
        return lnum
      elseif line !~ s:block_end
        let s:count = s:count - 1
      endif
    elseif line =~ s:block_end && s:matched_block_end == a:end_type
      let s:count = s:count + 1
    endif

    let lnum = prevnonblank(lnum - 1)
  endwhile
  return a:lnum
endfunction

" 3. GetJavascriptIndent Function {{{1
" =========================

let s:block_start = '\([{(\[]\)\(\s\+\)\?$'
let s:block_end = '^\(\s\+\)\?\([})\]]\)'

let s:dedent = 0

function GetJavascriptIndent()
  let vcol = col('.')
  let ind = -1
  let line = getline(v:lnum)
  let prevnum = prevnonblank(v:lnum - 1)
  let prevline = getline(prevnum)

  " handles dedent when set and doesn't interfere with multiple assignments
  if (s:dedent == 1)
    if (prevline =~ s:comma_last)
      return indent(v:lnum)
    endif
    let s:dedent = 0
    return indent(prevnum) - &sw
  endif

  " if you're in the process of a multi-assign, indent one level.
  if (prevline =~ s:comma_last && indent(v:lnum) != indent(prevnum))
    let s:dedent = 1
    return indent(prevnum) + &sw
  endif

" XXX fix, make sure that it is truly a one liner. can't have brace
"  if (prevline =~ s:one_line_scope_regex)
"    let s:dedent = 1
"    return indent(prevnum) + &sw
"  endif

  " indent one level if there's an open parentheses, brace, or bracket.
  if (prevline =~ s:block_start)
    let ind = indent(prevnum) + &sw
  endif

" XXX if there is a multiline expression find the brace position, and then
" find the indent level of where the multiline expression starts. to do this
" check for open parens?

  " Find matching parentheses, brace, or bracket and indent to that level
  if (line =~ s:block_end)
    let end_type = matchlist(line, s:block_end)[2]
    let ind = indent(s:findMatching(v:lnum, end_type))
  endif

  " use previous line indentation as a guide unless ind is specified.
  if ind > -1
    return ind
  else
    return indent(prevnum)
  endif
endfunction

" }}}1

let &cpo = s:cpo_save
unlet s:cpo_save
