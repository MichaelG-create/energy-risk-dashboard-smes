with src as (
    select
        utc_timestamp,
        AT_price_day_ahead,
        DE_price_day_ahead,
        DE_AT_LU_price_day_ahead,
        DE_LU_price_day_ahead,
        DK_1_price_day_ahead,
        DK_2_price_day_ahead,
        GB_GBN_price_day_ahead,
        IE_sem_price_day_ahead,
        IT_BRNN_price_day_ahead,
        IT_CNOR_price_day_ahead,
        IT_CSUD_price_day_ahead,
        IT_FOGN_price_day_ahead,
        IT_GR_price_day_ahead,
        IT_NORD_price_day_ahead,
        IT_NORD_AT_price_day_ahead,
        IT_NORD_CH_price_day_ahead,
        IT_NORD_FR_price_day_ahead,
        IT_NORD_SI_price_day_ahead,
        IT_PRGP_price_day_ahead,
        IT_ROSN_price_day_ahead,
        IT_SACO_AC_price_day_ahead,
        IT_SACO_DC_price_day_ahead,
        IT_SARD_price_day_ahead,
        IT_SICI_price_day_ahead,
        IT_SUD_price_day_ahead,
        NO_1_price_day_ahead,
        NO_2_price_day_ahead,
        NO_3_price_day_ahead,
        NO_4_price_day_ahead,
        NO_5_price_day_ahead,
        SE_price_day_ahead,
        SE_1_price_day_ahead,
        SE_2_price_day_ahead,
        SE_3_price_day_ahead,
        SE_4_price_day_ahead
    from {{ source('energy_risk_raw', 'raw_energy_prices_ext') }}
),

unioned as (

    select
        utc_timestamp as ts_utc,
        'AT' as price_zone,
        cast(AT_price_day_ahead as float64) as price_eur_mwh
    from src
    where AT_price_day_ahead is not null

    union all

    select
        utc_timestamp as ts_utc,
        'DE' as price_zone,
        cast(DE_price_day_ahead as float64) as price_eur_mwh
    from src
    where DE_price_day_ahead is not null

    union all

    select
        utc_timestamp as ts_utc,
        'DE_AT_LU' as price_zone,
        cast(DE_AT_LU_price_day_ahead as float64) as price_eur_mwh
    from src
    where DE_AT_LU_price_day_ahead is not null

    union all

    select
        utc_timestamp as ts_utc,
        'DE_LU' as price_zone,
        cast(DE_LU_price_day_ahead as float64) as price_eur_mwh
    from src
    where DE_LU_price_day_ahead is not null

    union all

    select
        utc_timestamp as ts_utc,
        'DK_1' as price_zone,
        cast(DK_1_price_day_ahead as float64) as price_eur_mwh
    from src
    where DK_1_price_day_ahead is not null

    union all

    select
        utc_timestamp as ts_utc,
        'DK_2' as price_zone,
        cast(DK_2_price_day_ahead as float64) as price_eur_mwh
    from src
    where DK_2_price_day_ahead is not null

    union all

    select
        utc_timestamp as ts_utc,
        'GB_GBN' as price_zone,
        cast(GB_GBN_price_day_ahead as float64) as price_eur_mwh
    from src
    where GB_GBN_price_day_ahead is not null

    union all

    select
        utc_timestamp as ts_utc,
        'IE_SEM' as price_zone,
        cast(IE_sem_price_day_ahead as float64) as price_eur_mwh
    from src
    where IE_sem_price_day_ahead is not null

    union all

    select
        utc_timestamp as ts_utc,
        'IT_BRNN' as price_zone,
        cast(IT_BRNN_price_day_ahead as float64) as price_eur_mwh
    from src
    where IT_BRNN_price_day_ahead is not null

    union all

    select
        utc_timestamp as ts_utc,
        'IT_CNOR' as price_zone,
        cast(IT_CNOR_price_day_ahead as float64) as price_eur_mwh
    from src
    where IT_CNOR_price_day_ahead is not null

    union all

    select
        utc_timestamp as ts_utc,
        'IT_CSUD' as price_zone,
        cast(IT_CSUD_price_day_ahead as float64) as price_eur_mwh
    from src
    where IT_CSUD_price_day_ahead is not null

    union all

    select
        utc_timestamp as ts_utc,
        'IT_FOGN' as price_zone,
        cast(IT_FOGN_price_day_ahead as float64) as price_eur_mwh
    from src
    where IT_FOGN_price_day_ahead is not null

    union all

    select
        utc_timestamp as ts_utc,
        'IT_GR' as price_zone,
        cast(IT_GR_price_day_ahead as float64) as price_eur_mwh
    from src
    where IT_GR_price_day_ahead is not null

    union all

    select
        utc_timestamp as ts_utc,
        'IT_NORD' as price_zone,
        cast(IT_NORD_price_day_ahead as float64) as price_eur_mwh
    from src
    where IT_NORD_price_day_ahead is not null

    union all

    select
        utc_timestamp as ts_utc,
        'IT_NORD_AT' as price_zone,
        cast(IT_NORD_AT_price_day_ahead as float64) as price_eur_mwh
    from src
    where IT_NORD_AT_price_day_ahead is not null

    union all

    select
        utc_timestamp as ts_utc,
        'IT_NORD_CH' as price_zone,
        cast(IT_NORD_CH_price_day_ahead as float64) as price_eur_mwh
    from src
    where IT_NORD_CH_price_day_ahead is not null

    union all

    select
        utc_timestamp as ts_utc,
        'IT_NORD_FR' as price_zone,
        cast(IT_NORD_FR_price_day_ahead as float64) as price_eur_mwh
    from src
    where IT_NORD_FR_price_day_ahead is not null

    union all

    select
        utc_timestamp as ts_utc,
        'IT_NORD_SI' as price_zone,
        cast(IT_NORD_SI_price_day_ahead as float64) as price_eur_mwh
    from src
    where IT_NORD_SI_price_day_ahead is not null

    union all

    select
        utc_timestamp as ts_utc,
        'IT_PRGP' as price_zone,
        cast(IT_PRGP_price_day_ahead as float64) as price_eur_mwh
    from src
    where IT_PRGP_price_day_ahead is not null

    union all

    select
        utc_timestamp as ts_utc,
        'IT_ROSN' as price_zone,
        cast(IT_ROSN_price_day_ahead as float64) as price_eur_mwh
    from src
    where IT_ROSN_price_day_ahead is not null

    union all

    select
        utc_timestamp as ts_utc,
        'IT_SACO_AC' as price_zone,
        cast(IT_SACO_AC_price_day_ahead as float64) as price_eur_mwh
    from src
    where IT_SACO_AC_price_day_ahead is not null

    union all

    select
        utc_timestamp as ts_utc,
        'IT_SACO_DC' as price_zone,
        cast(IT_SACO_DC_price_day_ahead as float64) as price_eur_mwh
    from src
    where IT_SACO_DC_price_day_ahead is not null

    union all

    select
        utc_timestamp as ts_utc,
        'IT_SARD' as price_zone,
        cast(IT_SARD_price_day_ahead as float64) as price_eur_mwh
    from src
    where IT_SARD_price_day_ahead is not null

    union all

    select
        utc_timestamp as ts_utc,
        'IT_SICI' as price_zone,
        cast(IT_SICI_price_day_ahead as float64) as price_eur_mwh
    from src
    where IT_SICI_price_day_ahead is not null

    union all

    select
        utc_timestamp as ts_utc,
        'IT_SUD' as price_zone,
        cast(IT_SUD_price_day_ahead as float64) as price_eur_mwh
    from src
    where IT_SUD_price_day_ahead is not null

    union all

    select
        utc_timestamp as ts_utc,
        'NO_1' as price_zone,
        cast(NO_1_price_day_ahead as float64) as price_eur_mwh
    from src
    where NO_1_price_day_ahead is not null

    union all

    select
        utc_timestamp as ts_utc,
        'NO_2' as price_zone,
        cast(NO_2_price_day_ahead as float64) as price_eur_mwh
    from src
    where NO_2_price_day_ahead is not null

    union all

    select
        utc_timestamp as ts_utc,
        'NO_3' as price_zone,
        cast(NO_3_price_day_ahead as float64) as price_eur_mwh
    from src
    where NO_3_price_day_ahead is not null

    union all

    select
        utc_timestamp as ts_utc,
        'NO_4' as price_zone,
        cast(NO_4_price_day_ahead as float64) as price_eur_mwh
    from src
    where NO_4_price_day_ahead is not null

    union all

    select
        utc_timestamp as ts_utc,
        'NO_5' as price_zone,
        cast(NO_5_price_day_ahead as float64) as price_eur_mwh
    from src
    where NO_5_price_day_ahead is not null

    union all

    select
        utc_timestamp as ts_utc,
        'SE' as price_zone,
        cast(SE_price_day_ahead as float64) as price_eur_mwh
    from src
    where SE_price_day_ahead is not null

    union all

    select
        utc_timestamp as ts_utc,
        'SE_1' as price_zone,
        cast(SE_1_price_day_ahead as float64) as price_eur_mwh
    from src
    where SE_1_price_day_ahead is not null

    union all

    select
        utc_timestamp as ts_utc,
        'SE_2' as price_zone,
        cast(SE_2_price_day_ahead as float64) as price_eur_mwh
    from src
    where SE_2_price_day_ahead is not null

    union all

    select
        utc_timestamp as ts_utc,
        'SE_3' as price_zone,
        cast(SE_3_price_day_ahead as float64) as price_eur_mwh
    from src
    where SE_3_price_day_ahead is not null

    union all

    select
        utc_timestamp as ts_utc,
        'SE_4' as price_zone,
        cast(SE_4_price_day_ahead as float64) as price_eur_mwh
    from src
    where SE_4_price_day_ahead is not null
)

select * from unioned