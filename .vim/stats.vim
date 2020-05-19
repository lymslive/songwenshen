
let s:class = {}

" Func: s:new 
function! s:new() abort
    let l:obj = copy(s:class)
    let l:obj.curline = 0
    let l:obj.maxline = line('$')
    let l:obj.desc_online = 0
    let l:obj.desc_inline = 0
    let l:obj.roles = {}
    let l:obj.section = []
    return l:obj
endfunction

" Method: run 
function! s:class.run() dict abort
    let l:joinLine = ''

    while self.curline < self.maxline
        let self.curline += 1
        let l:sLine = getline(self.curline)
        if l:sLine =~# '^\s*$'
            if !empty(l:joinLine)
                let l:ok = self.deal_desc(l:joinLine) || self.deal_line(l:joinLine)
            endif
            let l:joinLine = ''
            continue
        elseif l:sLine =~# '^\s*\*\s*'
            let l:joinLine = ''
            continue
        elseif self.deal_title(l:sLine)
            let l:joinLine = ''
            continue
        else
            let l:joinLine .= l:sLine
        endif
    endwhile

endfunction

" Method: deal_title 
function! s:class.deal_title(text) dict abort
    let l:sLine = a:text
    if l:sLine =~# '^\s*##\s*\d\+'
        let l:sTitle = substitute(l:sLine, '^\s*##\s*', '', '')
        call add(self.section, l:sTitle)
        return v:true
    endif
    return v:false
endfunction

" Method: deal_desc 
function! s:class.deal_desc(text) dict abort
    let l:text = a:text
    if l:text =~# '^\s*（'
        let l:iChar = s:count_char(l:text) - 1
        let self.desc_online += l:iChar
        return v:true
    endif
    return v:false
endfunction

" Method: deal_line 
function! s:class.deal_line(text) dict abort
    let l:text = a:text
    if l:text =~# '^\s*\*\s*'
        return v:false
    endif

    " 人名：台词
    let l:lsMatch = split(l:text, '：')
    if len(l:lsMatch) < 2
        return v:false
    endif

    let l:role = l:lsMatch[0]
    let l:line = l:lsMatch[1]
    if !has_key(self.roles, l:role)
        let l:st = {'line': 0, 'char': 0, 'name': l:role}
        let self.roles[l:role] = l:st
    endif

    " （行内描叙）
    let l:iDesc = 0
    while l:line =~# '（.\{-}）'
        let l:desc = matchstr(l:line, '（.\{-}）')
        let l:iDesc += s:count_char(l:desc) - 2
        let l:line = substitute(l:line,'（.\{-}）', '', '') 
    endwhile

    let l:iChar = s:count_char(l:line)

    let self.roles[l:role].line += 1
    let self.roles[l:role].char += l:iChar
    let self.desc_inline += l:iDesc

    return v:true
endfunction

" Method: output 
function! s:class.output() dict abort
    edit title.md
    1,$ delete

    call append(0, '# 分段标题')
    for l:title in self.section
        call append(line('$'), '* ' . l:title)
    endfor
    call append(line('$'), '')

    edit stats.md
    1,$ delete
    call append(0, '# 台词统计')

    let l:total_line = 0
    let l:total_char = 0

    let l:lsRole = []
    for [l:role, l:say] in items(self.roles)
        let l:total_line += l:say.line
        let l:total_char += l:say.char
        call add(l:lsRole, l:say)
    endfor

    let l:table = ['| 人物 | 句数 | 字数 |', '|--|--|--|']
    call append(line('$'), l:table)
    call sort(lsRole, {a, b -> b.char - a.char})
    for l:say in l:lsRole
        let l:text = printf('| %s | %d | %d |', l:say.name, l:say.line, l:say.char)
        call append(line('$'), l:text)
    endfor

    call append(line('$'), '')
    call append(line('$'), '* 台词总段数：' . l:total_line)
    call append(line('$'), '* 台词总字数：' . l:total_char)
    call append(line('$'), '* 行外描述字数：' . self.desc_online)
    call append(line('$'), '* 行内描述字数：' . self.desc_inline)
endfunction

" Func: s:count_char 
function! s:count_char(text) abort
    let l:lsText = split(a:text, '\zs')
    return len(l:lsText)
endfunction

" Func: s:run 
function! s:run() abort
    let l:scaner = s:new()
    call l:scaner.run()
    call l:scaner.output()
endfunction

call s:run()
