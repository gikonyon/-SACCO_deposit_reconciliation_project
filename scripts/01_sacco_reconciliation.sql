-- ====================================================================
-- STIMA SACCO DEPOSIT RECONCILIATION & EXCEPTION DETECTION SCRIPT
-- ====================================================================

-- 1. Initialize Database & Schema
CREATE DATABASE PracticeDB;
GO
USE PracticeDB;
GO

CREATE TABLE Members (
    MemberNo VARCHAR(10) PRIMARY KEY,
    FullName VARCHAR(60),
    Branch VARCHAR(30)
);

CREATE TABLE FormDeposits (
    QRRef VARCHAR(12) PRIMARY KEY,
    MemberNo VARCHAR(10),
    Amount DECIMAL(12,2),
    SubmittedAt DATETIME
);

CREATE TABLE TellerLedger (
    LedgerID INT IDENTITY(1,1) PRIMARY KEY,
    QRRef VARCHAR(12),
    MemberNo VARCHAR(10),
    AmountPosted DECIMAL(12,2),
    PostedAt DATETIME,
    TellerID VARCHAR(6)
);
GO

-- 2. Insert Synthetic Test Data
INSERT INTO Members VALUES
('M001', 'Member One', 'Nairobi'),
('M002', 'Member Two', 'Nairobi'),
('M003', 'Member Three', 'Mombasa'),
('M004', 'Member Four', 'Mombasa'),
('M005', 'Member Five', 'Kisumu');

INSERT INTO FormDeposits VALUES
('QR1001', 'M001', 5000, '2026-10-01 09:10'),
('QR1002', 'M002', 12000, '2026-10-01 10:05'),
('QR1003', 'M003', 3000, '2026-10-02 11:20'),
('QR1004', 'M004', 8000, '2026-10-02 14:45'),
('QR1005', 'M005', 2500, '2026-10-03 08:30'),
('QR1006', 'M001', 4000, '2026-10-03 15:00');

INSERT INTO TellerLedger (QRRef, MemberNo, AmountPosted, PostedAt, TellerID) VALUES
('QR1001', 'M001', 5000, '2026-10-01 09:40', 'T01'),
('QR1002', 'M002', 10000, '2026-10-01 10:30', 'T01'),
('QR1003', 'M003', 3000, '2026-10-02 11:50', 'T02'),
('QR1003', 'M003', 3000, '2026-10-02 11:55', 'T02'),
('QR1005', 'M005', 2500, '2026-10-03 09:00', 'T03');
GO

-- 3. Core Reconciliation & Exception Status Classification Query
WITH LedgerSummary AS (
    SELECT 
        QRRef,
        COUNT(*) AS LedgerCount,
        SUM(AmountPosted) AS TotalPosted
    FROM TellerLedger
    GROUP BY QRRef
),
ReconciliationStatus AS (
    SELECT 
        f.QRRef,
        f.MemberNo,
        m.Branch,
        f.Amount AS FormAmount,
        ISNULL(ls.TotalPosted, 0) AS TotalPosted,
        CASE 
            WHEN ls.QRRef IS NULL THEN 'Not posted'
            WHEN ls.LedgerCount > 1 THEN 'Duplicate posting'
            WHEN f.Amount <> ls.TotalPosted THEN 'Amount mismatch'
            ELSE 'Matched'
        END AS Status
    FROM FormDeposits f
    INNER JOIN Members m ON f.MemberNo = m.MemberNo
    LEFT JOIN LedgerSummary ls ON f.QRRef = ls.QRRef
)
SELECT * FROM ReconciliationStatus;