--============================================
-- Data Quality Check
--============================================

SELECT
    COUNT(*) AS TOTAL_RECORDS,

    SUM(CASE WHEN CLIENT_ID IS NULL
        THEN 1 ELSE 0 END) AS NULL_CLIENT_ID,

    SUM(CASE WHEN AGE_GROUP IS NULL
        THEN 1 ELSE 0 END) AS NULL_AGE_GROUP,

    SUM(CASE WHEN GENDER IS NULL
        THEN 1 ELSE 0 END) AS NULL_GENDER,

    SUM(CASE WHEN CITY IS NULL
        THEN 1 ELSE 0 END) AS NULL_CITY,

    SUM(CASE WHEN ACQUISITION_CHANNEL IS NULL
        THEN 1 ELSE 0 END) AS NULL_CHANNEL,

    SUM(CASE WHEN REGISTRATION_DATE IS NULL
        THEN 1 ELSE 0 END) AS NULL_REG_DATE,

    SUM(CASE WHEN MAIN_PRODUCT IS NULL
        THEN 1 ELSE 0 END) AS NULL_PRODUCT,

    SUM(CASE WHEN DEVICE_OS IS NULL
        THEN 1 ELSE 0 END) AS NULL_DEVICE,

    SUM(CASE WHEN ACTIVE_90D IS NULL
        THEN 1 ELSE 0 END) AS NULL_ACTIVE_90D

FROM CLIENTS;


--============================================
2. CLIENTS – Duplicate Records Check
--============================================

SELECT
    CLIENT_ID,
    COUNT(*) AS DUPLICATE_COUNT
FROM CLIENTS
GROUP BY CLIENT_ID
HAVING COUNT(*) > 1
ORDER BY DUPLICATE_COUNT DESC;


--============================================
3. CLIENTS NULL CLIENT_ID CHECK
--============================================

SELECT
    COUNT(*) AS TOTAL_RECORDS,
    SUM(CASE
        WHEN CLIENT_ID IS NULL THEN 1
        ELSE 0
    END) AS NULL_CLIENT_ID
FROM CLIENTS;


--============================================
4. CLIENTS – Invalid Values Check
--============================================

SELECT DISTINCT AGE_GROUP
FROM CLIENTS
ORDER BY AGE_GROUP;

--

SELECT DISTINCT GENDER
FROM CLIENTS
ORDER BY GENDER;

--

SELECT DISTINCT ACTIVE_90D
FROM CLIENTS
ORDER BY ACTIVE_90D;


--============================================
5. CLIENTS – Registration Date Validation
--============================================

SELECT
    COUNT(*) AS TOTAL_RECORDS,
    SUM(CASE
        WHEN REGISTRATION_DATE > SYSDATE THEN 1
        ELSE 0
    END) AS FUTURE_REGISTRATION_DATES,
    MIN(REGISTRATION_DATE) AS EARLIEST_REGISTRATION,
    MAX(REGISTRATION_DATE) AS LATEST_REGISTRATION
FROM CLIENTS;


--============================================
6. Check Missing Values in Referrals
--============================================

SELECT
    COUNT(*) AS TOTAL_RECORDS,

    SUM(CASE WHEN INVITE_ID IS NULL
        THEN 1 ELSE 0 END) AS NULL_INVITE_ID,

    SUM(CASE WHEN INVITER_ID IS NULL
        THEN 1 ELSE 0 END) AS NULL_INVITER_ID,

    SUM(CASE WHEN INVITER_AGE_GROUP IS NULL
        THEN 1 ELSE 0 END) AS NULL_AGE_GROUP,

    SUM(CASE WHEN INVITE_SENT_DATE IS NULL
        THEN 1 ELSE 0 END) AS NULL_SENT_DATE,

    SUM(CASE WHEN PHONE_ENTERED_DATE IS NULL
        THEN 1 ELSE 0 END) AS NULL_PHONE_DATE,

    SUM(CASE WHEN REGISTRATION_DATE IS NULL
        THEN 1 ELSE 0 END) AS NULL_REG_DATE,

    SUM(CASE WHEN CARD_ISSUED_DATE IS NULL
        THEN 1 ELSE 0 END) AS NULL_CARD_ISSUED,

    SUM(CASE WHEN CARD_ACTIVATED_DATE IS NULL
        THEN 1 ELSE 0 END) AS NULL_CARD_ACTIVATED

FROM REFERRALS;


--============================================
7. REFERRALS – Duplicate INVITE_ID Check
--============================================

SELECT
    INVITE_ID,
    COUNT(*) AS DUPLICATE_COUNT
FROM REFERRALS
GROUP BY INVITE_ID
HAVING COUNT(*) > 1
ORDER BY DUPLICATE_COUNT DESC;


--============================================
8. REFERRALS – Exact Duplicate Records
--============================================

SELECT *
FROM REFERRALS
WHERE INVITE_ID IN (
    SELECT INVITE_ID
    FROM REFERRALS
    GROUP BY INVITE_ID
    HAVING COUNT(*) > 1
)
ORDER BY INVITE_ID;


--============================================
9. REFERRALS – INVITER_ID Referential Integrity Check
--============================================

SELECT
    R.INVITER_ID,
    COUNT(*) AS RECORD_COUNT
FROM REFERRALS R
WHERE R.INVITER_ID IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM CLIENTS C
      WHERE C.CLIENT_ID = R.INVITER_ID
  )
GROUP BY R.INVITER_ID
ORDER BY RECORD_COUNT DESC;


--============================================
10. REFERRALS – Invalid INVITER_ID Summary
--============================================

SELECT
    COUNT(*) AS INVALID_RECORDS,
    COUNT(DISTINCT R.INVITER_ID) AS INVALID_INVITER_IDS
FROM REFERRALS R
WHERE R.INVITER_ID IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM CLIENTS C
      WHERE C.CLIENT_ID = R.INVITER_ID
  );


--============================================
11. REFERRALS – Analyze Invalid INVITER_ID
--============================================

SELECT *
FROM REFERRALS
WHERE INVITER_ID IN (
    SELECT DISTINCT R.INVITER_ID
    FROM REFERRALS R
    WHERE R.INVITER_ID IS NOT NULL
      AND NOT EXISTS (
          SELECT 1
          FROM CLIENTS C
          WHERE C.CLIENT_ID = R.INVITER_ID
      )
)
ORDER BY INVITER_ID;


--============================================
12. REFERRALS – FIRST_POS_AMOUNT_EUR Validity Check
--============================================

SELECT
    COUNT(*) AS TOTAL_RECORDS,
    SUM(CASE
        WHEN FIRST_POS_AMOUNT_EUR < 0
        THEN 1 ELSE 0
    END) AS NEGATIVE_AMOUNTS
FROM REFERRALS;


--============================================
13. REFERRALS – Negative POS Amount Details
--============================================

SELECT
    INVITE_ID,
    FIRST_POS_AMOUNT_EUR
FROM REFERRALS
WHERE FIRST_POS_AMOUNT_EUR < 0
ORDER BY FIRST_POS_AMOUNT_EUR;


--============================================
14. REFERRALS – Date Sequence Validation
--============================================

SELECT
    COUNT(*) AS TOTAL_RECORDS,

    SUM(CASE
        WHEN PHONE_ENTERED_DATE < INVITE_SENT_DATE
        THEN 1 ELSE 0
    END) AS PHONE_BEFORE_INVITE,

    SUM(CASE
        WHEN REGISTRATION_DATE < PHONE_ENTERED_DATE
        THEN 1 ELSE 0
    END) AS REG_BEFORE_PHONE,

    SUM(CASE
        WHEN CARD_ISSUED_DATE < REGISTRATION_DATE
        THEN 1 ELSE 0
    END) AS CARD_BEFORE_REG,

    SUM(CASE
        WHEN CARD_ACTIVATED_DATE < CARD_ISSUED_DATE
        THEN 1 ELSE 0
    END) AS ACTIVATION_BEFORE_ISSUE,

    SUM(CASE
        WHEN FIRST_POS_DATE < CARD_ACTIVATED_DATE
        THEN 1 ELSE 0
    END) AS POS_BEFORE_ACTIVATION

FROM REFERRALS;


--============================================
15. REFERRALS – INVITER_AGE_GROUP Consistency Check
--============================================

SELECT
    R.INVITE_ID,
    R.INVITER_ID,
    R.INVITER_AGE_GROUP,
    C.AGE_GROUP AS CLIENT_AGE_GROUP
FROM REFERRALS R
JOIN CLIENTS C
    ON R.INVITER_ID = C.CLIENT_ID
WHERE R.INVITER_AGE_GROUP <> C.AGE_GROUP
   OR (R.INVITER_AGE_GROUP IS NULL AND C.AGE_GROUP IS NOT NULL)
   OR (R.INVITER_AGE_GROUP IS NOT NULL AND C.AGE_GROUP IS NULL);


--============================================
16. INVITED ACTIVITY NULL CHECK
--============================================

SELECT
    COUNT(*) AS TOTAL_RECORDS,

    SUM(CASE WHEN INVITED_CLIENT_ID IS NULL
        THEN 1 ELSE 0 END) AS NULL_CLIENT_ID,

    SUM(CASE WHEN MONTH IS NULL
        THEN 1 ELSE 0 END) AS NULL_MONTH,

    SUM(CASE WHEN POS_TXN_COUNT IS NULL
        THEN 1 ELSE 0 END) AS NULL_TXN_COUNT,

    SUM(CASE WHEN POS_AMOUNT_EUR IS NULL
        THEN 1 ELSE 0 END) AS NULL_AMOUNT

FROM INVITED_ACTIVITY;


--============================================
17. INVITED ACTIVITY NUMERIC VALIDATION
--============================================

SELECT
    COUNT(*) AS TOTAL_RECORDS,

    SUM(CASE
        WHEN POS_TXN_COUNT < 0
        THEN 1 ELSE 0
    END) AS NEGATIVE_TXN_COUNT,

    SUM(CASE
        WHEN POS_AMOUNT_EUR < 0
        THEN 1 ELSE 0
    END) AS NEGATIVE_AMOUNT

FROM INVITED_ACTIVITY;


--============================================
18. INVITED ACTIVITY DUPLICATE CHECK
--============================================

SELECT
    INVITED_CLIENT_ID,
    MONTH,
    COUNT(*) AS DUPLICATE_COUNT
FROM INVITED_ACTIVITY
GROUP BY
    INVITED_CLIENT_ID,
    MONTH
HAVING COUNT(*) > 1
ORDER BY DUPLICATE_COUNT DESC;


--============================================
19. INVITED ACTIVITY MONTHLY VALIDATION
--============================================

SELECT
    COUNT(*) AS TOTAL_RECORDS,

    SUM(CASE
        WHEN MONTH IS NULL THEN 1
        ELSE 0
    END) AS NULL_MONTHS,

    SUM(CASE
        WHEN NOT REGEXP_LIKE(MONTH, '^[0-9]{4}-(0[1-9]|1[0-2])$')
        THEN 1
        ELSE 0
    END) AS INVALID_MONTHS

FROM INVITED_ACTIVITY;


--============================================
20. MONTHLY_KPI – MONTH NULL CHECK
--============================================

SELECT
    COUNT(*) AS TOTAL_RECORDS,
    SUM(CASE
        WHEN MONTH IS NULL
        THEN 1 ELSE 0
    END) AS NULL_MONTH
FROM MONTHLY_KPI;


--============================================
21. MONTHLY_KPI – Duplicate Check
--============================================

SELECT
    MONTH,
    COUNT(*) AS RECORD_COUNT
FROM MONTHLY_KPI
GROUP BY MONTH
HAVING COUNT(*) > 1
ORDER BY MONTH;


--============================================
22. MONTHLY_KPI – Negative Values Check
--============================================

SELECT
    SUM(CASE WHEN MAU < 0 THEN 1 ELSE 0 END) AS NEGATIVE_MAU,
    SUM(CASE WHEN NEW_REGISTRATIONS < 0 THEN 1 ELSE 0 END) AS NEGATIVE_NEW_REGISTRATIONS,
    SUM(CASE WHEN ACTIVATION_RATE_30D < 0 THEN 1 ELSE 0 END) AS NEGATIVE_ACTIVATION_RATE,
    SUM(CASE WHEN AVG_LOGINS_PER_MAU < 0 THEN 1 ELSE 0 END) AS NEGATIVE_AVG_LOGINS,
    SUM(CASE WHEN POS_USERS_SHARE < 0 THEN 1 ELSE 0 END) AS NEGATIVE_POS_SHARE,
    SUM(CASE WHEN P2P_USERS_SHARE < 0 THEN 1 ELSE 0 END) AS NEGATIVE_P2P_SHARE,
    SUM(CASE WHEN INACTIVE_90D_SHARE < 0 THEN 1 ELSE 0 END) AS NEGATIVE_INACTIVE_SHARE
FROM MONTHLY_KPI;


--============================================
23. MONTHLY_KPI – Percentage Range Validation
--============================================

SELECT
    SUM(CASE
        WHEN ACTIVATION_RATE_30D < 0 OR ACTIVATION_RATE_30D > 1
        THEN 1 ELSE 0
    END) AS INVALID_ACTIVATION_RATE,

    SUM(CASE
        WHEN POS_USERS_SHARE < 0 OR POS_USERS_SHARE > 1
        THEN 1 ELSE 0
    END) AS INVALID_POS_SHARE,

    SUM(CASE
        WHEN P2P_USERS_SHARE < 0 OR P2P_USERS_SHARE > 1
        THEN 1 ELSE 0
    END) AS INVALID_P2P_SHARE,

    SUM(CASE
        WHEN INACTIVE_90D_SHARE < 0 OR INACTIVE_90D_SHARE > 1
        THEN 1 ELSE 0
    END) AS INVALID_INACTIVE_SHARE

FROM MONTHLY_KPI;


--============================================
24. MONTHLY_KPI – NULL Values Check
--============================================

SELECT
    COUNT(*) AS TOTAL_RECORDS,
    SUM(CASE WHEN MAU IS NULL THEN 1 ELSE 0 END) AS NULL_MAU,
    SUM(CASE WHEN NEW_REGISTRATIONS IS NULL THEN 1 ELSE 0 END) AS NULL_NEW_REGISTRATIONS,
    SUM(CASE WHEN ACTIVATION_RATE_30D IS NULL THEN 1 ELSE 0 END) AS NULL_ACTIVATION_RATE,
    SUM(CASE WHEN AVG_LOGINS_PER_MAU IS NULL THEN 1 ELSE 0 END) AS NULL_AVG_LOGINS,
    SUM(CASE WHEN POS_USERS_SHARE IS NULL THEN 1 ELSE 0 END) AS NULL_POS_SHARE,
    SUM(CASE WHEN P2P_USERS_SHARE IS NULL THEN 1 ELSE 0 END) AS NULL_P2P_SHARE,
    SUM(CASE WHEN INACTIVE_90D_SHARE IS NULL THEN 1 ELSE 0 END) AS NULL_INACTIVE_SHARE
FROM MONTHLY_KPI;


--============================================
25. MONTHLY_KPI – Whole Number Validation
--============================================

SELECT
    SUM(CASE
        WHEN MAU <> TRUNC(MAU)
        THEN 1 ELSE 0
    END) AS DECIMAL_MAU,

    SUM(CASE
        WHEN NEW_REGISTRATIONS <> TRUNC(NEW_REGISTRATIONS)
        THEN 1 ELSE 0
    END) AS DECIMAL_NEW_REGISTRATIONS

FROM MONTHLY_KPI;