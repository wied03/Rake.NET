:On Error ignore
USE [$(dbname)]
GO
DROP USER [$(dbuser)]
GO
USE [master]
GO
DROP LOGIN [$(dbuser)]
GO
:On Error exit
