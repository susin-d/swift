CREATE OR REPLACE VIEW public.spending_summary AS
SELECT
  o.user_id,
  o.vendor_id,
  v.name AS vendor_name,
  DATE_TRUNC('month', o.created_at) AS month,
  SUM(o.total_amount - COALESCE(o.discount_amount, 0)) AS net_spent,
  COUNT(*) AS order_count
FROM public.orders o
JOIN public.vendors v ON v.id = o.vendor_id
WHERE o.status = 'completed'
GROUP BY o.user_id, o.vendor_id, v.name, DATE_TRUNC('month', o.created_at);
