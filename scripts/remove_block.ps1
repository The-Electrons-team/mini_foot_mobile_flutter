param($src, $startMarker, $endMarker)

$content = Get-Content $src -Raw

$start = $content.IndexOf($startMarker)
$end   = $content.IndexOf($endMarker)

if ($start -lt 0) { Write-Host "ERREUR: startMarker non trouve"; exit 1 }
if ($end   -lt 0) { Write-Host "ERREUR: endMarker non trouve"; exit 1 }

$before = $content.Substring(0, $start)
$after  = $content.Substring($end)
$newContent = $before + $after
Set-Content $src -Value $newContent -NoNewline
Write-Host "OK: supprime $($end - $start) chars de $src"
