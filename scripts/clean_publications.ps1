$content = Get-Content 'lib/team_screen.dart' -Raw
$start = $content.IndexOf('// ── MODÈLE POST')
$end = $content.IndexOf('// ── _MiniPitchPainter')
if ($start -ge 0 -and $end -ge 0) {
    $before = $content.Substring(0, $start)
    $after = $content.Substring($end)
    $newContent = $before + $after
    Set-Content 'lib/team_screen.dart' -Value $newContent -NoNewline
    Write-Host "OK: supprime $($end - $start) caracteres"
} else {
    Write-Host "ERREUR: start=$start end=$end"
}
