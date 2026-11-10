/*
===============================================================================
ÖDEV 1 - VERİTABANI TASARIMI
Proje: Üniversite Öğrenci ve Ders Kayıt Sistemi
DBMS: PostgreSQL

AMAÇ
-----
Üniversite bölümlerini, öğrencileri, öğretim elemanlarını, dersleri,
ders şubelerini ve öğrenci kayıtlarını saklayan ilişkisel bir veritabanı
tasarlamak.

ÇALIŞTIRMA
----------
1. pgAdmin 4 -> Databases altında bir veritabanı oluşturun
   (ör. university_db).
2. Bu veritabanına bağlanın.
3. Query Tool'u açın.
4. Bu dosyanın tamamını çalıştırın.

NOT
---
Bu dosya tabloları oluşturur. Örnek kayıtlar ve Ödev 2 testleri
02_odev2.sql dosyasındadır.

ER DİYAGRAMI (Mermaid)
---------------------
Aşağıdaki diyagram SQL yorum satırları içindedir; PostgreSQL bunu
çalıştırmaz. Diyagramı Mermaid destekleyen bir editöre yapıştırarak
görsel hale getirebilirsiniz.

erDiagram
    DEPARTMENT ||--o{ STUDENT : has
    DEPARTMENT ||--o{ INSTRUCTOR : employs
    DEPARTMENT ||--o{ COURSE : offers
    COURSE ||--o{ SECTION : has
    INSTRUCTOR o|--o{ SECTION : teaches
    STUDENT ||--o{ ENROLLMENT : makes
    SECTION ||--o{ ENROLLMENT : contains

    DEPARTMENT {
        integer department_id PK
        varchar department_name UK
    }
    STUDENT {
        integer student_id PK
        varchar student_no UK
        varchar first_name
        varchar last_name
        varchar email UK
        integer enrollment_year
        integer department_id FK
    }
    INSTRUCTOR {
        integer instructor_id PK
        varchar first_name
        varchar last_name
        varchar email UK
        integer department_id FK
    }
    COURSE {
        integer course_id PK
        varchar course_code UK
        varchar course_name
        integer credits
        integer department_id FK
    }
    SECTION {
        integer section_id PK
        integer course_id FK
        integer instructor_id FK
        varchar term
        integer academic_year
        integer section_no
        integer capacity
    }
    ENROLLMENT {
        integer enrollment_id PK
        integer student_id FK
        integer section_id FK
        date enrollment_date
        numeric grade
    }

İLİŞKİLERİN AÇIKLAMASI
----------------------
1. Department - Student: 1-N. Bir bölümde birçok öğrenci bulunabilir.
2. Department - Instructor: 1-N. Bir bölümde birçok öğretim elemanı bulunabilir.
3. Department - Course: 1-N. Bir bölüm birçok ders sunabilir.
4. Course - Section: 1-N. Bir ders farklı dönem/şubelerde açılabilir.
5. Instructor - Section: 1-N. Bir öğretim elemanı birçok şube verebilir.
   instructor_id NULL olabilir; öğretim elemanı silinirse SET NULL uygulanır.
6. Student - Section: N-N. Bu çoktan çoğa ilişki Enrollment ile çözülür.
7. Student - Enrollment ve Section - Enrollment: iki adet 1-N ilişkidir.

ANAHTARLAR VE KISITLAR
---------------------
PRIMARY KEY : Her satırı benzersiz tanımlar.
FOREIGN KEY : Tablolar arasındaki referans bütünlüğünü sağlar.
NOT NULL    : Alanın boş bırakılmasını engeller.
UNIQUE      : Aynı değerin tekrarını engeller.
CHECK       : Alan değerinin belirtilen koşula uymasını sağlar.
SERIAL      : PostgreSQL'in otomatik artan tamsayı alanıdır.
===============================================================================
*/

-- Tabloları bağımlılık sırasına göre oluşturuyoruz.

CREATE TABLE Department (
    department_id SERIAL PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE Student (
    student_id SERIAL PRIMARY KEY,
    student_no VARCHAR(20) NOT NULL UNIQUE,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    enrollment_year INTEGER NOT NULL
        CHECK (enrollment_year >= 2000),
    department_id INTEGER NOT NULL,

    CONSTRAINT fk_student_department
        FOREIGN KEY (department_id)
        REFERENCES Department(department_id)
        ON DELETE RESTRICT
);

CREATE TABLE Instructor (
    instructor_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    department_id INTEGER NOT NULL,

    CONSTRAINT fk_instructor_department
        FOREIGN KEY (department_id)
        REFERENCES Department(department_id)
        ON DELETE RESTRICT
);

CREATE TABLE Course (
    course_id SERIAL PRIMARY KEY,
    course_code VARCHAR(20) NOT NULL UNIQUE,
    course_name VARCHAR(100) NOT NULL,
    credits INTEGER NOT NULL
        CHECK (credits BETWEEN 1 AND 10),
    department_id INTEGER NOT NULL,

    CONSTRAINT fk_course_department
        FOREIGN KEY (department_id)
        REFERENCES Department(department_id)
        ON DELETE RESTRICT
);

CREATE TABLE Section (
    section_id SERIAL PRIMARY KEY,
    course_id INTEGER NOT NULL,
    instructor_id INTEGER,
    term VARCHAR(20) NOT NULL
        CHECK (term IN ('Fall', 'Spring', 'Summer')),
    academic_year INTEGER NOT NULL
        CHECK (academic_year >= 2000),
    section_no INTEGER NOT NULL
        CHECK (section_no > 0),
    capacity INTEGER NOT NULL
        CHECK (capacity > 0),

    CONSTRAINT fk_section_course
        FOREIGN KEY (course_id)
        REFERENCES Course(course_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_section_instructor
        FOREIGN KEY (instructor_id)
        REFERENCES Instructor(instructor_id)
        ON DELETE SET NULL,

    CONSTRAINT uq_section
        UNIQUE (course_id, term, academic_year, section_no)
);

CREATE TABLE Enrollment (
    enrollment_id SERIAL PRIMARY KEY,
    student_id INTEGER NOT NULL,
    section_id INTEGER NOT NULL,
    enrollment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    grade NUMERIC(5,2)
        CHECK (grade BETWEEN 0 AND 100),

    CONSTRAINT fk_enrollment_student
        FOREIGN KEY (student_id)
        REFERENCES Student(student_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_enrollment_section
        FOREIGN KEY (section_id)
        REFERENCES Section(section_id)
        ON DELETE CASCADE,

    CONSTRAINT uq_enrollment
        UNIQUE (student_id, section_id)
);

-- Tablo oluşturma işlemini kontrol etmek için:
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN
      ('department', 'student', 'instructor',
       'course', 'section', 'enrollment')
ORDER BY table_name;

Örnek veri ve testler için 02_odev2.sql dosyası 
yaren yılmazer 202502009063 ybs
