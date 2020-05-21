" 对剧本格式进行语法着色
" :source .vim/syntax.vim

" （行外描述
" syntax match Comment /^\s*（\_.\{-}\ze\n\n/
" syntax match Comment /^\s*（./

" （行内描述）
" syntax match Special /（\_.\{-}）/

syntax region Comment  start="（"  end="）\|\n\n"

" 人物：台词
syntax match Macro /^[^*]\{-}：/

