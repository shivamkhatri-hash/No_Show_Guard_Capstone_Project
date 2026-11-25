-- ============================================================================
-- Task 2.1 – Verification & Duplicate Primary Key Test
-- ============================================================================
SELECT COUNT(*) AS clinic_count FROM clinics;
SELECT COUNT(*) AS appointment_count FROM appointments;
SELECT SUM(no_show) AS total_no_shows FROM appointments;

-- Duplicate primary key test (expected to fail with duplicate-key / UNIQUE constraint error)
INSERT INTO appointments VALUES (
  'A0001','P509','C05','2025-01-24','2025-01-25',60,'F',18.0,850,
  'Phone','Consultation','Yes',1,'No-Show',1,1
);
