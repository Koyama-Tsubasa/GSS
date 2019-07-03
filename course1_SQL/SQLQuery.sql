USE GSSWEB;
GO

--practice_01
SELECT USER_ID AS KeeperId, 
	   USER_CNAME AS CName, 
	   USER_ENAME AS EName, 
	   YEAR(LEND_DATE) AS BorrowYear, 
	   COUNT(BOOK_ID) AS BorrowCnt

FROM dbo.MEMBER_M AS mm

LEFT JOIN dbo.BOOK_LEND_RECORD AS blr
	ON blr.KEEPER_ID = mm.USER_ID

GROUP BY USER_ID, USER_CNAME, USER_ENAME, YEAR(LEND_DATE)

ORDER BY KeeperId, BorrowYear;



--practice_02
SELECT TOP 5  WITH TIES bd.BOOK_ID AS BookId, 
						bd.BOOK_NAME AS BookName,
						COUNT(bd.BOOK_ID) AS QTY

FROM dbo.BOOK_DATA AS bd

INNER JOIN dbo.BOOK_LEND_RECORD AS blr
	ON bd.BOOK_ID = blr.BOOK_ID

GROUP BY bd.BOOK_ID, bd.BOOK_NAME

ORDER BY QTY DESC



--practice_03
SELECT SPAN_YEAR + '/' + SPAN_START + '~' + SPAN_YEAR + '/' + SPAN_END AS [Quarter],
	   COUNT(SPAN_YEAR + '/' + SPAN_START + '~' + SPAN_YEAR + '/' + SPAN_END) AS Cnt

FROM dbo.SPAN_TABLE AS st

--dbo.BOOK_LEND_RECORD  跟 dbo.SPAN_TABLE 的月份綁起來
INNER JOIN dbo.BOOK_LEND_RECORD AS blr
	ON MONTH(blr.LEND_DATE) = st.SPAN_START OR		--開始月
	   MONTH(blr.LEND_DATE) = st.SPAN_START+1 OR	--中間月
	   MONTH(blr.LEND_DATE) = st.SPAN_END			--結束月

WHERE (
	SPAN_YEAR = 2019 AND
	YEAR(LEND_DATE) = 2019
)

GROUP BY SPAN_YEAR,SPAN_START,SPAN_END



--practice_04
SELECT per.Seq,per.BookClass,
	   per.BookId,per.BookName,
	   per.QTY

FROM (
					  --ROW_NUMBER() OVER()...給每一組資料一個數字 ( 從 1 開始 ++ )
                      --partition...以不同 BOOK_CLASS_NAME 分割,各個 class name 從 1 重新給數字
	SELECT ROW_NUMBER() OVER (PARTITION BY bc.BOOK_CLASS_NAME ORDER BY COUNT(bd.BOOK_ID) DESC) AS Seq, 
		   bc.BOOK_CLASS_NAME AS BookClass,
		   bd.BOOK_ID AS BookId, bd.BOOK_NAME AS BookName, COUNT(bd.BOOK_ID) AS QTY

	FROM dbo.BOOK_CLASS AS bc

	INNER JOIN dbo.BOOK_DATA AS bd
		ON bc.BOOK_CLASS_ID = bd.BOOK_CLASS_ID
	INNER JOIN dbo.BOOK_LEND_RECORD AS blr
		ON bd.BOOK_ID = blr.BOOK_ID

	GROUP BY bc.BOOK_CLASS_NAME, bd.BOOK_ID, bd.BOOK_NAME

) AS per

--只取每個 book class 的前3筆資料
WHERE (
	per.Seq <= 3
)

ORDER BY per.BookClass,per.QTY DESC,per.BookId



--practice_05
SELECT bc.BOOK_CLASS_ID AS ClassId, 
       bc.BOOK_CLASS_NAME AS ClassName, 
	   sum ( CASE WHEN YEAR(blr.LEND_DATE) = '2016' THEN 1 ELSE 0 END ) AS CNT2016,		--計算各個 class_name 在該年分的總借書量
	   sum ( CASE WHEN YEAR(blr.LEND_DATE) = '2017' THEN 1 ELSE 0 END ) AS CNT2017,
	   sum ( CASE WHEN YEAR(blr.LEND_DATE) = '2018' THEN 1 ELSE 0 END ) AS CNT2018,
	   sum ( CASE WHEN YEAR(blr.LEND_DATE) = '2019' THEN 1 ELSE 0 END ) AS CNT2019

FROM dbo.BOOK_CLASS AS bc

INNER JOIN dbo.BOOK_DATA AS bd
	ON bc.BOOK_CLASS_ID = bd.BOOK_CLASS_ID
INNER JOIN dbo.BOOK_LEND_RECORD AS blr
	ON bd.BOOK_ID = blr.BOOK_ID

GROUP BY bc.BOOK_CLASS_ID, bc.BOOK_CLASS_NAME

ORDER BY bc.BOOK_CLASS_ID



--practice_06
SELECT ClassId, 
	   ClassName,
	   isnull([2016],0) AS CNT2016,				--讓 NULL 全部改為 0
	   isnull([2017],0) AS CNT2017,
	   isnull([2018],0) AS CNT2018,
	   isnull([2019],0) AS CNT2019									

FROM (

	SELECT bc.BOOK_CLASS_ID AS ClassId, 
	       bc.BOOK_CLASS_NAME AS ClassName, 
		   YEAR(blr.LEND_DATE) AS lendyear, 
		   COUNT(bc.BOOK_CLASS_ID) AS Cbookclass

	FROM dbo.BOOK_CLASS AS bc

	INNER JOIN dbo.BOOK_DATA AS bd
		ON bc.BOOK_CLASS_ID = bd.BOOK_CLASS_ID
	INNER JOIN dbo.BOOK_LEND_RECORD AS blr
		ON bd.BOOK_ID = blr.BOOK_ID

	GROUP BY bc.BOOK_CLASS_ID, bc.BOOK_CLASS_NAME, YEAR(blr.LEND_DATE)

) AS data

PIVOT (
	SUM(Cbookclass) FOR lendyear IN ([2016],[2017],[2018],[2019])
) AS pvt

ORDER BY ClassId



--practice_07
SELECT bd.BOOK_ID AS 書本ID,
	   CONVERT(varchar,YEAR(bd.BOOK_BOUGHT_DATE)) + '/'
	   + CONVERT(varchar,MONTH(bd.BOOK_BOUGHT_DATE)) + '/'
	   + CONVERT(varchar,DAY(bd.BOOK_BOUGHT_DATE)) AS 購書日期,					--改成 yyyy/mm/dd 形式 (代碼: 111)
	   CONVERT(varchar,blr.LEND_DATE , 111) AS 借閱日期,						--改成 yyyy/mm/dd 形式 (代碼: 111)     
	   bc.BOOK_CLASS_ID + '-' + bc.BOOK_CLASS_NAME AS 書籍類別,					--改成 BOOK_CLASS_id - BOOK_CLASS_name 形式
	   mm.USER_ID + '-' + mm.USER_CNAME + '(' + mm.USER_ENAME + ')' AS 借閱人,  --改成 id-Cname(Ename) 形式
	   bco.CODE_ID + '-' + bco.CODE_NAME AS 狀態,								--改成 codeid - codename 形式
	   REPLACE(CONVERT(varchar,CONVERT(money, bd.BOOK_AMOUNT), 1), '.00', '') + '元' AS 購書金額  
								--convert(~,money,1)形式...xxx,xxx,xxx.00
							    --replace...把'.00'部分改為''
FROM dbo.BOOK_DATA AS bd

INNER JOIN dbo.BOOK_LEND_RECORD AS blr
	ON blr.BOOK_ID = bd.BOOK_ID
INNER JOIN dbo.BOOK_CLASS AS bc
	ON bc.BOOK_CLASS_ID = bd.BOOK_CLASS_ID
INNER JOIN dbo.MEMBER_M AS mm
	ON mm.USER_ID = blr.KEEPER_ID
INNER JOIN dbo.BOOK_CODE AS bco
	ON bco.CODE_ID = bd.BOOK_STATUS

WHERE (
	mm.USER_ID = '0002' AND
	bco.CODE_TYPE = 'BOOK_STATUS'
)

ORDER BY 書本ID DESC



--practice_08
--查資料庫裡面是否有這一個條件的資料: 沒有->跑 insert,values 有->跳過 insert,values
IF NOT EXISTS (
	SELECT BOOK_ID,KEEPER_ID,LEND_DATE
	FROM dbo.BOOK_LEND_RECORD
	WHERE (
		BOOK_ID = '2004' AND
		KEEPER_ID = '0002' AND
		LEND_DATE = '2019/01/02'
	)
)
INSERT INTO dbo.BOOK_LEND_RECORD(BOOK_ID,KEEPER_ID,LEND_DATE)   --增加資料形式
VALUES ('2004','0002','2019/01/02')								--增加資料內容				
/*UPDATE dbo.BOOK_LEND_RECORD										--要更新資料的 table
SET LEND_DATE = '2019/01/02'									--要更新的資料
WHERE (
	KEEPER_ID = '0002'
)*/
SELECT bd.BOOK_ID AS 書本ID,
	   CONVERT(varchar,YEAR(bd.BOOK_BOUGHT_DATE)) + '/'
	   + CONVERT(varchar,MONTH(bd.BOOK_BOUGHT_DATE)) + '/'
	   + CONVERT(varchar,DAY(bd.BOOK_BOUGHT_DATE)) AS 購書日期,	
	   CONVERT(varchar,blr.LEND_DATE , 111) AS 借閱日期,
	   bc.BOOK_CLASS_ID + '-' + bc.BOOK_CLASS_NAME AS 書籍類別,
	   mm.USER_ID + '-' + mm.USER_CNAME + '(' + mm.USER_ENAME + ')' AS 借閱人,
	   bco.CODE_ID + '-' + bco.CODE_NAME AS 狀態,
	   REPLACE(CONVERT(varchar,CONVERT(money, bd.BOOK_AMOUNT), 1), '.00', '') + '元' AS 購書金額  
	   
FROM dbo.BOOK_DATA AS bd

INNER JOIN dbo.BOOK_LEND_RECORD AS blr
	ON blr.BOOK_ID = bd.BOOK_ID
INNER JOIN dbo.BOOK_CLASS AS bc
	ON bc.BOOK_CLASS_ID = bd.BOOK_CLASS_ID
INNER JOIN dbo.MEMBER_M AS mm
	ON mm.USER_ID = blr.KEEPER_ID
INNER JOIN dbo.BOOK_CODE AS bco
ON bco.CODE_ID = bd.BOOK_STATUS

WHERE (
	mm.USER_ID = '0002'
)

ORDER BY bd.BOOK_AMOUNT DESC



--practice_09
DELETE FROM dbo.BOOK_LEND_RECORD WHERE ( 
	BOOK_ID = '2004' AND
	KEEPER_ID = '0002' AND
	LEND_DATE = '2019/01/02' 
)

SELECT bd.BOOK_ID AS 書本ID,
	   CONVERT(varchar,YEAR(bd.BOOK_BOUGHT_DATE)) + '/'
	   + CONVERT(varchar,MONTH(bd.BOOK_BOUGHT_DATE)) + '/'
	   + CONVERT(varchar,DAY(bd.BOOK_BOUGHT_DATE)) AS 購書日期,
	   CONVERT(varchar,blr.LEND_DATE , 111) AS 借閱日期,
	   bc.BOOK_CLASS_ID + '-' + bc.BOOK_CLASS_NAME AS 書籍類別,
	   mm.USER_ID + '-' + mm.USER_CNAME + '(' + mm.USER_ENAME + ')' AS 借閱人,
	   bco.CODE_ID + '-' + bco.CODE_NAME AS 狀態,
	   REPLACE(CONVERT(varchar,CONVERT(money, bd.BOOK_AMOUNT), 1), '.00', '') + '元' AS 購書金額  

FROM dbo.BOOK_DATA AS bd

INNER JOIN dbo.BOOK_LEND_RECORD AS blr
	ON blr.BOOK_ID = bd.BOOK_ID
INNER JOIN dbo.BOOK_CLASS AS bc
	ON bc.BOOK_CLASS_ID = bd.BOOK_CLASS_ID
INNER JOIN dbo.MEMBER_M AS mm
	ON mm.USER_ID = blr.KEEPER_ID
INNER JOIN dbo.BOOK_CODE AS bco
ON bco.CODE_ID = bd.BOOK_STATUS

WHERE (
	mm.USER_ID = '0002'
)

ORDER BY bd.BOOK_AMOUNT DESC