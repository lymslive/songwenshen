" �Ծ籾��ʽ�����﷨��ɫ
" :source .vim/syntax.vim

" ����������
" syntax match Comment /^\s*��\_.\{-}\ze\n\n/
" syntax match Comment /^\s*��./

" ������������
" syntax match Special /��\_.\{-}��/

syntax region Comment  start="��"  end="��\|\n\n"

" ���̨��
syntax match Macro /^[^*]\{-}��/

