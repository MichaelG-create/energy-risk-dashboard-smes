with prices as (
    select
        ts_utc,
        country_code,
        price_eur_mwh,
        -- prix en EUR/kWh
        price_eur_mwh / 1000.0 as price_eur_kwh
    from {{ ref('stg_opsd_prices') }}
),

sme as (
    select * from {{ ref('sme_energy_profile') }}
),

daily_costs as (
    select
        date(ts_utc) as date,
        p.country_code,
        s.segment,
        s.avg_kwh_per_day,
        s.base_margin_pct,
        s.energy_cost_share,
        -- coût énergie quotidien
        s.avg_kwh_per_day * p.price_eur_kwh as energy_cost_eur,
        -- revenu approximatif (en supposant que l'énergie représente energy_cost_share des coûts)
        (s.avg_kwh_per_day * p.price_eur_kwh) / s.energy_cost_share as total_cost_eur,
        (( (s.avg_kwh_per_day * p.price_eur_kwh) / s.energy_cost_share ) / (1 - s.base_margin_pct)) as revenue_eur,
        -- profit brut simplifié
        (
          (( (s.avg_kwh_per_day * p.price_eur_kwh) / s.energy_cost_share ) / (1 - s.base_margin_pct))
          - (s.avg_kwh_per_day * p.price_eur_kwh) / s.energy_cost_share
        ) as gross_profit_eur
    from prices p
    cross join sme s
)

select * from daily_costs