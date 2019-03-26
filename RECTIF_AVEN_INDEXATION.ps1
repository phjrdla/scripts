# To be run on ORLSOL00  ora12prdbak
#
# runs Solife ODS Prod data fixing script RECTIF_AVEN_INDEXATION.sql
# a schema change is done to solife_it0_ods after connecting to clv61prd

D:\SOLIFE-DB\scripts\ExecSqlStmtV3.ps1 -conn orlsol00 -schema clv61prd -pass CLV_61_PRD -stmtfile D:\SOLIFE-DB\scripts\RECTIF_AVEN_INDEXATION.sql -StmtOut c:\temp\RECTIF_AVEN_INDEXATION.out -mode true

GET-content c:\temp\RECTIF_AVEN_INDEXATION.out