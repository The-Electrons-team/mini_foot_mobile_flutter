$content = Get-Content 'lib/team_screen.dart' -Raw

$startMarker = '// ── PAGE : COMPOSITIONS'

$start = $content.IndexOf($startMarker)
if ($start -lt 0) { Write-Host "ERREUR: startMarker non trouve"; exit 1 }

$block = $content.Substring($start).TrimEnd()

$header = @"
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'team_screen.dart' show TeamData, TeamMember, MemberStatus, _PlayerPosition, _mockPlayers;

const Color _kGreen = Color(0xFF006F39);
Color _bg(BuildContext c) => Theme.of(c).scaffoldBackgroundColor;
Color _card(BuildContext c) => Theme.of(c).cardColor;
Color _txt(BuildContext c) => Theme.of(c).colorScheme.onSurface;
Color _sub(BuildContext c) => Theme.of(c).brightness == Brightness.dark
    ? const Color(0xFFF0EBE0).withValues(alpha: 0.5)
    : Colors.black.withValues(alpha: 0.45);
"@

$output = $header + "`n`n" + $block
Set-Content 'lib/team_composition_screen.dart' -Value $output -NoNewline

# Supprimer de team_screen.dart
$before = $content.Substring(0, $start).TrimEnd()
Set-Content 'lib/team_screen.dart' -Value $before -NoNewline

Write-Host "OK: extrait $($block.Length) chars"
