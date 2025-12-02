CREATE TYPE person_gender AS ENUM ('M', 'F');

CREATE TABLE table_persons (
    id SERIAL NOT NULL PRIMARY KEY,
    first_name TEXT NOT NULL CHECK ( first_name != '' ),
    last_name TEXT NOT NULL CHECK ( last_name != '' ),
    patronymic TEXT CHECK ( patronymic != '' ),
    gender person_gender NOT NULL CHECK ( gender != '' ),
    date_of_birth DATE
);

CREATE TABLE table_emails (
    id SERIAL NOT NULL PRIMARY KEY,
    person_id INT NOT NULL,
    email TEXT NOT NULL CHECK ( email LIKE '%@%' ),
    FOREIGN KEY (person_id) REFERENCES table_phone_numbers(id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
);

CREATE TABLE table_phone_numbers (
    id SERIAL NOT NULL PRIMARY KEY,
    person_id INT NOT NULL,
    phone_number TEXT NOT NULL CHECK ( phone_number != '' ),
    FOREIGN KEY (person_id) REFERENCES table_phone_numbers(id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
);

CREATE TABLE table_manufacturers (
    id SERIAL NOT NULL PRIMARY KEY,
    name TEXT NOT NULL CHECK ( name != '' ),
    address TEXT CHECK ( address != '' ),
    contact_person_id INT NOT NULL,
    description TEXT CHECK ( name != '' ),
    FOREIGN KEY (contact_person_id) REFERENCES table_persons(id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
);

CREATE TABLE table_product_types (
    id SERIAL NOT NULL PRIMARY KEY,
    name TEXT NOT NULL CHECK ( name != '' ),
    description TEXT CHECK ( name != '' )
);

CREATE TABLE table_products (
    id SERIAL NOT NULL PRIMARY KEY,
    name TEXT NOT NULL CHECK ( name != '' ),
    type_id INT NOT NULL,
    amount_in_stock INT NOT NULL CHECK ( amount_in_stock >= 0 ),
    cost_price NUMERIC NOT NULL CHECK ( cost_price >= 0.0 ),
    manufacturer_id INT NOT NULL,
    price NUMERIC NOT NULL CHECK ( price >= 0.0 ),
    measurement_unit TEXT CHECK ( name != '' ),
    measurement_value NUMERIC CHECK ( measurement_value >= 0.0 ),
    is_archived BOOLEAN NOT NULL DEFAULT FALSE,
    FOREIGN KEY (type_id) REFERENCES table_product_types(id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    FOREIGN KEY (manufacturer_id) REFERENCES table_manufacturers(id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
);

-- Товар должен помещаться в архив, когда его количество становится 0
CREATE TABLE table_archived_products_log (
    id SERIAL NOT NULL PRIMARY KEY,
    product_id INT NOT NULL,
    change_date DATE NOT NULL,
    FOREIGN KEY (product_id) REFERENCES table_products(id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
);

CREATE TABLE table_positions (
    id SERIAL NOT NULL PRIMARY KEY,
    name TEXT NOT NULL CHECK ( name != '' ),
    level TEXT NOT NULL CHECK ( level != '' ),
    average_salary NUMERIC NOT NULL CHECK ( average_salary >= 0.0 ),
    requirements TEXT NOT NULL CHECK ( requirements != '' ),
    tasks TEXT NOT NULL CHECK ( tasks != '' ),
    is_hiring BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE table_employees (
    id SERIAL NOT NULL PRIMARY KEY,
    person_id INT NOT NULL,
    position_id INT NOT NULL,
    hiring_date DATE NOT NULL,
    salary NUMERIC NOT NULL CHECK ( salary >= 0.0 ),
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    FOREIGN KEY (person_id) REFERENCES table_persons(id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    FOREIGN KEY (position_id) REFERENCES table_positions(id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
);

CREATE TABLE employee_history (
    id SERIAL NOT NULL PRIMARY KEY,
    employee_id INT NOT NULL,
    supervisor_id INT NOT NULL,
    position_id INT NOT NULL,
    change_date DATE NOT NULL,
    change_reason TEXT CHECK ( change_reason != '' ),
    FOREIGN KEY (employee_id) REFERENCES table_employees(id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    FOREIGN KEY (supervisor_id) REFERENCES table_employees(id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    FOREIGN KEY (position_id) REFERENCES table_positions(id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
);

CREATE TABLE table_price_history (
    id SERIAL NOT NULL PRIMARY KEY,
    product_id INT NOT NULL,
    employee_id INT NOT NULL,
    cost_price NUMERIC NOT NULL CHECK ( cost_price >= 0.0 ),
    price NUMERIC NOT NULL CHECK ( price >= 0.0 ),
    change_date DATE NOT NULL,
    change_reason TEXT CHECK ( change_reason != '' ),
    FOREIGN KEY (product_id) REFERENCES table_products(id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    FOREIGN KEY (employee_id) REFERENCES table_employees(id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
);

CREATE TABLE table_clients (
    id SERIAL NOT NULL PRIMARY KEY,
    person_id INT NOT NULL,
    discount_percent NUMERIC(3, 2) NOT NULL CHECK ( discount_percent < 1.00 AND discount_percent >= 0.00) DEFAULT 0.00,
    is_subscribed_to_mailing_list BOOLEAN NOT NULL DEFAULT FALSE,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    FOREIGN KEY (person_id) REFERENCES table_persons(id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
);

CREATE TABLE table_orders (
    id SERIAL NOT NULL PRIMARY KEY,
    items_price NUMERIC NOT NULL CHECK ( items_price >= 0.0 ),
    items_amount INT NOT NULL CHECK ( items_amount >= 0 ),
    date DATE NOT NULL,
    is_payed BOOLEAN NOT NULL DEFAULT FALSE,
    is_client_registered BOOLEAN NOT NULL DEFAULT FALSE,
    client_id INT,
    FOREIGN KEY (client_id) REFERENCES table_clients(id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
);

CREATE TABLE table_order_items (
    id SERIAL NOT NULL PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    amount INT NOT NULL CHECK ( amount >= 0 ),
    FOREIGN KEY (order_id) REFERENCES table_orders(id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    FOREIGN KEY (product_id) REFERENCES table_products(id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
);

CREATE TABLE table_sales (
    id SERIAL NOT NULL PRIMARY KEY,
    order_id INT NOT NULL,
    total_price NUMERIC NOT NULL CHECK ( total_price >= 0.0 ),
    payment_type TEXT NOT NULL CHECK ( payment_type != '' ),
    employee_id INT NOT NULL,
    date DATE NOT NULL,
    FOREIGN KEY (order_id) REFERENCES table_orders(id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    FOREIGN KEY (employee_id) REFERENCES table_employees(id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
);

CREATE FUNCTION function_archive_product()
    RETURNS TRIGGER
    LANGUAGE plpgsql
AS
$$
BEGIN
    IF (tg_table_name == 'table_products') THEN
        IF (NEW.amount_in_stock = 0 AND NEW.is_archived = FALSE) THEN
            NEW.is_archived = TRUE;
            INSERT INTO table_archived_products_log(product_id, change_date)
            VALUES (NEW.id, current_date);
        ELSEIF (NEW.amount_in_stock > 0 AND NEW.is_archived = TRUE) THEN
            NEW.is_archived = FALSE;
        END IF;
    END IF;
END;
$$;


CREATE TRIGGER trigger_archive_product
    BEFORE UPDATE
    ON table_products
    FOR EACH ROW
    EXECUTE FUNCTION function_archive_product();