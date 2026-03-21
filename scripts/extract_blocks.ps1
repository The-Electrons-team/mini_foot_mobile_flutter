param($src, $startMarker, $endMarker, $dest, $header)

$content = Get-Content $src -Raw

$start = $content.IndexOf($startMarker)
$end   = $content.IndexOf($endMarker)

if ($start -lt 0) { Write-Host "ERREUR: startMarker non trouve: $startMarker"; exit 1 }
if ($end   -lt 0) { Write-Host "ERREUR: endMarker non trouve: $endMarker"; exit 1 }

$block = $content.Substring($start, $end - $start).TrimEnd()
$output = $header + "`n`n" + $block
Set-Content $dest -Value $output -NoNewline
Write-Host "OK: extrait $($block.Length) chars -> $dest"
