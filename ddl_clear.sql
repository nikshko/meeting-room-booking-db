create table buildings
(
    building_id serial
        primary key,
    street      varchar(50) not null,
    number      varchar(10)
);

create table catering
(
    catering_id serial
        primary key,
    name        varchar(50)    not null,
    price       numeric(10, 2) not null
        constraint price_positive1
            check (price > (0)::numeric),
    description varchar(1000)
);

create table food_drinks
(
    item_id serial
        primary key,
    name    varchar(50) not null
);

create table rooms
(
    room_id     serial
        primary key,
    capacity    integer        not null,
    price       numeric(10, 2) not null
        constraint price_positive
            check (price > (0)::numeric),
    building_id integer        not null
        constraint rooms_buildings_fk
            references buildings
);

create table equipment
(
    equipment_id serial
        primary key,
    name         varchar(40) not null,
    amount       integer default 1,
    room_id      integer
        constraint equipment_rooms_fk
            references rooms
);

create table rooms_catering
(
    room_id     integer not null
        constraint rooms_catering_rooms_fk
            references rooms,
    catering_id integer not null
        constraint rooms_catering_catering_fk
            references catering,
    constraint rooms_catering_pk
        primary key (room_id, catering_id)
);

create table rooms_food
(
    food_drinks_id integer not null
        constraint rooms_food_food_drinks_fk
            references food_drinks,
    room_id        integer not null
        constraint rooms_food_rooms_fk
            references rooms,
    constraint rooms_food_pk
        primary key (food_drinks_id, room_id)
);

create table services
(
    service_id  serial
        primary key,
    name        varchar(50)    not null,
    price       numeric(10, 2) not null
        constraint price_positive2
            check (price > (0)::numeric),
    description varchar(200)
);

create table services_rooms
(
    service_id integer not null
        constraint services_rooms_services_fk
            references services,
    room_id    integer not null
        constraint services_rooms_rooms_fk
            references rooms,
    constraint services_rooms_pk
        primary key (service_id, room_id)
);

create table users
(
    user_id      serial
        primary key,
    name         varchar(50) not null,
    surname      varchar(50) not null,
    phone_number varchar(15) not null,
    password     varchar(12) not null
        constraint password_length
            check (length((password)::text) <= 12),
    is_admin     boolean
);

create table contacts
(
    contact_id      serial
        primary key,
    email           varchar(50),
    company_name    varchar(100) not null,
    company_website varchar(100),
    user_id         integer      not null
        constraint contacts_users_fk
            references users
);

create table events
(
    event_id   serial
        primary key,
    title      varchar(100) not null,
    start_time date         not null,
    end_time   date         not null,
    user_id    integer
        constraint fk_user
            references users
);

create table events_rooms
(
    event_id integer not null
        constraint events_rooms_events_fk
            references events,
    room_id  integer not null
        constraint events_rooms_rooms_fk
            references rooms,
    constraint events_rooms_pk
        primary key (event_id, room_id)
);

create table reservations
(
    reservation_id serial
        primary key,
    event_id       integer              not null
        constraint reservations_events_fk
            references events,
    user_id        integer              not null
        constraint reservations_users_fk
            references users,
    catering_id    integer
        constraint reservations_catering_fk
            references catering,
    is_active      boolean default true not null,
    amount         numeric(10, 2)       not null,
    room_id        integer              not null
        constraint reservations_rooms_fk
            references rooms
);

create table payments
(
    payment_id        serial
        primary key,
    "Date"            timestamp(0) not null,
    reservation_id    integer      not null
        constraint payments_reservations_fk
            references reservations,
    user_name         varchar(50),
    user_surname      varchar(50),
    amount            numeric(10, 2),
    user_phone_number varchar(15)  not null
);

create index payments_reservations_index
    on payments (reservation_id);

create index reservations_user
    on reservations (user_id);

create table reviews
(
    review_id      serial
        primary key,
    rating         integer      not null
        constraint rating_range
            check ((rating >= 1) AND (rating <= 5)),
    "Comment"      varchar(1000),
    reservation_id integer      not null
        constraint reviews_reservations_fk
            references reservations,
    published_date timestamp(0) not null
);

create table rooms_availability_time
(
    availability_date_id serial
        primary key,
    room_id              integer      not null
        constraint av_time_rooms_fk
            references rooms,
    start_time           timestamp(0) not null,
    end_time             timestamp(0) not null,
    reservation_id       integer
        constraint av_time_reservations_fk
            references reservations
            on delete set null
);

create index rat_reservation
    on rooms_availability_time (reservation_id);

create index rat_room
    on rooms_availability_time (room_id);

create table services_reservations
(
    service_id     integer not null
        constraint services_reservations_s_fk
            references services,
    reservation_id integer not null
        constraint services_reservations_r_fk
            references reservations,
    constraint services_reservations_pk
        primary key (service_id, reservation_id)
);

create table workers
(
    worker_id serial
        primary key,
    name      varchar(50) not null,
    surname   varchar(50) not null,
    salary    numeric(10, 2)
        constraint salary_positive
            check (salary > (0)::numeric),
    company   varchar(50) not null
);

create table workers_rooms
(
    worker_id integer not null
        constraint workers_rooms_workers_fk
            references workers,
    room_id   integer not null
        constraint workers_rooms_rooms_fk
            references rooms,
    constraint workers_rooms_pk
        primary key (worker_id, room_id)
);