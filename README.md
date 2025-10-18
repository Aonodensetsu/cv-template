# CV/Resume template

[![ko-fi](https://img.shields.io/badge/show-support-555599?style=for-the-badge&logo=kofi)](https://ko-fi.com/aonodensetsu)

### Preview

The repository contains an [example pdf](example.pdf), which also serves as an instruction manual.

A Windows [compile script](compile.ps1) is provided, which will speed up generating the PDF (parallelized).

### Setup

1. Ensure you have `git` installed.
2. `git clone` this repository.
3. `git submodule update --init --recursive` since this repository uses another.
4. Ensure your LaTeX distribution includes LuaLaTeX.

   <details>
   <summary>LaTeX Packages</summary>

   - luacode
   - luapackageloader
   - lua-tinyyaml
   - bookmark
   - calc
   - xcolor
   - fontspec
   - parskip
   - paracol
   - tabularx
   - graphicx
   - hyperref
   - progressbar
   - tikz
   - tikz library: fadings
   </details>
5. Ensure `imagemagick` is available to lua under the name `magick`.
6. Ensure the FontAwesome Pro fonts are installed in the system (`C:\Windows\Fonts`, not the user path).  
   I am using version `5.15.4`. Type in the font file names in [the lua file](cv.lua#L110) if they are different in your system than mine.
7. Ensure the Source Code Pro font is installed in the system. Adjust [the tex file](cv.tex#L53) if the file name is different on your system.
8. You need to run LuaLaTeX with `-shell-escape`.