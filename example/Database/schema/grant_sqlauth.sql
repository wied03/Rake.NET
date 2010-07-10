USE [master]
GO
CREATE LOGIN [$(dbuser)] WITH PASSWORD=N'$(dbpassword)', DEFAULT_DATABASE=[$(dbname)], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
USE [$(dbname)]
GO
CREATE USER [$(dbuser)] FOR LOGIN [$(dbuser)]
GO
USE [$(dbname)]
GO
EXEC sp_addrolemember N'db_owner', N'$(dbuser)'
GO
