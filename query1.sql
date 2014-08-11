SELECT 
		 a.AGR_PartnerName AS PartnerNombre,
		 a.AGR_Id AS acuerdoid,
		 a.AGR_Name AS acuerdoNombre,
		 a.AGR_Dstart AS Desde,
		 a.AGR_Dend AS Hasta,
		 'SWAPS' usrName,
		 'XXX' AS estadoNombre,
		 'SHORTFALL' shortfall,
		IF(DATEDIFF(MAX(LastDay), a.AGR_Dstart) <= 0, 1, DATEDIFF(MAX(LastDay), a.AGR_Dstart) / DATEDIFF(a.AGR_Dend, a.AGR_Dstart)) as ProgressTime, 
		MAX(LastDay) LastDay,
		SUM(BCMargen) BCMargen,
		SUM(ReMargin) AS ReMargin,
		SUM(RepoMargin) AS RepoMargin,
		SUM(RealNetMargin) AS RealNetMargin,
		SUM(MargenBCActual) AS MargenBCActual,
		SUM(SentMins) AS SentMins,
		SUM(ReMargin) / SUM(SentMins) AS AMPM,
		SUM(ReMargin) / SUM(REVENUE) as MarginPctl,
		SUM(RemainingMargin) AS RemainingMargin
		
FROM (
		SELECT AGR_Id, PRB_Id, MAX(rb.REB_MaxDia) LastDay,
			 IFNULL(SUM(rb.REB_ADB_Mins * (rb.REB_ADB_AvgSELL - rb.REB_ADB_Rate)),0) AS BCMargen,
--			 IF(pb.PRB_Type = 'Mins', IFNULL(SUM(((rb.REB_SentMins/ rb.REB_BUYvsSELL) * rb.REB_RealARPM) - (rb.REB_SentMins * rb.REB_ADB_Rate)),0), IFNULL(SUM(((rb.REB_SentMins/ rb.REB_BUYvsSELL) * rb.REB_RealARPM) - (rb.REB_SentMins * rb.REB_BUYvsSELL)),0)) AS ReMargin,
			 IF(pb.PRB_Type = 'Mins', IFNULL(SUM(((rb.REB_SentMins/ rb.REB_BUYvsSELL) * rb.REB_RealARPM) - (rb.REB_SentMins * rb.REB_ADB_Rate)),0), IFNULL(SUM(((rb.REB_SentMins/ rb.REB_BUYvsSELL)) - (rb.REB_SentMins)),0)) AS ReMargin,
			 -- IFNULL(SUM(((rb.REB_SentMins/ rb.REB_BUYvsSELL) * rb.REB_RealARPM) - (rb.REB_SentMins * rb.REB_ADB_Rate)),0) AS ReMargin,
			 (SUM((rb.REB_SentMins / rb.REB_BUYvsSELL) * rb.REB_RealARPM) -
     			SUM(rb.REB_SentMins * rb.REB_RealACPM)) AS RepoMargin,
			 0 AS RealNetMargin,
			IF(pb.PRB_Type = 'Mins', IFNULL(SUM(((rb.REB_SentMins/ rb.REB_BUYvsSELL) * rb.REB_ADB_AvgSELL) - (rb.REB_SentMins * rb.REB_ADB_Rate)),0), IFNULL(SUM(rb.REB_SentMins * (REB_ADB_AvgSELL - rb.REB_ADB_Rate)),0)) AS MargenBCActual, 
			-- IFNULL(SUM(((rb.REB_SentMins/ rb.REB_BUYvsSELL) * rb.REB_ADB_AvgSELL) - (rb.REB_SentMins * rb.REB_ADB_Rate)),0) AS MargenBCActual,
			SUM(rb.REB_SentMins) SentMins,
			SUM((rb.REB_SentMins/ rb.REB_BUYvsSELL) * rb.REB_RealARPM) REVENUE,
			SUM(rb.REB_RealAMPM * (rb.REB_ADB_Mins - rb.REB_SentMins)) RemainingMargin1,
--			(SUM(rb.REB_RealAMPM * rb.REB_SentMins) / SUM(rb.REB_SentMins)) * SUM((rb.REB_ADB_Mins - rb.REB_SentMins)) RemainingMargin
--			SUM( IFNULL(((rb.REB_RealAMPM * rb.REB_SentMins) / (rb.REB_SentMins)), IFNULL((rb.REB_ADB_AvgSELL - rb.REB_ADB_Rate),0)) * ((IFNULL(rb.REB_ADB_Mins,0) - IFNULL(rb.REB_SentMins,0)))) RemainingMargin			
			SUM( IFNULL(((IF(pb.PRB_Type = 'Mins', rb.REB_RealAMPM, (rb.REB_ADB_Rate - rb.REB_BUYvsSELL)) * rb.REB_SentMins) / (rb.REB_SentMins)), IFNULL((rb.REB_ADB_AvgSELL - rb.REB_ADB_Rate),0)) * ((IFNULL(rb.REB_ADB_Mins,0) - IFNULL(rb.REB_SentMins,0)))) RemainingMargin			
		FROM REB_ResumenBUY rb
		 JOIN AGR_Agreement a ON a.AGR_Id = rb.REB_AGR_Id
		 JOIN PRB_ProductBUY pb ON pb.PRB_Id = rb.REB_ADB_PRB_Id		 
		WHERE a.AGR_Id IN(${Acuerdos})
		GROUP BY 1,2

		UNION ALL

		SELECT AGR_Id, PRS_Id, MAX(rs.RES_MaxDia) LastDay,
			 IFNULL(SUM(rs.RES_ADS_Mins * (rs.RES_ADS_Rate-rs.RES_ADS_AvgBUY)),0) AS BCMargen,
--			 IF(ps.PRS_Type = 'Mins', IFNULL(SUM((rs.RES_SentMins * rs.RES_ADS_Rate) - ((rs.RES_SentMins/ rs.RES_BUYvsSELL) * rs.RES_RealACPM)),0), IFNULL(SUM((rs.RES_SentMins * rs.RES_ADS_Rate) - ((rs.RES_SentMins * rs.RES_BUYvsSELL))),0)) AS ReMargin,
			 IF(ps.PRS_Type = 'Mins', IFNULL(SUM((rs.RES_SentMins * rs.RES_ADS_Rate) - ((rs.RES_SentMins/ rs.RES_BUYvsSELL) * rs.RES_RealACPM)),0), IFNULL(SUM((rs.RES_SentMins * rs.RES_ADS_Rate) - ((rs.RES_SentMins * rs.RES_BUYvsSELL))),0)) AS ReMargin,
			 -- IFNULL(SUM((rs.RES_SentMins * rs.RES_ADS_Rate) - ((rs.RES_SentMins/ rs.RES_BUYvsSELL) * rs.RES_RealACPM)),0) AS ReMargin,
			 (SUM(rs.RES_SentMins * rs.RES_RealARPM) - 
	   		 SUM((rs.RES_SentMins / rs.RES_BUYvsSELL) * rs.RES_RealACPM)) AS RepoMargin,
			 0 AS RealNetMargin,
		 	 IF(ps.PRS_Type = 'Mins', IFNULL(SUM((rs.RES_SentMins * rs.RES_ADS_Rate) - ((rs.RES_SentMins/ rs.RES_BUYvsSELL) * rs.RES_ADS_AvgBUY)),0), IFNULL(SUM(rs.RES_SentMins * (rs.RES_ADS_Rate - rs.RES_ADS_AvgBUY )),0)) AS MargenBCActual,
			 -- IFNULL(SUM((rs.RES_SentMins * rs.RES_ADS_Rate) - ((rs.RES_SentMins/ rs.RES_BUYvsSELL) * rs.RES_ADS_AvgBUY)),0) AS MargenBCActual,
			 SUM(rs.RES_SentMins) SentMins,
			 SUM((rs.RES_SentMins * rs.RES_ADS_Rate)) REVENUE,
			 SUM(rs.RES_RealAMPM * (rs.RES_ADS_Mins - rs.RES_SentMins)) RemainingMargin1,
--		  	(SUM(rs.RES_RealAMPM * rs.RES_SentMins) / SUM(rs.RES_SentMins)) * SUM((rs.RES_ADS_Mins - rs.RES_SentMins)) RemainingMargin
--			SUM(IFNULL(((rs.RES_RealAMPM * rs.RES_SentMins) / (rs.RES_SentMins)), IFNULL((rs.RES_ADS_Rate-rs.RES_ADS_AvgBUY),0) ) * ((IFNULL(rs.RES_ADS_Mins,0) - IFNULL(rs.RES_SentMins,0))))	RemainingMargin
			SUM(IFNULL(((IF(ps.PRS_Type = 'Mins', rs.RES_RealAMPM, (rs.RES_ADS_Rate - rs.RES_BUYvsSELL)) * rs.RES_SentMins) / (rs.RES_SentMins)), IFNULL((rs.RES_ADS_Rate-rs.RES_ADS_AvgBUY),0) ) * ((IFNULL(rs.RES_ADS_Mins,0) - IFNULL(rs.RES_SentMins,0))))	RemainingMargin	
		FROM RES_ResumenSELL rs
		 JOIN AGR_Agreement a ON a.AGR_Id = rs.RES_AGR_Id
		 JOIN PRS_ProductSELL ps ON ps.PRS_Id = rs.RES_ADS_PRS_Id
		WHERE a.AGR_Id IN(${Acuerdos})
		GROUP BY 1,2
) r
 JOIN AGR_Agreement a ON a.AGR_Id = r.AGR_Id
GROUP BY a.AGR_Id
