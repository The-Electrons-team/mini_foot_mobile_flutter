$content = Get-Content 'lib/team_screen.dart' -Raw

$startMarker = '// ── PAGE : EFFECTIF'
$endMarker   = '// ── _MiniPitchPainter'

$start = $content.IndexOf($startMarker)
$end   = $content.IndexOf($endMarker)

if ($start -lt 0) { Write-Host "ERREUR: startMarker non trouve: $startMarker"; exit 1 }
if ($end   -lt 0) { Write-Host "ERREUR: endMarker non trouve: $endMarker"; exit 1 }

$block = $content.Substring($start, $end - $start).TrimEnd()

$header = @"
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'team_screen.dart' show TeamData, TeamMember, MemberStatus, _PlayerPosition;

const Color _kGreen = Color(0xFF006F39);
Color _bg(BuildContext c) => Theme.of(c).scaffoldBackgroundColor;
Color _card(BuildContext c) => Theme.of(c).cardColor;
Color _txt(BuildContext c) => Theme.of(c).colorScheme.onSurface;
Color _sub(BuildContext c) => Theme.of(c).brightness == Brightness.dark
    ? const Color(0xFFF0EBE0).withValues(alpha: 0.5)
    : Colors.black.withValues(alpha: 0.45);
"@

$output = $header + "`n`n" + $block
Set-Content 'lib/team_roster_screen.dart' -Value $output -NoNewline

# Supprimer de team_screen.dart
$before = $content.Substring(0, $start)
$after  = $content.Substring($end)
Set-Content 'lib/team_screen.dart' -Value ($before + $after) -NoNewline

Write-Host "OK: extrait $($block.Length) chars"
