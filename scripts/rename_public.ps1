$c = Get-Content 'lib/team_screen.dart' -Raw
$c = $c -replace 'enum _PlayerPosition', 'enum PlayerPosition'
$c = $c -replace '_PlayerPosition\.', 'PlayerPosition.'
$c = $c -replace 'extension _PlayerPositionLabel on _PlayerPosition', 'extension PlayerPositionLabel on PlayerPosition'
$c = $c -replace 'final _mockPlayers', 'final mockPlayers'
$c = $c -replace '_mockPlayers\.map', 'mockPlayers.map'
$c = $c -replace 'List\.from\(_mockPlayers\)', 'List.from(mockPlayers)'
Set-Content 'lib/team_screen.dart' -Value $c -NoNewline
Write-Host "OK"
