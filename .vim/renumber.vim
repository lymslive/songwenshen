" 重新编号，修改当前 buffer ## 节号
" 在编辑 main.md 时运行如下命令：
" :source .vim/renumber.vim

" 返回最后一个节号
function! s:run() abort
    let l:iSection = -1
    let l:iLast = line('$')
    for l:iLine in range(1, l:iLast)
        let l:sLine = getline(l:iLine)
        if l:sLine =~# '^\s*##\s*\d\+'
            let l:iSection += 1
            let l:sLine = substitute(l:sLine, '\d\+', l:iSection, '')
            call setline(l:iLine, l:sLine)
        endif
    endfor
    return l:iSection
endfunction

call s:run()

" 首次加载后可直接执行命令
command! JubenRenumber call s:run()
