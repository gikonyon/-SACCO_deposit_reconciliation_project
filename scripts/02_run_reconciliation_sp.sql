-- ====================================================================
-- STIMA SACCO: DAILY RECONCILIATION STORED PROCEDURE & AUDIT LOG
-- Objective: Automate daily execution, capture historical exception snapshots,
--            and store audit metrics for Power BI trending and reporting.
-- ====================================================================

USE PracticeDB;
GO

-- 1. Create Historical Audit Log Table for Trend Analysis
IF OBJECT_ID('ReconciliationAuditLog', 'U') IS NOT NULL
    DROP TABLE ReconciliationAuditLog;
GO

CREATE TABLE ReconciliationAuditLog (
    AuditID INT IDENTITY(1,1) PRIMARY KEY,
    RunDate DATETIME DEFAULT GETDATE(),
    QRRef VARCHAR(12),
    MemberNo VARCHAR(10),
    Branch VARCHAR(30),
    FormAmount DECIMAL(12,2),
    TotalPosted DECIMAL(12,2),
    LedgerCount INT,
    ReconciliationStatus VARCHAR(30)
);
GO

-- 2. Create Stored Procedure for Daily Automated Reconciliation
CREATE OR ALTER PROCEDURE sp_RunDailyReconciliation
AS
BEGIN
    SET NOCOUNT ON;

    -- Clear previous run snapshot if re-running on the same day (optional design choice)
    -- TRUNCATE TABLE ReconciliationAuditLog;

    WITH LedgerSummary AS (
        SELECT 
            QRRef,
            COUNT(*) AS LedgerCount,
            SUM(AmountPosted) AS TotalPosted
        FROM TellerLedger
        GROUP BY QRRef
    ),
    CurrentReconciliation AS (
        SELECT 
            f.QRRef,
            f.MemberNo,
            m.Branch,
            f.Amount AS FormAmount,
            ISNULL(ls.TotalPosted, 0) AS TotalPosted,
            ISNULL(ls.LedgerCount, 0) AS LedgerCount,
            CASE 
                WHEN ls.QRRef IS NULL THEN 'Not posted'
                WHEN ls.LedgerCount > 1 THEN 'Duplicate posting'
                WHEN f.Amount <> ls.TotalPosted THEN 'Amount mismatch'
                ELSE 'Matched'
            END AS ReconciliationStatus
        FROM FormDeposits f
        INNER JOIN Members m ON f.MemberNo = m.MemberNo
        LEFT JOIN LedgerSummary ls ON f.QRRef = ls.QRRef
    )
    -- Insert results into the audit log table
    INSERT INTO ReconciliationAuditLog (
        RunDate, QRRef, MemberNo, Branch, FormAmount, TotalPosted, LedgerCount, ReconciliationStatus
    )
    SELECT 
        GETDATE(),
        QRRef,
        MemberNo,
        Branch,
        FormAmount,
        TotalPosted,
        LedgerCount,
        ReconciliationStatus
    FROM CurrentReconciliation;

    -- Return summary results for immediate verification
    SELECT 
        ReconciliationStatus,
        COUNT(*) AS ExceptionCount,
        SUM(FormAmount) AS TotalValue
    FROM ReconciliationAuditLog
    WHERE RunDate >= CAST(GETDATE() AS DATE)
    GROUP BY ReconciliationStatus;
END;
GO

-- ====================================================================
-- 3. EXECUTE THE STORED PROCEDURE
-- ====================================================================
EXEC sp_RunDailyReconciliation;
GO