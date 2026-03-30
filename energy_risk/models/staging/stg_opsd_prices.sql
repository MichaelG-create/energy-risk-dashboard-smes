with src as (
    select
        utc_timestamp,
        AT_price_day_ahead
    from `{{ env_var('PROJECT_ID') }}`.`{{ env_var('DATASET_ID') }}`.raw_energy_prices_ext
    where AT_price_day_ahead is not null
),

renamed as (
    select
        utc_timestamp as ts_utc,
        'AT' as country_code,
        AT_price_day_ahead as price_eur_mwh
    from src
)

select * from renamed