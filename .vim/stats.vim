" 生成台词统计等信息
" 在编辑 main.md 时运行如下命令：
" :source .vim/stats.vim

let s:class = {}

" Func: s:new 
function! s:new() abort
    let l:obj = copy(s:class)
    let l:obj.curline = 1
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

    while self.curline <= self.maxline
        let l:sLine = getline(self.curline)
        let self.curline += 1
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
    " ## 1 【苏城风情】
    if l:sLine =~# '^\s*##\s*\d\+'
        let l:lsMatch = matchlist(l:sLine, '^\s*##\s*\(\d\+\)\s*【\(.\+\)】')
        if len(l:lsMatch) <= 2
            return v:false
        endif
        let l:number = l:lsMatch[1]
        let l:title = l:lsMatch[2]
        let l:section = {'number': l:number, 'title': l:title}
        " 再向下查找时间地点人物
        let l:place = ''
        let l:time = ''
        let l:roles = ''
        let l:next = 0
        for l:below in range(1, 2)
            let l:sLine = getline(self.curline + l:below)
            if l:sLine !~# '^\s*\*\s*'
                break
            endif
            let l:next = l:below
            let l:sLine = substitute(l:sLine, '^\s*\*\s*', '', '')
            if l:below == 1
                let l:time = l:sLine
            elseif l:below == 2
                let l:place = l:sLine
            elseif l:below == 3
                let l:roles = substitute(l:sLine, '^.*：', '', '')
            endif
        endfor
        let l:section.place = l:place
        let l:section.time = l:time
        let l:section.roles = l:roles
        call add(self.section, l:section)
        let self.curline += l:next
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

" Method: output_title 
function! s:class.output_title() dict abort
    edit title.md
    1,$ delete

    call append(0, '# 分段标题')
    let l:table = ['| 序号 | 标题 | 时间 | 地点 |', '|--|--|--|--|']
    call append(line('$'), l:table)

    for l:section in self.section
        let l:text = printf('| %d | %s | %s | %s |', l:section.number, l:section.title, l:section.time, l:section.place)
        call append(line('$'), l:text)
    endfor
    call append(line('$'), '')
endfunction

" Method: output_roles 
function! s:class.output_roles() dict abort
    vsplit stats.md
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

    let l:table = ['| 人物 | 段数 | 字数 |', '|--|--|--|']
    call append(line('$'), l:table)
    call sort(lsRole, {a, b -> b.char - a.char})
    for l:say in l:lsRole
        let l:text = printf('| %s | %d | %d |', l:say.name, l:say.line, l:say.char)
        call append(line('$'), l:text)
    endfor

    call append(line('$'), '')
    call append(line('$'), '* 台词总段数：' . l:total_line)
    call append(line('$'), '* 台词总字数：' . l:total_char)
    call append(line('$'), '* （行外描述字数：' . self.desc_online)
    call append(line('$'), '* （行内描述）字数：' . self.desc_inline)
    let l:sumAll = l:total_char + self.desc_online + self.desc_inline
    call append(line('$'), '* 正文总字数：' . l:sumAll)
endfunction

" Method: output 
function! s:class.output() dict abort
    call self.output_title()
    call self.output_roles()
endfunction

" Func: s:count_char 
function! s:count_char(text) abort
    let l:lsText = split(a:text, '\zs')
    return len(l:lsText)
endfunction

" Func: s:run 
function! s:run(...) abort
    let l:scaner = s:new()
    if a:0 >= 1
        let l:scaner.curline = a:1
    endif
    if a:0 >= 2
        let l:scaner.maxline = a:2
    endif
    call l:scaner.run()
    call l:scaner.output()
endfunction

call s:run()

" 首次加载后可直接执行命令
" 可选定部分行统计
command! -nargs=* -range=% JubenStats call s:run(<line1>, <line2>)
