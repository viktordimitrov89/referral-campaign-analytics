--============================================
-- CLIENTS – CATEGORY DISTRIBUTION / EXPLORATORY CHECKS
--============================================

--============================================
1. CLIENTS GENDER VALIDATION
--============================================

SELECT
    GENDER,
    COUNT(*) AS RECORD_COUNT
FROM CLIENTS
GROUP BY GENDER
ORDER BY RECORD_COUNT DESC;

--============================================
2. CLIENTS CITY VALIDATION
--============================================

SELECT
    CITY,
    COUNT(*) AS RECORD_COUNT
FROM CLIENTS
GROUP BY CITY
ORDER BY RECORD_COUNT DESC;

--============================================
3. ACQUISITION CHANNEL VALIDATION
--============================================

SELECT
    ACQUISITION_CHANNEL,
    COUNT(*) AS RECORD_COUNT
FROM CLIENTS
GROUP BY ACQUISITION_CHANNEL
ORDER BY RECORD_COUNT DESC;

--============================================
4. CLIENTS: DEVICE OS VALIDATION
--============================================

SELECT
    DEVICE_OS,
    COUNT(*) AS RECORD_COUNT
FROM CLIENTS
GROUP BY DEVICE_OS
ORDER BY RECORD_COUNT DESC;

--============================================
5. CLIENTS: MAIN PRODUCT VALIDATION
--============================================

SELECT
    MAIN_PRODUCT,
    COUNT(*) AS RECORD_COUNT
FROM CLIENTS
GROUP BY MAIN_PRODUCT
ORDER BY RECORD_COUNT DESC;


--============================================
-- REFERRALS – BUSINESS LOGIC / SUPPORTING CHECKS
--============================================

--============================================
6. REFERRALS – Conditional Date Consistency
--============================================

SELECT
    COUNT(*) AS TOTAL_RECORDS,

    SUM(CASE
        WHEN REGISTRATION_DATE IS NOT NULL
         AND PHONE_ENTERED_DATE IS NULL
        THEN 1 ELSE 0
    END) AS REG_WITHOUT_PHONE,

    SUM(CASE
        WHEN CARD_ISSUED_DATE IS NOT NULL
         AND REGISTRATION_DATE IS NULL
        THEN 1 ELSE 0
    END) AS CARD_WITHOUT_REG,

    SUM(CASE
        WHEN CARD_ACTIVATED_DATE IS NOT NULL
         AND CARD_ISSUED_DATE IS NULL
        THEN 1 ELSE 0
    END) AS ACTIVATED_WITHOUT_CARD,

    SUM(CASE
        WHEN PHONE_ENTERED_DATE < INVITE_SENT_DATE
        THEN 1 ELSE 0
    END) AS INVALID_PHONE_DATE,

    SUM(CASE
        WHEN REGISTRATION_DATE < PHONE_ENTERED_DATE
        THEN 1 ELSE 0
    END) AS INVALID_REG_DATE,

    SUM(CASE
        WHEN CARD_ISSUED_DATE < REGISTRATION_DATE
        THEN 1 ELSE 0
    END) AS INVALID_CARD_DATE,

    SUM(CASE
        WHEN CARD_ACTIVATED_DATE < CARD_ISSUED_DATE
        THEN 1 ELSE 0
    END) AS INVALID_ACTIVATION_DATE

FROM REFERRALS;

--============================================
7. REFERRALS – INVITED CLIENT ID BUSINESS LOGIC REVIEW
--============================================

SELECT
    R.INVITED_CLIENT_ID,
    COUNT(*) AS RECORD_COUNT
FROM REFERRALS R
WHERE R.INVITED_CLIENT_ID IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM CLIENTS C
      WHERE C.CLIENT_ID = R.INVITED_CLIENT_ID
  )
GROUP BY R.INVITED_CLIENT_ID
ORDER BY RECORD_COUNT DESC;

--============================================
8. REFERRALS – Multiple Invitations per Invited Client
--============================================

SELECT
    INVITED_CLIENT_ID,
    COUNT(DISTINCT INVITE_ID) AS INVITE_COUNT
FROM REFERRALS
WHERE INVITED_CLIENT_ID IS NOT NULL
GROUP BY INVITED_CLIENT_ID
HAVING COUNT(DISTINCT INVITE_ID) > 1
ORDER BY INVITE_COUNT DESC;


--============================================
-- INVITED_ACTIVITY – BUSINESS LOGIC / CONSISTENCY CHECKS
--============================================

--============================================
9. INVITED_ACTIVITY – POS Transaction / Amount Consistency
--============================================

SELECT
    COUNT(*) AS TOTAL_RECORDS,

    SUM(CASE
        WHEN POS_TXN_COUNT = 0
         AND POS_AMOUNT_EUR = 0
        THEN 1 ELSE 0
    END) AS BOTH_ZERO,

    SUM(CASE
        WHEN POS_TXN_COUNT = 0
         AND POS_AMOUNT_EUR > 0
        THEN 1 ELSE 0
    END) AS ZERO_TXN_POSITIVE_AMOUNT,

    SUM(CASE
        WHEN POS_TXN_COUNT > 0
         AND POS_AMOUNT_EUR = 0
        THEN 1 ELSE 0
    END) AS POSITIVE_TXN_ZERO_AMOUNT

FROM INVITED_ACTIVITY;


--============================================
-- MONTHLY_KPI – FORMAT / STRUCTURE / EXPLORATORY CHECKS
--============================================

--============================================
10. MONTHLY_KPI – MONTH Distribution
--============================================

SELECT
    MONTH,
    COUNT(*) AS RECORD_COUNT
FROM MONTHLY_KPI
GROUP BY MONTH
ORDER BY MONTH;

--============================================
11. MONTHLY_KPI – Column Data Types Check
--============================================

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    DATA_PRECISION,
    DATA_SCALE
FROM USER_TAB_COLUMNS
WHERE TABLE_NAME = 'MONTHLY_KPI'
ORDER BY COLUMN_ID;

--============================================
12. MONTHLY_KPI – Zero Values Check
--============================================

SELECT
    SUM(CASE WHEN MAU = 0 THEN 1 ELSE 0 END) AS ZERO_MAU,
    SUM(CASE WHEN NEW_REGISTRATIONS = 0 THEN 1 ELSE 0 END) AS ZERO_NEW_REGISTRATIONS
FROM MONTHLY_KPI;

--============================================
13. MONTHLY_KPI – AVG_LOGINS Range Check
--============================================

SELECT
    MIN(AVG_LOGINS_PER_MAU) AS MIN_AVG_LOGINS,
    MAX(AVG_LOGINS_PER_MAU) AS MAX_AVG_LOGINS
FROM MONTHLY_KPI;

--============================================
14. MONTHLY_KPI – MONTH Chronological Validation
--============================================

SELECT
    MONTH,
    LAG(MONTH) OVER (ORDER BY MONTH) AS PREVIOUS_MONTH
FROM MONTHLY_KPI
ORDER BY MONTH;