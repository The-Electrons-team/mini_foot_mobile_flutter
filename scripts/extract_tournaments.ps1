$content = Get-Content 'lib/team_screen.dart' -Raw

$startMarker = '// ── _TournamentsPage'
$start = $content.IndexOf($startMarker)

if ($start -lt 0) { Write-Host "ERREUR: startMarker non trouve"; exit 1 }

$block = $content.Substring($start).TrimEnd()

# Ajouter au fichier tournois
$existing = Get-Content 'lib/team_tournaments_screen.dart' -Raw
$newContent = $existing.TrimEnd() + "`n`n" + $block
Set-Content 'lib/team_tournaments_screen.dart' -Value $newContent -NoNewline

# Supprimer de team_screen.dart
$before = $content.Substring(0, $start).TrimEnd()
Set-Content 'lib/team_screen.dart' -Value $before -NoNewline

Write-Host "OK: extrait $($block.Length) chars"
