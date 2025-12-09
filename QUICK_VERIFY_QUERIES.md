# Quick Verification Queries for Estimate to Rating Workflow

## Booking Details
- **Booking ID**: `12663430-6b99-4de6-8a53-fb1e7adb639e`
- **Professional ID**: `VZ2bAvAX0ThZ4QArKwhDnD37u652`
- **Customer ID**: `WhprgUxoPvU9nDTiQE3Hkj5PD1u1`
- **Rating**: 4
- **PostgreSQL Review ID**: `add19376-df4a-42f5-b5c2-539b16093f53`

---

## 🔍 Quick Verification Queries

### 1. Check if Review Was Created
```sql
SELECT * 
FROM reviews 
WHERE booking_id = '12663430-6b99-4de6-8a53-fb1e7adb639e';
```

### 2. Verify Review by PostgreSQL ID
```sql
SELECT * 
FROM reviews 
WHERE id = 'add19376-df4a-42f5-b5c2-539b16093f53';
```

### 3. Check Booking Status
```sql
SELECT 
    id,
    status,
    agreed_price,
    currency,
    job_started_at,
    job_completed_at,
    job_accepted_at
FROM bookings 
WHERE id = '12663430-6b99-4de6-8a53-fb1e7adb639e';
```

### 4. Verify All Reviews for This Booking
```sql
SELECT 
    r.*,
    CASE 
        WHEN r.reviewer_id = 'VZ2bAvAX0ThZ4QArKwhDnD37u652' THEN 'Professional Review'
        WHEN r.reviewer_id = 'WhprgUxoPvU9nDTiQE3Hkj5PD1u1' THEN 'Customer Review'
        ELSE 'Unknown'
    END as review_type
FROM reviews r
WHERE r.booking_id = '12663430-6b99-4de6-8a53-fb1e7adb639e';
```

### 5. Check Payment Confirmation
```sql
SELECT * 
FROM payment_confirmations 
WHERE booking_id = '12663430-6b99-4de6-8a53-fb1e7adb639e';
```

### 6. Complete Workflow Summary
```sql
SELECT 
    b.id,
    b.status,
    b.agreed_price,
    b.currency,
    b.job_completed_at,
    b.job_accepted_at,
    CASE WHEN pc.booking_id IS NOT NULL THEN 'Yes' ELSE 'No' END as payment_confirmed,
    COUNT(r.id) as review_count,
    MAX(CASE WHEN r.reviewer_id = b.professional_id THEN r.rating END) as professional_rating
FROM bookings b
LEFT JOIN payment_confirmations pc ON b.id = pc.booking_id
LEFT JOIN reviews r ON b.id = r.booking_id
WHERE b.id = '12663430-6b99-4de6-8a53-fb1e7adb639e'
GROUP BY b.id, b.status, b.agreed_price, b.currency, 
         b.job_completed_at, b.job_accepted_at, pc.booking_id;
```

---

## 📊 Expected Results

Based on your logs, you should see:

1. **Review Record**: 
   - `reviewer_id` = `VZ2bAvAX0ThZ4QArKwhDnD37u652` (Professional)
   - `reviewee_id` = `WhprgUxoPvU9nDTiQE3Hkj5PD1u1` (Customer)
   - `rating` = `4`
   - `booking_id` = `12663430-6b99-4de6-8a53-fb1e7adb639e`

2. **Booking Status**: 
   - Should be `completed` or `reviewed` (depending on workflow stage)

3. **Payment Confirmation**: 
   - May or may not exist depending on when payment was confirmed

---

## 🚀 How to Run in Supabase

1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor**
3. Copy and paste any of the queries above
4. Click **Run** to execute
5. Review the results

---

## 📝 Notes

- All queries use the booking ID from your logs
- The review should have been created with rating 4
- The professional (VZ2bAvAX0ThZ4QArKwhDnD37u652) reviewed the customer (WhprgUxoPvU9nDTiQE3Hkj5PD1u1)
- Check the `created_at` timestamp to verify when the review was submitted

