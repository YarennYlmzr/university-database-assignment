/*
===============================================================================
ÖDEV 2 - CONSTRAINT TESTLERİ, ON DELETE VE İLİŞKİSEL CEBİR
Proje: Üniversite Öğrenci ve Ders Kayıt Sistemi
DBMS: PostgreSQL

ÖN KOŞUL
--------
Önce 01_odev1.sql dosyasını aynı veritabanında çalıştırmış olmalısınız.
Bu dosya Ödev 1'de oluşturulan tabloları kullanır.

ÇALIŞTIRMA
----------
pgAdmin 4 -> aynı veritabanı -> Query Tool -> bu dosyayı açıp çalıştırın.

ÖNEMLİ
------
Constraint ihlali testleri DO blokları içinde yakalanır. Böylece beklenen
hatalar tüm betiğin çalışmasını durdurmaz. Her testte SQLSTATE (PostgreSQL
hata kodu) ekrana NOTICE olarak yazdırılır.

ON DELETE testleri bir transaction içinde yapılır ve en sonunda ROLLBACK
uygulanır. Böylece silme davranışları gösterilir, fakat örnek veriler
kalıcı olarak silinmez.
===============================================================================
*/

-- ============================================================================
-- BÖLÜM 1: ÖRNEK VERİLER
-- ============================================================================
-- Bu INSERT'ler boş tablolar için hazırlanmıştır. Aynı verileri ikinci kez
-- eklememek için dosyayı normalde bir kez çalıştırın.

INSERT INTO Department (department_name)
VALUES
    ('Management Information Systems'),
    ('Computer Engineering');

INSERT INTO Student
    (student_no, first_name, last_name, email,
     enrollment_year, department_id)
VALUES
    ('2026001', 'Ayse', 'Yilmaz', 'ayse@example.com', 2026, 1),
    ('2026002', 'Mehmet', 'Demir', 'mehmet@example.com', 2026, 1),
    ('2025003', 'Zeynep', 'Kaya', 'zeynep@example.com', 2025, 2);

INSERT INTO Instructor
    (first_name, last_name, email, department_id)
VALUES
    ('Ahmet', 'Can', 'ahmet@example.com', 1),
    ('Elif', 'Aydin', 'elif@example.com', 2);

INSERT INTO Course
    (course_code, course_name, credits, department_id)
VALUES
    ('BIM381', 'Database Systems', 4, 1),
    ('BIM201', 'Programming', 3, 1),
    ('CENG101', 'Introduction to Computing', 4, 2);

INSERT INTO Section
    (course_id, instructor_id, term, academic_year, section_no, capacity)
VALUES
    (1, 1, 'Fall', 2026, 1, 40),
    (2, 1, 'Fall', 2026, 1, 35),
    (3, 2, 'Spring', 2027, 1, 30);

INSERT INTO Enrollment (student_id, section_id, grade)
VALUES
    (1, 1, 85),
    (2, 1, 90),
    (1, 2, 75),
    (3, 3, 95);

-- Örnek kayıtları görüntüle.
SELECT * FROM Department ORDER BY department_id;
SELECT * FROM Student ORDER BY student_id;
SELECT * FROM Instructor ORDER BY instructor_id;
SELECT * FROM Course ORDER BY course_id;
SELECT * FROM Section ORDER BY section_id;
SELECT * FROM Enrollment ORDER BY enrollment_id;

-- ============================================================================
-- BÖLÜM 2: CONSTRAINT İHLAL TESTLERİ
-- ============================================================================
-- Beklenen SQLSTATE kodları:
-- 23505 = unique_violation
-- 23503 = foreign_key_violation
-- 23502 = not_null_violation
-- 23514 = check_violation
--
-- Her DO bloğunda hata yakalanır. "Beklenen hata" mesajı doğru test
-- davranışını gösterir. "TEST BAŞARISIZ" mesajı ise kısıtın çalışmadığını
-- gösterir.

-- TEST 1: UNIQUE - Aynı student_no tekrar eklenemez.
DO $$
BEGIN
    INSERT INTO Student
        (student_no, first_name, last_name, email,
         enrollment_year, department_id)
    VALUES
        ('2026001', 'Ali', 'Yilmaz',
         'ali_test@example.com', 2026, 1);

    RAISE NOTICE 'TEST BAŞARISIZ: UNIQUE kısıtı ihlal edilmedi.';
EXCEPTION WHEN unique_violation THEN
    RAISE NOTICE 'BEKLENEN HATA: SQLSTATE %, UNIQUE ihlali.', SQLSTATE;
END $$;

-- TEST 2: FOREIGN KEY - Var olmayan department_id kullanılamaz.
DO $$
BEGIN
    INSERT INTO Student
        (student_no, first_name, last_name, email,
         enrollment_year, department_id)
    VALUES
        ('2099001', 'Veli', 'Demir',
         'veli_test@example.com', 2026, 9999);

    RAISE NOTICE 'TEST BAŞARISIZ: FOREIGN KEY kısıtı ihlal edilmedi.';
EXCEPTION WHEN foreign_key_violation THEN
    RAISE NOTICE 'BEKLENEN HATA: SQLSTATE %, FOREIGN KEY ihlali.', SQLSTATE;
END $$;

-- TEST 3: NOT NULL - first_name boş bırakılamaz.
DO $$
BEGIN
    INSERT INTO Student
        (student_no, first_name, last_name, email,
         enrollment_year, department_id)
    VALUES
        ('2099002', NULL, 'Kaya',
         'null_test@example.com', 2026, 1);

    RAISE NOTICE 'TEST BAŞARISIZ: NOT NULL kısıtı ihlal edilmedi.';
EXCEPTION WHEN not_null_violation THEN
    RAISE NOTICE 'BEKLENEN HATA: SQLSTATE %, NOT NULL ihlali.', SQLSTATE;
END $$;

-- TEST 4: CHECK - Ders kredisi 1 ile 10 arasında olmalıdır.
DO $$
BEGIN
    INSERT INTO Course
        (course_code, course_name, credits, department_id)
    VALUES
        ('TEST999', 'Invalid Credits Course', -2, 1);

    RAISE NOTICE 'TEST BAŞARISIZ: CHECK kısıtı ihlal edilmedi.';
EXCEPTION WHEN check_violation THEN
    RAISE NOTICE 'BEKLENEN HATA: SQLSTATE %, CHECK ihlali.', SQLSTATE;
END $$;

-- ============================================================================
-- BÖLÜM 3: ON DELETE DAVRANIŞLARININ TEST EDİLMESİ
-- ============================================================================
-- Bu testler transaction içinde yapılır. En sondaki ROLLBACK nedeniyle
-- örnek veriler kalıcı olarak değişmez.

BEGIN;

-- TEST A: ON DELETE CASCADE
-- Öğrenci silinince Enrollment tablosundaki ilgili kayıtlar da silinmelidir.
DO $$
DECLARE
    v_student_id INTEGER;
    v_before INTEGER;
    v_after INTEGER;
BEGIN
    SELECT student_id INTO v_student_id
    FROM Student WHERE student_no = '2026002';

    SELECT COUNT(*) INTO v_before
    FROM Enrollment WHERE student_id = v_student_id;

    DELETE FROM Student WHERE student_id = v_student_id;

    SELECT COUNT(*) INTO v_after
    FROM Enrollment WHERE student_id = v_student_id;

    RAISE NOTICE 'CASCADE: Önce kayıt sayısı %, sonra kayıt sayısı %.',
        v_before, v_after;
END $$;

-- TEST B: ON DELETE SET NULL
-- Öğretim elemanı silinince Section satırı kalmalı ve instructor_id NULL olmalı.
DO $$
DECLARE
    v_instructor_id INTEGER;
    v_null_count INTEGER;
BEGIN
    SELECT instructor_id INTO v_instructor_id
    FROM Instructor WHERE email = 'ahmet@example.com';

    DELETE FROM Instructor WHERE instructor_id = v_instructor_id;

    SELECT COUNT(*) INTO v_null_count
    FROM Section
    WHERE instructor_id IS NULL
      AND course_id IN (1, 2);

    RAISE NOTICE 'SET NULL: instructor_id NULL olan ilgili şube sayısı %.',
        v_null_count;
END $$;

-- TEST C: ON DELETE RESTRICT
-- İlişkili öğrenci/ders/öğretim elemanı kayıtları bulunan bölüm silinemez.
DO $$
BEGIN
    DELETE FROM Department WHERE department_id = 1;

    RAISE NOTICE 'TEST BAŞARISIZ: Department silinebildi.';
EXCEPTION WHEN foreign_key_violation THEN
    RAISE NOTICE 'BEKLENEN DAVRANIŞ: RESTRICT nedeniyle bölüm silinemedi. SQLSTATE %.',
        SQLSTATE;
END $$;

-- Test amaçlı silme işlemlerini geri al; örnek veriler korunur.
ROLLBACK;

-- ============================================================================
-- BÖLÜM 4: İLİŞKİSEL CEBİR VE SQL KARŞILIKLARI
-- ============================================================================

-- SORU 1: Bütün öğrencileri listeleyin.
-- İlişkisel cebir: Student
SELECT *
FROM Student;

-- SORU 2: 2026 yılında kayıt yaptıran öğrencileri bulun.
-- İlişkisel cebir: σ enrollment_year = 2026 (Student)
SELECT *
FROM Student
WHERE enrollment_year = 2026;

-- SORU 3: Öğrencilerin yalnızca ad ve soyadlarını gösterin.
-- İlişkisel cebir: π first_name, last_name (Student)
SELECT first_name, last_name
FROM Student;

-- SORU 4: Öğrencilerin kayıtlı oldukları dersleri listeleyin.
-- İlişkisel cebir: Student ⋈ Enrollment ⋈ Section ⋈ Course
SELECT
    s.student_no,
    s.first_name,
    s.last_name,
    c.course_code,
    c.course_name
FROM Student AS s
JOIN Enrollment AS e ON e.student_id = s.student_id
JOIN Section AS sec ON sec.section_id = e.section_id
JOIN Course AS c ON c.course_id = sec.course_id
ORDER BY s.student_no, c.course_code;

-- SORU 5: Notu 80 veya daha yüksek olan öğrenci ve dersleri bulun.
-- İlişkisel cebir: σ grade >= 80 (Student ⋈ Enrollment ⋈ Section ⋈ Course)
SELECT
    s.first_name,
    s.last_name,
    c.course_name,
    e.grade
FROM Student AS s
JOIN Enrollment AS e ON e.student_id = s.student_id
JOIN Section AS sec ON sec.section_id = e.section_id
JOIN Course AS c ON c.course_id = sec.course_id
WHERE e.grade >= 80
ORDER BY e.grade DESC;

-- ============================================================================
-- BÖLÜM 5: SON KONTROL
-- ============================================================================
-- Tablolardaki kayıt sayılarını gösterir.
SELECT 'Department' AS table_name, COUNT(*) AS row_count FROM Department
UNION ALL
SELECT 'Student', COUNT(*) FROM Student
UNION ALL
SELECT 'Instructor', COUNT(*) FROM Instructor
UNION ALL
SELECT 'Course', COUNT(*) FROM Course
UNION ALL
SELECT 'Section', COUNT(*) FROM Section
UNION ALL
SELECT 'Enrollment', COUNT(*) FROM Enrollment
ORDER BY table_name;

-- ÖDEV 2 tamamlandı.
yaren yılmazer 202502009063
