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

--dbo.BOOK_LEND_RECORD  �� dbo.SPAN_TABLE ������j�_��
INNER JOIN dbo.BOOK_LEND_RECORD AS blr
	ON MONTH(blr.LEND_DATE) = st.SPAN_START OR		--�}�l��
	   MONTH(blr.LEND_DATE) = st.SPAN_START+1 OR	--������
	   MONTH(blr.LEND_DATE) = st.SPAN_END			--������

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
					  --ROW_NUMBER() OVER()...���C�@�ո�Ƥ@�ӼƦr ( �q 1 �}�l ++ )
                      --partition...�H���P BOOK_CLASS_NAME ����,�U�� class name �q 1 ���s���Ʀr
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

--�u���C�� book class ���e3�����
WHERE (
	per.Seq <= 3
)

ORDER BY per.BookClass,per.QTY DESC,per.BookId



--practice_05
SELECT bc.BOOK_CLASS_ID AS ClassId, 
       bc.BOOK_CLASS_NAME AS ClassName, 
	   sum ( CASE WHEN YEAR(blr.LEND_DATE) = '2016' THEN 1 ELSE 0 END ) AS CNT2016,		--�p��U�� class_name �b�Ӧ~�����`�ɮѶq
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
	   isnull([2016],0) AS CNT2016,				--�� NULL �����אּ 0
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
SELECT bd.BOOK_ID AS �ѥ�ID,
	   CONVERT(varchar,YEAR(bd.BOOK_BOUGHT_DATE)) + '/'
	   + CONVERT(varchar,MONTH(bd.BOOK_BOUGHT_DATE)) + '/'
	   + CONVERT(varchar,DAY(bd.BOOK_BOUGHT_DATE)) AS �ʮѤ��,					--�令 yyyy/mm/dd �Φ� (�N�X: 111)
	   CONVERT(varchar,blr.LEND_DATE , 111) AS �ɾ\���,						--�令 yyyy/mm/dd �Φ� (�N�X: 111)     
	   bc.BOOK_CLASS_ID + '-' + bc.BOOK_CLASS_NAME AS ���y���O,					--�令 BOOK_CLASS_id - BOOK_CLASS_name �Φ�
	   mm.USER_ID + '-' + mm.USER_CNAME + '(' + mm.USER_ENAME + ')' AS �ɾ\�H,  --�令 id-Cname(Ename) �Φ�
	   bco.CODE_ID + '-' + bco.CODE_NAME AS ���A,								--�令 codeid - codename �Φ�
	   REPLACE(CONVERT(varchar,CONVERT(money, bd.BOOK_AMOUNT), 1), '.00', '') + '��' AS �ʮѪ��B  
								--convert(~,money,1)�Φ�...xxx,xxx,xxx.00
							    --replace...��'.00'�����אּ''
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

ORDER BY �ѥ�ID DESC



--practice_08
--�d��Ʈw�̭��O�_���o�@�ӱ��󪺸��: �S��->�] insert,values ��->���L insert,values
IF NOT EXISTS (
	SELECT BOOK_ID,KEEPER_ID,LEND_DATE
	FROM dbo.BOOK_LEND_RECORD
	WHERE (
		BOOK_ID = '2004' AND
		KEEPER_ID = '0002' AND
		LEND_DATE = '2019/01/02'
	)
)
INSERT INTO dbo.BOOK_LEND_RECORD(BOOK_ID,KEEPER_ID,LEND_DATE)   --�W�[��ƧΦ�
VALUES ('2004','0002','2019/01/02')								--�W�[��Ƥ��e				
/*UPDATE dbo.BOOK_LEND_RECORD										--�n��s��ƪ� table
SET LEND_DATE = '2019/01/02'									--�n��s�����
WHERE (
	KEEPER_ID = '0002'
)*/
SELECT bd.BOOK_ID AS �ѥ�ID,
	   CONVERT(varchar,YEAR(bd.BOOK_BOUGHT_DATE)) + '/'
	   + CONVERT(varchar,MONTH(bd.BOOK_BOUGHT_DATE)) + '/'
	   + CONVERT(varchar,DAY(bd.BOOK_BOUGHT_DATE)) AS �ʮѤ��,	
	   CONVERT(varchar,blr.LEND_DATE , 111) AS �ɾ\���,
	   bc.BOOK_CLASS_ID + '-' + bc.BOOK_CLASS_NAME AS ���y���O,
	   mm.USER_ID + '-' + mm.USER_CNAME + '(' + mm.USER_ENAME + ')' AS �ɾ\�H,
	   bco.CODE_ID + '-' + bco.CODE_NAME AS ���A,
	   REPLACE(CONVERT(varchar,CONVERT(money, bd.BOOK_AMOUNT), 1), '.00', '') + '��' AS �ʮѪ��B  
	   
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

SELECT bd.BOOK_ID AS �ѥ�ID,
	   CONVERT(varchar,YEAR(bd.BOOK_BOUGHT_DATE)) + '/'
	   + CONVERT(varchar,MONTH(bd.BOOK_BOUGHT_DATE)) + '/'
	   + CONVERT(varchar,DAY(bd.BOOK_BOUGHT_DATE)) AS �ʮѤ��,
	   CONVERT(varchar,blr.LEND_DATE , 111) AS �ɾ\���,
	   bc.BOOK_CLASS_ID + '-' + bc.BOOK_CLASS_NAME AS ���y���O,
	   mm.USER_ID + '-' + mm.USER_CNAME + '(' + mm.USER_ENAME + ')' AS �ɾ\�H,
	   bco.CODE_ID + '-' + bco.CODE_NAME AS ���A,
	   REPLACE(CONVERT(varchar,CONVERT(money, bd.BOOK_AMOUNT), 1), '.00', '') + '��' AS �ʮѪ��B  

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