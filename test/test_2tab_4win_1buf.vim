source test/init.vim

silent edit test/file.txt
split
vsplit
wincmd j
vsplit

silent tabnew test/file.txt
split
vsplit
wincmd j
vsplit
