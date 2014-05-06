""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"
" Author: Gustavo Yokoyama Ribeiro <gustavoyr+vim AT gmail DOT com>
" File:   python.vim
" Update: 20120213
" (C) Copyright 2010 Gustavo Yokoyama Ribeiro
" Licensed under CreativeCommons Attribution-ShareAlike 3.0 Unsupported
" http://creativecommons.org/licenses/by-sa/3.0/ for more info.
"
""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if &cp
    finish
endif
let s:keep_cpo = &cpo
set cpo&vim
"===============================================================================
" Settings:{{{1

call gyrlib#ProgTextMode()

" Allow make to get syntax errors
" allows us to run :make and get syntax errors for our python scripts
" :cn :cp :cl :cw :cope :ccl
"setlocal makeprg=python\ -c\ \"import\ py_compile,sys;\ sys.stderr=sys.stdout;\ py_compile.compile(r'%')\"
"setlocal efm& efm=%C\ %.%#,%A\ \ File\ \"%f\"\\,\ line\ %l%.%#,%Z%[%^\ ]%\\@=%m
"setlocal makeprg=pep8\ %:p
"setlocal errorformat=%f:%l:%c:%m
"setlocal makeprg=pyflakes\ %:p
"setlocal errorformat=%f:%l:%m
set makeprg=pylint\ --reports=n\ --output-format=parseable\ %:p
set errorformat=%f:%l:\ [%t%n%m

setlocal foldmethod& foldmethod=indent
" Indentation sets
"setlocal omnifunc& omnifunc=pythoncomplete#Complete
setlocal smartindent
setlocal cinwords& cinwords=if,elif,else,for,while,try,except,finally,def,class

" make python follow PEP8 ( http://www.python.org/dev/peps/pep-0008/ )
" Indents are 4 spaces
setlocal shiftwidth=4
setlocal tabstop=4
setlocal softtabstop=4
" And they really are spaces, *not* tabs
setlocal expandtab
setlocal textwidth=79
" already set in ftplugin (python.py)
"    autocmd BufRead *.py set makeprg=python\ -c\ \"import\ py_compile,sys;\ sys.stderr=sys.stdout;\ py_compile.compile(r'%')\"
"    autocmd FileType python set omnifunc=pythoncomplete#Complete
"    autocmd BufRead *.py set efm=%C\ %.%#,%A\ \ File\ \"%f\"\\,\ line\ %l%.%#,%Z%[%^\ ]%\\@=%m

" include python tags
"setlocal tags&
"setlocal tags+=~/.vim-tmp/tags/python26tags
setlocal tags+=~/.vim-tmp/tags/python27tags
"setlocal tags+=~/.vim-tmp/tags/python3tags
" regenerate tags
"call system("ctags -R -f ~/.vim-tmp/tags/python26.tags /usr/lib/python2.6")
"call system("ctags -R -f ~/.vim-tmp/tags/python27.tags /usr/lib/python2.7")
"call system("ctags -R -f ~/.vim-tmp/tags/python3.tags /usr/lib/python3")

let b:syntastic_checkers = ['python', 'pep8', 'pyflakes']
let b:syntastic_quiet_messages = { "regex": ['E501 line too long',], }

" }}}1
"===============================================================================
" Tag Path:{{{1

"}}}1
"===============================================================================
" Mapping:{{{1
"noremap <buffer><Leader>e :py EvaluateCurrentRange()<CR>
noremap <buffer><Leader>mx :call gyrlib#MakeExecutable()<CR>
"noremap <buffer><Leader>s :!pyflakes %<CR>
noremap <buffer><Leader>f :call <SID>PythonFormatChecker()<CR>
"noremap <buffer><Leader>s :call <SID>PythonSyntaxChecker()<CR>

" }}}1
"===============================================================================
" Abbreviation:{{{1
iab <buffer> py,, #!/usr/bin/python<C-R>=gyrlib#EatChar('\s')<CR>
iab <buffer> sb,, #!/usr/bin/env python<C-R>=gyrlib#EatChar('\s')<CR>
iab <buffer> fh,, <C-R>=gyrlib#AddFh('#', 'short')<CR><C-R>=gyrlib#EatChar('\s')<CR>
cab <buffer> ctags,, !ctags -R -f ~/.vim-tmp/tags/python.ctags /usr/lib/python2.5/

" }}}1
"===============================================================================

let &cpo = s:keep_cpo
unlet s:keep_cpo

if exists('s:load_python')
    finish
endif
let s:load_python = 1

"===============================================================================
" Function:{{{1
"-------------------------------------------------------------------------------
" Format checker (PEP8):{{{2
function! s:PythonFormatChecker()
    setlocal makeprg=pep8\ %:p
    setlocal errorformat=%f:%l:%c:%m
    make
    cwindow
endfunction

"}}}2
"-------------------------------------------------------------------------------
" Syntax checker (pyflakes):{{{2
function! s:PythonSyntaxChecker()
    setlocal makeprg=pyflakes\ %:p
    setlocal errorformat=%f:%l:%m
    make
    cwindow
endfunction

"}}}2
"-------------------------------------------------------------------------------
" Add breakpoint:{{{2
python << EOF
import vim
import re

def SetBreakpoint():
    nLine = int( vim.eval( 'line(".")'))

    strLine = vim.current.line
    strWhite = re.search( '^(\s*)', strLine).group(1)

    vim.current.script.append(
        "%(space)spdb.set_trace() %(mark)s Breakpoint %(mark)s" %
            {'space':strWhite, 'mark': '#' * 30}, nLine - 1)

    for strLine in vim.current.script:
        if strLine == "import pdb":
            break
    else:
        vim.current.script.append( 'import pdb', 0)
        vim.command( 'normal! j1')

vim.command( 'noremap <script><Leader>sb :py SetBreakpoint()<cr>')

def RemoveBreakpoints():
    nCurrentLine = int( vim.eval( 'line(".")'))

    nLines = []
    nLine = 1
    for strLine in vim.current.script:
        if strLine == 'import pdb' or strLine.lstrip()[:15] == 'pdb.set_trace()':
            nLines.append( nLine)
        nLine += 1

    nLines.reverse()

    for nLine in nLines:
        vim.command( 'normal! %dG' % nLine)
        vim.command( 'normal! dd')
        if nLine < nCurrentLine:
            nCurrentLine -= 1

    vim.command( 'normal! %dG' % nCurrentLine)

vim.command( 'noremap <script><Leader>db :py RemoveBreakpoints()<cr>')
EOF

"}}}2
"-------------------------------------------------------------------------------
" Add libs to vim path:{{{2
python << EOF
import os
import sys
import vim
for p in sys.path:
    if os.path.isdir(p):
        vim.command(r"setlocal path+=%s" % (p.replace(" ",r"\ ")))
EOF

"}}}2
"-------------------------------------------------------------------------------
" Evaluate selected text via python:{{{2
python << EOL
import vim
def EvaluateCurrentRange():
    eval(compile('\n'.join(vim.current.range),'','exec'),globals())
EOL

"}}}2
"-------------------------------------------------------------------------------
"}}}1
"===============================================================================

" vim: set filetype=vim fileformat=unix foldmethod=marker :
