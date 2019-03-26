$connectStrs = 'orlsol00', 'orlpea00'

cd D:\solife-DB\Scripts

foreach ( $connectStr in $connectStrs ) {
  .\DailyChecks.ps1 -connectStr $connectStr -username bip -password Koek1081 > D:\solife-DB\DailyChecks\$connectStr.txt
}