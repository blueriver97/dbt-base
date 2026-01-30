--
-- Superset Dynamic SQL Example
-- Description: Apache Superset에서 사용 가능한 동적 SQL 예제
-- 필터링 조건을 동적으로 쿼리에 반영하여 SQL 생성 및 조회 가능
--    - company_seq: 회사 시퀀스
--    - sub_company_seq: 계열사 시퀀스
--    - year: 연도
--    - quarter: 분기
--    - month: 월
--
-- Usage:
-- 1. ENABLE_TEMPLATE_PROCESSING 옵션 활성화
-- 2. Superset 대시보드에서 필터 설정
-- 3. SQLLab 화면에서 필터 이름에 대한 값을 가져와 Jinja Template의 렌더링 과정을 거쳐 최종 SQL을 조립
-- WHERE 1=1 구문은 동적 쿼리 생성을 위한 기본 조건
-- 필터값이 없는 경우 Error type으로 처리

{% set _company_seq = filter_values('company_seq') %}
{% set _sub_company_seq = filter_values('sub_company_seq') %}
{% set _year = filter_values('year') %}
{% set _quarter = filter_values('quarter') %}
{% set _month = filter_values('month') %}

SELECT
    {% if _year and _quarter and _month %}
        monthly_users AS value,
        monthly_study_sec AS study_sec,
        monthly_answer AS answer,
        'Monthly' AS type
    {% elif _year and _quarter %}
        quarter_users AS value,
        quarter_study_sec AS study_sec,
        quarter_answer AS answer,
        'Quarterly' AS type
    {% elif _year %}
        year_users AS value,
        year_study_sec AS study_sec,
        year_answer AS answer,
        'Yearly' AS type
    {% else %}
        NULL AS value,
        NULL AS study_sec,
        NULL AS answer,
        'Error' AS type
    {% endif %}
FROM mart_gold.stats_study_history
WHERE 1=1
    -- 필터 값이 있을 때만 IN 절 생성
    {% if _company_seq %}
        AND company_seq IN ( {{ _company_seq | join(", ") }} )
    {% endif %}

    {% if _sub_company_seq %}
        AND sub_company_seq IN ( {{ _sub_company_seq | join(", ") }} )
    {% endif %}

    {% if _year %}
        AND year IN ( {{ _year | join(", ") }} )
    {% endif %}

    {% if _year and _quarter %}
        AND quarter IN ( {{ _quarter | join(", ") }} )
    {% endif %}

    {% if _year and _quarter and _month %}
        AND month IN ( {{ _month | join(", ") }} )
    {% endif %}
