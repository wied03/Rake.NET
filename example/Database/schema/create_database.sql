CREATE DATABASE [$(dbname)] ON  PRIMARY 
( NAME = N'$(dbname)', FILENAME = N'$(sqlserverdatadirectory)\$(dbname).mdf' , SIZE = 2048KB , FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'$(dbname)_log', FILENAME = N'$(sqlserverdatadirectory)\$(dbname)_log.ldf' , SIZE = 1024KB , FILEGROWTH = 10%)
GO
ALTER DATABASE [$(dbname)] SET COMPATIBILITY_LEVEL = 100
GO
ALTER DATABASE [$(dbname)] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [$(dbname)] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [$(dbname)] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [$(dbname)] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [$(dbname)] SET ARITHABORT OFF 
GO
ALTER DATABASE [$(dbname)] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [$(dbname)] SET AUTO_CREATE_STATISTICS ON 
GO
ALTER DATABASE [$(dbname)] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [$(dbname)] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [$(dbname)] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [$(dbname)] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [$(dbname)] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [$(dbname)] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [$(dbname)] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [$(dbname)] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [$(dbname)] SET  DISABLE_BROKER 
GO
ALTER DATABASE [$(dbname)] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [$(dbname)] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [$(dbname)] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [$(dbname)] SET  READ_WRITE 
GO
ALTER DATABASE [$(dbname)] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [$(dbname)] SET  MULTI_USER 
GO
ALTER DATABASE [$(dbname)] SET PAGE_VERIFY CHECKSUM  
GO
USE [$(dbname)]
GO
IF NOT EXISTS (SELECT name FROM sys.filegroups WHERE is_default=1 AND name = N'PRIMARY') ALTER DATABASE [$(dbname)] MODIFY FILEGROUP [PRIMARY] DEFAULT
GO