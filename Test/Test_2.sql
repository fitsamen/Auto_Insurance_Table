

----Test-2


--===================

SELECT TOP 20
   W.WorkorderNumber,
   BT.TransactionId,
   CORP.GetBusinessDaysBetweenDates(BT.Createddate, GETDATE(), 0) AS DaysPast,
   BT.ExpediteType,
   BT.StatusId,
   FS.Snapshot AS UploadSnapshot,
   TN.Snapshot AS EntitySearchSnapshot
FROM CORP.BusinessTransactions BT WITH (NOLOCK)          
INNER JOIN CORP.TransactionType TT WITH (NOLOCK) 
    ON TT.TransactionTypeID = BT.TransactionTypeId          
INNER JOIN CORP.Workorder W WITH (NOLOCK) 
    ON BT.WorkorderId = W.WorkorderId          
INNER JOIN CORP.BusinessFilingType BFT WITH (NOLOCK) 
    ON BFT.BusinessFilingTypeId = TT.BusinessFilingTypeId          
INNER JOIN online.OnlineTransaction OT WITH (NOLOCK) 
    ON OT.BusinessTransactionID = BT.TransactionId          
INNER JOIN online.TransactionAppointment TA 
    ON OT.OnlineTransactionID = TA.OnlineTransactionID

-- Replacing OUTER APPLY with LEFT JOIN for Upload Document snapshot
LEFT JOIN [Online].FilingSnapshot FS 
    ON FS.TransactionID = 8618980  -- Previously used constant ID
    AND CHARINDEX('"SerialNumber":1', FS.[Snapshot]) > 0
LEFT JOIN Filing.STEP S1 WITH (NOLOCK) 
    ON S1.stepid = FS.StepID      
    AND S1.DisplayName LIKE 'Upload Document'          

-- Replacing OUTER APPLY with LEFT JOIN for Entity Search snapshot
LEFT JOIN [Online].FilingSnapshot TN 
    ON TN.TransactionID = OT.OnlineTransactionID
    AND CHARINDEX('"IsOwnerofTradeName":true', TN.[Snapshot]) > 0    
    AND BFT.Description = 'Articles of Organization'
LEFT JOIN Filing.STEP S2 WITH (NOLOCK) 
    ON S2.stepid = TN.StepID      
    AND S2.DisplayName LIKE 'Entity Search'          

WHERE 
    BT.IsOnline = 1          
    AND BT.StatusId = 2      
    AND BFT.Description IN ('Annual Report', 'Articles of Organization')          
    AND ta.AppointmentStatusID = 2 -- Pending          
    AND FS.[Snapshot] IS NULL          
    AND TN.[Snapshot] IS NULL          
    AND LTRIM(RTRIM(ISNULL(BT.BusinessName, ''))) <> ''        
    AND CAST(BT.DateTimeReceived AS DATE) >= '2020-08-06'
