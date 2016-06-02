USE [master]
GO
/****** Object:  Database [Astro]    Script Date: 2016-06-02 21:57:49 ******/
CREATE DATABASE [Astro]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'Astro', FILENAME = N'c:\Program Files\Microsoft SQL Server\MSSQL11.SQLEXPRESS\MSSQL\DATA\Astro.mdf' , SIZE = 1024000KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'Astro_log', FILENAME = N'c:\Program Files\Microsoft SQL Server\MSSQL11.SQLEXPRESS\MSSQL\DATA\Astro_log.ldf' , SIZE = 10240KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO
ALTER DATABASE [Astro] SET COMPATIBILITY_LEVEL = 110
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [Astro].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [Astro] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [Astro] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [Astro] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [Astro] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [Astro] SET ARITHABORT OFF 
GO
ALTER DATABASE [Astro] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [Astro] SET AUTO_CREATE_STATISTICS ON 
GO
ALTER DATABASE [Astro] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [Astro] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [Astro] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [Astro] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [Astro] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [Astro] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [Astro] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [Astro] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [Astro] SET  DISABLE_BROKER 
GO
ALTER DATABASE [Astro] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [Astro] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [Astro] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [Astro] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [Astro] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [Astro] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [Astro] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [Astro] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [Astro] SET  MULTI_USER 
GO
ALTER DATABASE [Astro] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [Astro] SET DB_CHAINING OFF 
GO
ALTER DATABASE [Astro] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [Astro] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
USE [Astro]
GO
/****** Object:  StoredProcedure [dbo].[insertTestData]    Script Date: 2016-06-02 21:57:49 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[insertTestData]
  
   @observationId varchar(50) = NULL,
   @active bit = 1,
   @status varchar(20) = 'new', 
   @starName varchar(50) = NULL,
   @startDate varchar(50) = NULL,
   @endDate varchar(50) = NULL 

  
AS
BEGIN

   SET NOCOUNT ON;

--simple cursor in sql server
Declare @uPhotometryTime varchar(50), @uPhotometry varchar(50), @vPhotometryTime varchar(50), @vPhotometry varchar(50), @bPhotometryTime varchar(50), @bPhotometry varchar(50)
Declare @rowId int = 1
-- declare a cursor
DECLARE insert_cursor CURSOR FOR
SELECT [Column 0], [Column 1], [Column 2], [Column 3], [Column 4], [Column 5] from [dbo].[TestData]

-- open cursor and fetch first row into variables
OPEN insert_cursor
FETCH NEXT FROM insert_cursor into @uPhotometryTime,@uPhotometry,@vPhotometryTime,@vPhotometry,@bPhotometryTime,@bPhotometry

-- check for a new row
WHILE @@FETCH_STATUS=0
BEGIN
-- do complex operation here
Insert into dbo.stagingObservations (id, RowId, StarName, StartDate, EndDate, uPhotometry, uPhotometryTime, vPhotometry, vPhotometryTime, bPhotometry, bPhotometryTime, Status, Active)
SELECT @observationId, @rowId, @starName, @startDate, @endDate, @uPhotometry, @uPhotometryTime, @vPhotometry, @vPhotometryTime, @bPhotometry, @bPhotometryTime, @status, @active
-- get next available row into variables
FETCH NEXT FROM insert_cursor into @uPhotometryTime, @uPhotometry, @vPhotometryTime, @vPhotometry, @bPhotometryTime, @bPhotometry
set @rowId=@rowId+1
END
close insert_cursor
Deallocate insert_cursor


END
GO
/****** Object:  StoredProcedure [dbo].[observationsDelta]    Script Date: 2016-06-02 21:57:49 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[observationsDelta]
  
   @observationId varchar(50) = NULL
  
AS
BEGIN

   SET NOCOUNT ON;


--set id
Declare @i int
Declare @query nvarchar(max)
Declare @deltaColumn varchar(50)
Declare @stagingColumn varchar(50)
Declare @photometryTable varchar (100)
Declare @deltaColumnId nvarchar(max)


--uPhotometry table
 set @deltaColumn = (select DeltaColumnId from dbo.metadataComparison where id=1)
 set @photometryTable = (select PhotometryTable from dbo.metadataComparison where id=1)
 set @query = ('select top 1 @deltaColumnId='+@deltaColumn +' from '+@photometryTable+' alias order by '+ @deltaColumn +' desc')
 
 print @query
 
 exec sp_executesql @query, @Params = N'@deltaColumnId varchar(50) output', @deltaColumnId = @deltaColumnId output
 
 if ((@deltaColumnId) = null)
   begin
   set @i = 1
   end
 else
   begin
   set @i = (@deltaColumnId) + 1
   end


 Declare @uPhotometry varchar(50)
 DECLARE insert_cursor CURSOR FOR (select uPhotometry from dbo.stagingObservations where Active=1 except select uPhotometry from dbo.uPhotometry)

 OPEN insert_cursor
 FETCH NEXT FROM insert_cursor into @uPhotometry

 WHILE @@FETCH_STATUS=0
   BEGIN
   Insert into dbo.uPhotometry (uPhotometryId, uPhotometry) SELECT @i, @uPhotometry
   FETCH NEXT FROM insert_cursor into @uPhotometry
   set @i=@i+1
   END
 close insert_cursor
 Deallocate insert_cursor
 

--vPhotometry table

 set @deltaColumn = (select DeltaColumnId from dbo.metadataComparison where id=2)
 set @photometryTable = (select PhotometryTable from dbo.metadataComparison where id=2)
 set @query = ('select top 1 @deltaColumnId='+@deltaColumn +' from '+@photometryTable+' alias order by '+ @deltaColumn +' desc')
 
 print @query
 
 exec sp_executesql @query, @Params = N'@deltaColumnId varchar(50) output', @deltaColumnId = @deltaColumnId output
 
 if ((@deltaColumnId) = null)
   begin
   set @i = 1
   end
 else
   begin
   set @i = (@deltaColumnId) + 1
   end


 Declare @vPhotometry varchar(50)
 DECLARE insert_cursor CURSOR FOR (select vPhotometry from dbo.stagingObservations where Active=1 except select vPhotometry from dbo.vPhotometry)

 OPEN insert_cursor
 FETCH NEXT FROM insert_cursor into @vPhotometry

 WHILE @@FETCH_STATUS=0
   BEGIN
   Insert into dbo.vPhotometry (vPhotometryId, vPhotometry) SELECT @i, @vPhotometry
   FETCH NEXT FROM insert_cursor into @vPhotometry
   set @i=@i+1
   END
 close insert_cursor
 Deallocate insert_cursor



 --bPhotometry table

 set @deltaColumn = (select DeltaColumnId from dbo.metadataComparison where id=3)
 set @photometryTable = (select PhotometryTable from dbo.metadataComparison where id=3)
 set @query = ('select top 1 @deltaColumnId='+@deltaColumn +' from '+@photometryTable+' alias order by '+ @deltaColumn +' desc')
 
 print @query
 
 exec sp_executesql @query, @Params = N'@deltaColumnId varchar(50) output', @deltaColumnId = @deltaColumnId output
 
 if ((@deltaColumnId) = null)
   begin
   set @i = 1
   end
 else
   begin
   set @i = (@deltaColumnId) + 1
   end


 Declare @bPhotometry varchar(50)
 DECLARE insert_cursor CURSOR FOR (select bPhotometry from dbo.stagingObservations where Active=1 except select bPhotometry from dbo.bPhotometry)

 OPEN insert_cursor
 FETCH NEXT FROM insert_cursor into @bPhotometry

 WHILE @@FETCH_STATUS=0
   BEGIN
   Insert into dbo.bPhotometry (bPhotometryId, bPhotometry) SELECT @i, @bPhotometry
   FETCH NEXT FROM insert_cursor into @bPhotometry
   set @i=@i+1
   END
 close insert_cursor
 Deallocate insert_cursor


 
--uPhotometryTime table


 set @deltaColumn = (select DeltaColumnId from dbo.metadataComparison where id=4)
 set @photometryTable = (select PhotometryTable from dbo.metadataComparison where id=4)
 set @query = ('select top 1 @deltaColumnId='+@deltaColumn +' from '+@photometryTable+' alias order by '+ @deltaColumn +' desc')
 
 print @query
 
 exec sp_executesql @query, @Params = N'@deltaColumnId varchar(50) output', @deltaColumnId = @deltaColumnId output
 
 if ((@deltaColumnId) = null)
   begin
   set @i = 1
   end
 else
   begin
   set @i = (@deltaColumnId) + 1
   end


 Declare @uPhotometryTime varchar(50)
 DECLARE insert_cursor CURSOR FOR (select uPhotometryTime from dbo.stagingObservations where Active=1 except select uPhotometryTime from dbo.uPhotometryTime)

 OPEN insert_cursor
 FETCH NEXT FROM insert_cursor into @uPhotometryTime

 WHILE @@FETCH_STATUS=0
   BEGIN
   Insert into dbo.uPhotometryTime (uPhotometryTimeId, uPhotometryTime) SELECT @i, @uPhotometryTime
   FETCH NEXT FROM insert_cursor into @uPhotometryTime
   set @i=@i+1
   END
 close insert_cursor
 Deallocate insert_cursor


 --vPhotometryTime table

 set @deltaColumn = (select DeltaColumnId from dbo.metadataComparison where id=5)
 set @photometryTable = (select PhotometryTable from dbo.metadataComparison where id=5)
 set @query = ('select top 1 @deltaColumnId='+@deltaColumn +' from '+@photometryTable+' alias order by '+ @deltaColumn +' desc')
 
 print @query
 
 exec sp_executesql @query, @Params = N'@deltaColumnId varchar(50) output', @deltaColumnId = @deltaColumnId output
 
 if ((@deltaColumnId) = null)
   begin
   set @i = 1
   end
 else
   begin
   set @i = (@deltaColumnId) + 1
   end


 Declare @vPhotometryTime varchar(50)
 DECLARE insert_cursor CURSOR FOR (select vPhotometryTime from dbo.stagingObservations where Active=1 except select vPhotometryTime from dbo.vPhotometryTime)

 OPEN insert_cursor
 FETCH NEXT FROM insert_cursor into @vPhotometryTime

 WHILE @@FETCH_STATUS=0
   BEGIN
   Insert into dbo.vPhotometryTime (vPhotometryTimeId, vPhotometryTime) SELECT @i, @vPhotometryTime
   FETCH NEXT FROM insert_cursor into @vPhotometryTime
   set @i=@i+1
   END
 close insert_cursor
 Deallocate insert_cursor



 --bPhotometryTime table

 set @deltaColumn = (select DeltaColumnId from dbo.metadataComparison where id=6)
 set @photometryTable = (select PhotometryTable from dbo.metadataComparison where id=6)
 set @query = ('select top 1 @deltaColumnId='+@deltaColumn +' from '+@photometryTable+' alias order by '+ @deltaColumn +' desc')
 
 print @query
 
 exec sp_executesql @query, @Params = N'@deltaColumnId varchar(50) output', @deltaColumnId = @deltaColumnId output
 
 if ((@deltaColumnId) = null)
   begin
   set @i = 1
   end
 else
   begin
   set @i = (@deltaColumnId) + 1
   end


 Declare @bPhotometryTime varchar(50)
 DECLARE insert_cursor CURSOR FOR (select bPhotometryTime from dbo.stagingObservations where Active=1 except select bPhotometryTime from dbo.bPhotometryTime)

 OPEN insert_cursor
 FETCH NEXT FROM insert_cursor into @bPhotometryTime

 WHILE @@FETCH_STATUS=0
   BEGIN
   Insert into dbo.bPhotometryTime (bPhotometryTimeId, bPhotometryTime) SELECT @i, @bPhotometryTime
   FETCH NEXT FROM insert_cursor into @bPhotometryTime
   set @i=@i+1
   END
 close insert_cursor
 Deallocate insert_cursor



insert into dbo.observations select so.id, so.RowId, so.StarName, so.StartDate, so.EndDate, uph.uPhotometryId, upht.uPhotometryTimeId,
                                     vph.vPhotometryId, vpht.vPhotometryTimeId, bph.bPhotometryId, bpht.bPhotometryTimeId
from dbo.stagingObservations so
                               join dbo.uPhotometry uph on uph.uPhotometry=so.uPhotometry
                               join dbo.vPhotometry vph on vph.vPhotometry=so.vPhotometry
                               join dbo.bPhotometry bph on bph.bPhotometry=so.bPhotometry
                               join dbo.uPhotometryTime upht on upht.uPhotometryTime=so.uPhotometryTime
                               join dbo.vPhotometryTime vpht on vpht.vPhotometryTime=so.vPhotometryTime
                               join dbo.bPhotometryTime bpht on bpht.bPhotometryTime=so.bPhotometryTime
                               where id=@observationId and status='new' and active=1



delete tob from dbo.observations tob
inner join dbo.stagingObservations tso on tso.RowId=tob.RowId
where tso.id=@observationId and status='old' and active=0


update dbo.stagingObservations set status='old'

select * from dbo.stagingObservations

select * from dbo.observations

END
GO
/****** Object:  Table [dbo].[bPhotometry]    Script Date: 2016-06-02 21:57:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[bPhotometry](
	[bPhotometryId] [bigint] NOT NULL,
	[bPhotometry] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[bPhotometryId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[bPhotometryTime]    Script Date: 2016-06-02 21:57:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[bPhotometryTime](
	[bPhotometryTimeId] [bigint] NOT NULL,
	[bPhotometryTime] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[bPhotometryTimeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[log]    Script Date: 2016-06-02 21:57:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[log](
	[ID] [int] NOT NULL,
	[ProcName] [varchar](50) NULL,
	[StartDate] [datetime] NULL,
	[EndDate] [datetime] NULL,
	[Message] [varchar](1) NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[metadataComparison]    Script Date: 2016-06-02 21:57:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[metadataComparison](
	[ID] [int] NOT NULL,
	[MetadataCountsId] [int] NOT NULL,
	[StagingColumn] [varchar](50) NULL,
	[DeltaColumn] [varchar](50) NULL,
	[DeltaColumnId] [varchar](50) NULL,
	[PhotometryTable] [varchar](50) NULL,
	[DataTypeConversion] [varchar](1000) NULL,
	[NullValuesConversion] [varchar](100) NULL,
	[JoinHint] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[metadataCounts]    Script Date: 2016-06-02 21:57:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[metadataCounts](
	[ID] [int] NOT NULL,
	[StagingTable] [varchar](50) NULL,
	[DeltaTable] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[observations]    Script Date: 2016-06-02 21:57:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[observations](
	[ID] [int] NOT NULL,
	[RowId] [bigint] NULL,
	[StarName] [varchar](50) NULL,
	[StartDate] [datetime] NULL,
	[EndDate] [datetime] NULL,
	[uPhotometryId] [bigint] NULL,
	[uPhotometryTimeId] [bigint] NULL,
	[vPhotometryId] [bigint] NULL,
	[vPhotometryTimeId] [bigint] NULL,
	[bPhotometryId] [bigint] NULL,
	[bPhotometryTimeId] [bigint] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[stagingObservations]    Script Date: 2016-06-02 21:57:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[stagingObservations](
	[ID] [bigint] NULL,
	[RowId] [bigint] NOT NULL,
	[StarName] [varchar](50) NULL,
	[StartDate] [varchar](50) NULL,
	[EndDate] [varchar](50) NULL,
	[uPhotometry] [varchar](50) NULL,
	[uPhotometryTime] [varchar](50) NULL,
	[vPhotometry] [varchar](50) NULL,
	[vPhotometryTime] [varchar](50) NULL,
	[bPhotometry] [varchar](50) NULL,
	[bPhotometryTime] [varchar](50) NULL,
	[Status] [varchar](50) NULL,
	[Active] [bit] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TestData]    Script Date: 2016-06-02 21:57:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TestData](
	[Column 0] [varchar](50) NULL,
	[Column 1] [varchar](50) NULL,
	[Column 2] [varchar](50) NULL,
	[Column 3] [varchar](50) NULL,
	[Column 4] [varchar](50) NULL,
	[Column 5] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[uPhotometry]    Script Date: 2016-06-02 21:57:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[uPhotometry](
	[uPhotometryId] [bigint] NOT NULL,
	[uPhotometry] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[uPhotometryId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[uPhotometryTime]    Script Date: 2016-06-02 21:57:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[uPhotometryTime](
	[uPhotometryTimeId] [bigint] NOT NULL,
	[uPhotometryTime] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[uPhotometryTimeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[vPhotometry]    Script Date: 2016-06-02 21:57:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[vPhotometry](
	[vPhotometryId] [bigint] NOT NULL,
	[vPhotometry] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[vPhotometryId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[vPhotometryTime]    Script Date: 2016-06-02 21:57:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[vPhotometryTime](
	[vPhotometryTimeId] [bigint] NOT NULL,
	[vPhotometryTime] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[vPhotometryTimeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  View [dbo].[bPhotometrySorted]    Script Date: 2016-06-02 21:57:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[bPhotometrySorted] as
SELECT        TOP (100) PERCENT dbo.observations.ID, dbo.observations.RowId, dbo.observations.StarName, dbo.observations.StartDate, dbo.observations.EndDate, dbo.bPhotometry.bPhotometry, 
                         dbo.bPhotometryTime.bPhotometryTime
FROM            dbo.bPhotometry INNER JOIN
                         dbo.observations ON dbo.bPhotometry.bPhotometryId = dbo.observations.bPhotometryId INNER JOIN
                         dbo.bPhotometryTime ON dbo.observations.bPhotometryTimeId = dbo.bPhotometryTime.bPhotometryTimeId
ORDER BY dbo.observations.ID, dbo.observations.RowId, dbo.observations.StartDate

GO
/****** Object:  View [dbo].[observationsSorted]    Script Date: 2016-06-02 21:57:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[observationsSorted] as (
SELECT        TOP (100) PERCENT ID, RowId, StarName, StartDate, EndDate
FROM            dbo.observations
ORDER BY ID, RowId, StartDate)

GO
/****** Object:  View [dbo].[uPhotometrySorted]    Script Date: 2016-06-02 21:57:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[uPhotometrySorted] as
SELECT        TOP (100) PERCENT dbo.observations.ID, dbo.observations.RowId, dbo.observations.StarName, dbo.observations.StartDate, dbo.observations.EndDate, dbo.uPhotometry.uPhotometry, 
                         dbo.uPhotometryTime.uPhotometryTime
FROM            dbo.uPhotometry INNER JOIN
                         dbo.observations ON dbo.uPhotometry.uPhotometryId = dbo.observations.uPhotometryId INNER JOIN
                         dbo.uPhotometryTime ON dbo.observations.uPhotometryTimeId = dbo.uPhotometryTime.uPhotometryTimeId
ORDER BY dbo.observations.ID, dbo.observations.RowId, dbo.observations.StartDate

GO
/****** Object:  View [dbo].[vPhotometrySorted]    Script Date: 2016-06-02 21:57:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[vPhotometrySorted] as
SELECT        TOP (100) PERCENT dbo.observations.ID, dbo.observations.RowId, dbo.observations.StarName, dbo.observations.StartDate, dbo.observations.EndDate, dbo.vPhotometry.vPhotometry, 
                         dbo.vPhotometryTime.vPhotometryTime
FROM            dbo.vPhotometry INNER JOIN
                         dbo.observations ON dbo.vPhotometry.vPhotometryId = dbo.observations.vPhotometryId INNER JOIN
                         dbo.vPhotometryTime ON dbo.observations.vPhotometryTimeId = dbo.vPhotometryTime.vPhotometryTimeId
ORDER BY dbo.observations.ID, dbo.observations.RowId, dbo.observations.StartDate

GO
USE [master]
GO
ALTER DATABASE [Astro] SET  READ_WRITE 
GO
