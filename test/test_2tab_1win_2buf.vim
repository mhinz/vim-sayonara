source test/init.vim

silent! edit test/file.txt
silent! edit test/file2.txt
tabnew
silent! edit test/file.txt
silent! edit test/file2.txt
