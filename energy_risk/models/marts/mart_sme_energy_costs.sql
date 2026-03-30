{{
  config(
    materialized = "table",
    partition_by = {
      "field": "ts_utc",
      "data_type": "timestamp",
      "granularity": "month"
    },
    cluster_by = ["price_zone", "segment"]
  )
}}

with prices as (
    select
        ts_utc,
        price_zone,
        price_eur_mwh,
        -- price in EUR/kWh
        price_eur_mwh / 1000.0 as price_eur_kwh
    from {{ ref('stg_opsd_prices') }}
),

sme as (
    select
        segment,
        segment_size,
        industry,
        avg_kwh_per_day,
        energy_cost_share,
        base_margin_pct
    from {{ ref('sme_energy_profile') }}
),

daily_costs as (
    select
        p.ts_utc,
        date(p.ts_utc) as date,
        p.price_zone,
        s.segment,
        s.segment_size,
        s.industry,
        s.avg_kwh_per_day,
        s.base_margin_pct,
        s.energy_cost_share,
        -- daily energy cost
        s.avg_kwh_per_day * p.price_eur_kwh as energy_cost_eur,
        -- approximate total cost (assuming energy_cost_share is the share of total costs)
        (s.avg_kwh_per_day * p.price_eur_kwh) / s.energy_cost_share as total_cost_eur,
        -- approximate revenue given base margin
        (( (s.avg_kwh_per_day * p.price_eur_kwh) / s.energy_cost_share ) / (1 - s.base_margin_pct)) as revenue_eur,
        -- simplified gross profit
        (
          (( (s.avg_kwh_per_day * p.price_eur_kwh) / s.energy_cost_share ) / (1 - s.base_margin_pct))
          - (s.avg_kwh_per_day * p.price_eur_kwh) / s.energy_cost_share
        ) as gross_profit_eur
    from prices p
    cross join sme s
)

select * from daily_costs