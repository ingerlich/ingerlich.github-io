use mavenfuzzyfactory; 
-- Yêu cầu 1
select 
    year(ws.created_at) as yr,
	quarter(ws.created_at) as qtr, 
	count(distinct ws.website_session_id) as sessions, 
    count(distinct orders.order_id) as orders
from website_sessions as ws
	left join orders using (website_session_id)
group by 1,2
order by 1,2 asc;

-- Yêu cầu 2
select 
	year(ws.created_at) as yr, 
    quarter(ws.created_at) as qtr, 
	count(distinct orders.order_id)/count(distinct ws.website_session_id) as session_to_order_conv_rate, 
    sum(orders.price_usd) / count(distinct orders.order_id) as revenue_per_order,
	sum(orders.price_usd) / count(distinct ws.website_session_id) as revenue_per_session
from website_sessions as ws
	left join orders using (website_session_id)
group by 1,2
order by 1,2 asc;

-- Yêu cầu 3
select 
	year(ws.created_at) as yr, 
	quarter(ws.created_at) as qtr, 
	count(if(utm_source = 'gsearch' and utm_campaign = 'nonbrand', order_id, null)) as gsearch_nonbrand_orders,
	count(if(utm_source = 'bsearch' and utm_campaign = 'nonbrand', order_id, null)) as bsearch_nonbrand_orders,
	count(if(utm_campaign = 'brand', order_id, null)) as brand_search_orders,
	count(if(utm_source is null and http_referer is not null, order_id, null)) as organic_type_in_orders,
	count(if(utm_source is null and http_referer is null, order_id, null)) as direct_type_in_orders
from website_sessions as ws
	left join orders using(website_session_id)
group by 1,2;

-- Yêu cầu 4
select 
	year(ws.created_at) as yr, 
	quarter(ws.created_at) as qtr, 
	count(if(utm_source = 'gsearch' and utm_campaign = 'nonbrand', order_id, null)) / count(if(utm_source = 'gsearch' and utm_campaign = 'nonbrand', website_session_id, null)) as gsearch_nonbrand_conv_rt,
	count(if(utm_source = 'bsearch' and utm_campaign = 'nonbrand', order_id, null)) / count(if(utm_source = 'bsearch' and utm_campaign = 'nonbrand', website_session_id, null)) as bsearch_nonbrand_conv_rt,
	count(if(utm_campaign = 'brand', order_id, null)) / count(if(utm_campaign = 'brand', website_session_id, null)) as brand_search_conv_rt,
	count(if(utm_source is null and http_referer is not null, order_id, null)) / count(if(utm_source is null and http_referer is not null, website_session_id, null)) as organic_search_conv_rt,
	count(if(utm_source is null and http_referer is null, order_id, null)) / count(if(utm_source is null and http_referer is null, website_session_id, null)) as direct_type_in_conv_rt
from website_sessions as ws
	left join orders using(website_session_id)
group by 1,2;

-- Yêu cầu 5
select
	year(created_at) as yr, 
    month(created_at) as mo,
	sum(if(product_id = 1, price_usd,null)) as mrfuzzy_rev,
    sum(if(product_id = 1, price_usd-cogs_usd,null)) as mrfuzzy_marg,
	sum(if(product_id = 2, price_usd,null)) as lovebear_rev,
    sum(if(product_id = 2, price_usd-cogs_usd,null)) as lovebear_marg,
	sum(if(product_id = 3, price_usd,null)) as birthdaybear_rev,
    sum(if(product_id = 3, price_usd-cogs_usd,null)) as birthdaybear_marg,
	sum(if(product_id = 4, price_usd,null)) as minibear_rev,
    sum(if(product_id = 4, price_usd-cogs_usd,null)) as minibear_marg,
    sum(price_usd) as total_revenue,
    sum(price_usd - cogs_usd) as total_margin
from order_items
group by 1,2;

-- Yêu cầu 6
create temporary table product_sessions
select
	created_at,
    website_session_id,
    website_pageview_id
from website_pageviews
	where pageview_url = '/products'
group by 1,2,3;

select
	year(product_sessions.created_at) as yr, 
    month(product_sessions.created_at) as mo,
    count(distinct product_sessions.website_session_id) as sessions_to_product_page,
    count(distinct website_pageviews.website_session_id) as click_to_next,
    count(distinct website_pageviews.website_session_id) / count(distinct product_sessions.website_session_id) as clickthrough_rt,
    count(if(pageview_url = '/thank-you-for-your-order', 1, null)) as orders,
    count(if(pageview_url = '/thank-you-for-your-order', 1, null)) / count(distinct product_sessions.website_session_id) as products_to_order_rt
from product_sessions
	left join website_pageviews 
		on website_pageviews.website_session_id = product_sessions.website_session_id 
		and website_pageviews.website_pageview_id > product_sessions.website_pageview_id
group by 1,2;

-- Yêu cầu 7
select primary_product_id, 
	count(distinct orders.order_id) as total_orders,
    count(if(product_id = 1 and is_primary_item = 0, orders.order_id, null)) as _xsold_p1,
    count(if(product_id = 2 and is_primary_item = 0, orders.order_id, null)) as _xsold_p2,
    count(if(product_id = 3 and is_primary_item = 0, orders.order_id, null)) as _xsold_p3,
    count(if(product_id = 4 and is_primary_item = 0, orders.order_id, null)) as _xsold_p4,
	count(if(product_id = 1 and is_primary_item = 0, orders.order_id, null)) / count(distinct orders.order_id) as p1_sell_rt, 
    count(if(product_id = 2 and is_primary_item = 0, orders.order_id, null)) / count(distinct orders.order_id) as p2_sell_rt, 
    count(if(product_id = 3 and is_primary_item = 0, orders.order_id, null)) / count(distinct orders.order_id) as p3_sell_rt, 
    count(if(product_id = 4 and is_primary_item = 0, orders.order_id, null)) / count(distinct orders.order_id) as p4_sell_rt
from order_items
	left join orders
		on order_items.order_id = orders.order_id
where orders.created_at > '2014-12-05'
group by 1;

