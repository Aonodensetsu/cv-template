$cvvers = @('pdf', 'png')
$langs = @('en')

$combos = foreach ($ver in $cvvers) {
    foreach ($lang in $langs) {
        @{
            CVVER  = $ver
            LANG = $lang
        }
    }
}

New-Item -ItemType Directory -Force -Path .\out
New-Item -ItemType Directory -Force -Path .\aux

$combos | ForEach-Object -ThrottleLimit 8 -Parallel {
    $jobname = "$($_.LANG)-$($_.CVVER)"
    New-Item -ItemType Directory -Force -Path .\aux\$jobname-aux
    New-Item -ItemType Directory -Force -Path .\aux\$jobname-out
    Start-Process -NoNewWindow -Wait -Environment $_ -FilePath lualatex -ArgumentList "-shell-escape", "-file-line-error", "-interaction=nonstopmode", "-synctex=1", "-output-format=pdf", "-aux-directory=`"aux\$jobname-aux`"", "-output-directory=`"aux\$jobname-out`"", "cv.tex"
    if ($_.CVVER -eq "png") {
        pdftoppm -png .\aux\$jobname-out\cv.pdf .\aux\$jobname-out\page
        magick .\aux\$jobname-out\page* -append .\aux\$jobname-out\cv.png
        Copy-Item .\aux\$jobname-out\cv.png ".\out\$($_.LANG).png"
    } else {
        Copy-Item .\aux\$jobname-out\cv.pdf ".\out\$($_.LANG).pdf"
    }
}
