--============================================
-- 1. REFERRALS – REMOVE EXACT DUPLICATES
--============================================

CREATE TABLE REFERRALS_CLEAN AS
SELECT DISTINCT *
FROM REFERRALS;

--============================================
-- 2. REFERRALS – INVALID INVITER_ID REVIEW
--============================================

SELECT
    R.INVITE_ID,
    R.INVITER_ID,
    R.INVITER_AGE_GROUP,
    R.INVITED_CLIENT_ID,
    R.INVITE_SENT_DATE,
    R.REWARD_PAID
FROM REFERRALS_CLEAN R
WHERE NOT EXISTS (
    SELECT 1
    FROM CLIENTS C
    WHERE C.CLIENT_ID = R.INVITER_ID
)
ORDER BY R.INVITER_ID;

--============================================
-- 3. REFERRALS – NEGATIVE POS AMOUNT REVIEW
--============================================

SELECT
    INVITE_ID,
    INVITER_ID,
    INVITED_CLIENT_ID,
    FIRST_POS_DATE,
    FIRST_POS_AMOUNT_EUR,
    REWARD_PAID
FROM REFERRALS_CLEAN
WHERE FIRST_POS_AMOUNT_EUR < 0
ORDER BY FIRST_POS_AMOUNT_EUR;

--============================================
-- 4. REFERRALS – REWARD POS ELIGIBILITY CHECK
--============================================

SELECT
    INVITE_ID,
    INVITER_ID,
    INVITED_CLIENT_ID,
    FIRST_POS_DATE,
    FIRST_POS_AMOUNT_EUR,
    REWARD_PAID
FROM REFERRALS_CLEAN
WHERE REWARD_PAID = 1
  AND (
      FIRST_POS_AMOUNT_EUR < 5
      OR FIRST_POS_AMOUNT_EUR IS NULL
  )
ORDER BY FIRST_POS_AMOUNT_EUR;

--============================================
-- 5. REFERRALS – MAXIMUM 5 REWARDS PER INVITER
--============================================

SELECT
    INVITER_ID,
    COUNT(DISTINCT INVITE_ID) AS PAID_REWARDS
FROM REFERRALS_CLEAN
WHERE REWARD_PAID = 1
GROUP BY INVITER_ID
HAVING COUNT(DISTINCT INVITE_ID) > 5
ORDER BY PAID_REWARDS DESC;

--============================================
-- 6. REFERRALS – MAXIMUM REWARDS DETAIL REVIEW
--============================================

SELECT
    INVITER_ID,
    INVITE_ID,
    INVITED_CLIENT_ID,
    INVITE_SENT_DATE,
    CARD_ACTIVATED_DATE,
    FIRST_POS_DATE,
    FIRST_POS_AMOUNT_EUR,
    REWARD_PAID
FROM REFERRALS_CLEAN
WHERE REWARD_PAID = 1
  AND INVITER_ID IN (
      SELECT INVITER_ID
      FROM REFERRALS_CLEAN
      WHERE REWARD_PAID = 1
      GROUP BY INVITER_ID
      HAVING COUNT(DISTINCT INVITE_ID) > 5
  )
ORDER BY INVITER_ID, INVITE_SENT_DATE;

--============================================
-- 6. REFERRALS – EXCESS REWARDS IDENTIFICATION
--============================================

SELECT
    INVITER_ID,
    INVITE_ID,
    INVITED_CLIENT_ID,
    FIRST_POS_DATE,
    FIRST_POS_AMOUNT_EUR,
    REWARD_PAID,
    REWARD_NUMBER,
    CASE
        WHEN REWARD_NUMBER <= 5 THEN 'WITHIN LIMIT'
        ELSE 'EXCEEDS LIMIT'
    END AS REWARD_STATUS
FROM (
    SELECT
        INVITER_ID,
        INVITE_ID,
        INVITED_CLIENT_ID,
        FIRST_POS_DATE,
        FIRST_POS_AMOUNT_EUR,
        REWARD_PAID,
        ROW_NUMBER() OVER (
            PARTITION BY INVITER_ID
            ORDER BY FIRST_POS_DATE, INVITE_ID
        ) AS REWARD_NUMBER
    FROM REFERRALS_CLEAN
    WHERE REWARD_PAID = 1
)
WHERE REWARD_NUMBER > 5
ORDER BY INVITER_ID, REWARD_NUMBER;

--============================================
-- 7. CLIENTS – MISSING VALUES REVIEW
--============================================

SELECT
    CLIENT_ID,
    AGE_GROUP,
    GENDER,
    CITY,
    ACQUISITION_CHANNEL,
    REGISTRATION_DATE,
    MAIN_PRODUCT,
    DEVICE_OS,
    ACTIVE_90D
FROM CLIENTS
WHERE CITY IS NULL
   OR GENDER IS NULL
ORDER BY CLIENT_ID;

--============================================
-- 8. CLIENTS – CREATE CLEAN TABLE
--============================================

CREATE TABLE CLIENTS_CLEAN AS
SELECT *
FROM CLIENTS;

--============================================
-- 9. INVITED_ACTIVITY – CLEANING REVIEW
--============================================

SELECT
    INVITED_CLIENT_ID,
    MONTH,
    POS_TXN_COUNT,
    POS_AMOUNT_EUR
FROM INVITED_ACTIVITY
WHERE POS_TXN_COUNT < 0
   OR POS_AMOUNT_EUR < 0
ORDER BY INVITED_CLIENT_ID, MONTH;

-- 10. INVITED_ACTIVITY – DUPLICATE REVIEW
--============================================

SELECT
    INVITED_CLIENT_ID,
    MONTH,
    COUNT(*) AS RECORD_COUNT
FROM INVITED_ACTIVITY
GROUP BY
    INVITED_CLIENT_ID,
    MONTH
HAVING COUNT(*) > 1
ORDER BY RECORD_COUNT DESC;

--============================================
-- 11. INVITED_ACTIVITY – TRANSACTION / AMOUNT REVIEW
--============================================

SELECT
    INVITED_CLIENT_ID,
    MONTH,
    POS_TXN_COUNT,
    POS_AMOUNT_EUR
FROM INVITED_ACTIVITY
WHERE (POS_TXN_COUNT = 0 AND POS_AMOUNT_EUR <> 0)
   OR (POS_TXN_COUNT > 0 AND POS_AMOUNT_EUR = 0)
ORDER BY INVITED_CLIENT_ID, MONTH;

--============================================
-- 12. INVITED_ACTIVITY – MONTH FORMAT REVIEW
--============================================

SELECT DISTINCT
    MONTH
FROM INVITED_ACTIVITY
WHERE NOT REGEXP_LIKE(MONTH, '^[0-9]{4}-(0[1-9]|1[0-2])$')
   OR MONTH IS NULL
ORDER BY MONTH;

--============================================
-- 13. CREATE INVITED_ACTIVITY_CLEAN
--============================================

CREATE TABLE INVITED_ACTIVITY_CLEAN AS
SELECT *
FROM INVITED_ACTIVITY;

--============================================
-- 14. CREATE MONTHLY_KPI_CLEAN
--============================================

CREATE TABLE MONTHLY_KPI_CLEAN AS
SELECT *
FROM MONTHLY_KPI;

--============================================
-- 15. FINAL CLEAN TABLES CHECK
--============================================

SELECT 'CLIENTS_CLEAN' AS TABLE_NAME, COUNT(*) AS TOTAL_RECORDS
FROM CLIENTS_CLEAN

UNION ALL

SELECT 'REFERRALS_CLEAN', COUNT(*)
FROM REFERRALS_CLEAN

UNION ALL

SELECT 'INVITED_ACTIVITY_CLEAN', COUNT(*)
FROM INVITED_ACTIVITY_CLEAN

UNION ALL

SELECT 'MONTHLY_KPI_CLEAN', COUNT(*)
FROM MONTHLY_KPI_CLEAN;