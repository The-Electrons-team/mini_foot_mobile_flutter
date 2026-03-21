# Fix team_composition_screen.dart
$c = Get-Content 'lib/team_composition_screen.dart' -Raw
$c = $c -replace "import 'team_screen.dart' show TeamData, TeamMember, MemberStatus, _PlayerPosition, _mockPlayers;", "import 'team_screen.dart' show TeamData, TeamMember, MemberStatus, PlayerPosition, PlayerPositionLabel, mockPlayers;"
$c = $c -replace '_PlayerPosition\.', 'PlayerPosition.'
$c = $c -replace '_PlayerPosition\b', 'PlayerPosition'
$c = $c -replace '\b_mockPlayers\b', 'mockPlayers'
$c = $c -replace 'List\.from\(_mockPlayers\)', 'List.from(mockPlayers)'
Set-Content 'lib/team_composition_screen.dart' -Value $c -NoNewline
Write-Host "composition OK"

# Fix team_roster_screen.dart
$c = Get-Content 'lib/team_roster_screen.dart' -Raw
$c = $c -replace "import 'team_screen.dart' show TeamData, TeamMember, MemberStatus, _PlayerPosition;", "import 'team_screen.dart' show TeamData, TeamMember, MemberStatus, PlayerPosition, PlayerPositionLabel;"
$c = $c -replace '_PlayerPosition\.', 'PlayerPosition.'
$c = $c -replace '_PlayerPosition\b', 'PlayerPosition'
Set-Content 'lib/team_roster_screen.dart' -Value $c -NoNewline
Write-Host "roster OK"
