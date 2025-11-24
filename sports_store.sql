CREATE TABLE table_product_types (
    id SERIAL NOT NULL PRIMARY KEY,
    name TEXT NOT NULL CHECK ( name != '' ),
    description TEXT NOT NULL CHECK ( name != '' )
);

CREATE TABLE table_products (
    id SERIAL NOT NULL PRIMARY KEY,
    name TEXT NOT NULL CHECK ( name != '' ),
    type_id INT NOT NULL,
    amount_in_stock INT NOT NULL CHECK ( amount_in_stock >= 0 ),
    cost_price NUMERIC NOT NULL CHECK ( cost_price >= 0.0 ),
    manufacturer TEXT NOT NULL CHECK ( name != '' ),
    price NUMERIC NOT NULL CHECK ( price >= 0.0 ),
    FOREIGN KEY (type_id) REFERENCES table_product_types(id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
);

CREATE TABLE table_employees (
    id SERIAL NOT NULL PRIMARY KEY,
    first_name TEXT NOT NULL CHECK ( first_name != '' ),
    last_name TEXT NOT NULL CHECK ( last_name != '' ),
    patronymic TEXT CHECK ( patronymic != '' ),
    job TEXT NOT NULL CHECK ( job != '' ),
    hiring_date DATE NOT NULL,
    gender CHAR NOT NULL CHECK ( gender = 'M' OR gender = 'F' ),
    salary NUMERIC NOT NULL CHECK ( salary >= 0.0 )
);

CREATE TABLE table_clients (
    id SERIAL NOT NULL PRIMARY KEY,
    first_name TEXT NOT NULL CHECK ( first_name != '' ) DEFAULT 'UNREGISTERED',
    last_name TEXT NOT NULL CHECK ( last_name != '' ) DEFAULT 'UNREGISTERED',
    patronymic TEXT CHECK ( patronymic != '' ),
    email TEXT NOT NULL CHECK ( email LIKE '%@%' ) DEFAULT 'UNREGISTERED',
    phoneNumber TEXT NOT NULL CHECK ( phoneNumber != '' ) DEFAULT 'UNREGISTERED',
    gender CHAR CHECK ( gender = 'M' OR gender = 'F' ),
    discount_percent NUMERIC(3, 2) NOT NULL CHECK ( discount_percent >= 0.00 ) DEFAULT 0.00,
    is_subscribed_to_mailing_list BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE table_sales (
    id SERIAL NOT NULL PRIMARY KEY,
    product_id INT NOT NULL,
    amount_sold INT NOT NULL CHECK ( amount_sold >= 0 ),
    total_price NUMERIC NOT NULL CHECK ( total_price >= 0.0 ),
    date DATE NOT NULL,
    employee_id INT NOT NULL,
    client_id INT NOT NULL,
    FOREIGN KEY (product_id) REFERENCES table_products(id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    FOREIGN KEY (employee_id) REFERENCES table_employees(id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    FOREIGN KEY (client_id) REFERENCES table_clients(id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
);

CREATE TABLE table_order_histories (
    id SERIAL NOT NULL PRIMARY KEY,
    client_id INT NOT NULL,
    sale_id INT NOT NULL,
    FOREIGN KEY (client_id) REFERENCES table_clients(id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    FOREIGN KEY (sale_id) REFERENCES table_sales(id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
);