:On Error ignore
ALTER DATABASE [$(dbname)] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = N'$(dbname)'
GO
DROP DATABASE [$(dbname)]
GO
:On Error exit
