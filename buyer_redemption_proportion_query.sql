-- how often do SC Johnson buyers user coupons?
-- table of buyers of SC Johnson stuff who have also activated SC Johnson coupons in last year

drop table if exists cdw_research_tempdb.save_jh_scjohnson_buyeractivators;

create table cdw_research_tempdb.save_jh_scjohnson_buyeractivators as

select
distinct user_sid
from

(select 
slf.user_sid

from sales_line_fact slf
join qt_product_dim pd
on slf.ci_product_sid = pd.qt_product_sid

where identified_user = 'Identified'
and slf.partner_code = 'Safeway'
and pd.manufacturer_name = 'S. C. Johnson & Son Inc'
and transaction_date_id between 20180101 and 20190101) purchasers

join

(select
daf.user_sid

from daily_activation_fact daf
join offer_dim od
on daf.coupon_sid = od.coupon_sid
join offer_company_dim co
on od.manufacturer_sid = co.company_sid

where upper(co.company_name) like 'S.C. JOHNSON%'
and activation_date_id between 20180101 and 20190101
and ci_pid in (select ci_pid from riq_pidlist where partner_code = 'Safeway')
) activators

on purchasers.user_sid = activators.user_sid

;

-- of these buyers... how many redemptions? how many distinct purchases? Created the tables


-- distinct purchases
--1969626

select
count(distinct transaction_id)

from sales_line_fact slf
join qt_product_dim pd
on slf.ci_product_sid = pd.qt_product_sid
join cdw_research_tempdb.save_jh_scjohnson_buyeractivators ba  -- only users who have both activated a SCJ coupon and purchased
on slf.user_sid = ba.user_sid

where identified_user = 'Identified'
and slf.partner_code = 'Safeway'
and pd.manufacturer_name = 'S. C. Johnson & Son Inc'
and transaction_date_id between 20180101 and 20190101
;


-- redemptions
-- 202379

select
count(*)

from
daily_redemption_fact drf
join offer_dim od
on drf.coupon_sid = od.coupon_sid
join offer_company_dim co
on od.manufacturer_sid = co.company_sid
join cdw_research_tempdb.save_jh_scjohnson_buyeractivators ba  -- only users who have both activated a SCJ coupon and purchased
on drf.user_sid = ba.user_sid

where upper(co.company_name) like 'S.C. JOHNSON%'
and scan_date_id between 20180101 and 20190101
and ci_pid in (select ci_pid from riq_pidlist where partner_code = 'Safeway');


--overall number: 10%, next step would be to look at a distribution of customers

select t1.user_sid, trips, redemptions, redemptions/trips from

(select
slf.user_sid,
count(distinct transaction_id) trips

from sales_line_fact slf
join qt_product_dim pd
on slf.ci_product_sid = pd.qt_product_sid
join cdw_research_tempdb.save_jh_scjohnson_buyeractivators ba  -- only users who have both activated a SCJ coupon and purchased
on slf.user_sid = ba.user_sid

where identified_user = 'Identified'
and slf.partner_code = 'Safeway'
and pd.manufacturer_name = 'S. C. Johnson & Son Inc'
and transaction_date_id between 20180101 and 20190101
group by 1) t1

join

(select
drf.user_sid,
count(*) redemptions

from
daily_redemption_fact drf
join offer_dim od
on drf.coupon_sid = od.coupon_sid
join offer_company_dim co
on od.manufacturer_sid = co.company_sid
join cdw_research_tempdb.save_jh_scjohnson_buyeractivators ba  -- only users who have both activated a SCJ coupon and purchased
on drf.user_sid = ba.user_sid

where upper(co.company_name) like 'S.C. JOHNSON%'
and scan_date_id between 20180101 and 20190101
and ci_pid in (select ci_pid from riq_pidlist where partner_code = 'Safeway')
group by 1) t2

on t1.user_sid = t2.user_sid
;

-- join this by user sid to the other table so that we have count of transactions and count of redemptions in the same table and then can see a distribution
