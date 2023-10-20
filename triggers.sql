-- adds user data to new row in payments table
create or replace function Users_Payments_Denorm_Func() returns trigger as $$
    declare
        v_name varchar(50);
        v_surname varchar(50);
        v_phone_number varchar(15);
        v_user_id integer;
        v_amount numeric(10,2);
    BEGIN
        select reservations.user_id, reservations.amount into v_user_id, v_amount
        from reservations
        where reservations.reservation_id = NEW.reservation_id;

        select users.name, users.surname, users.phone_number
        into v_name, v_surname, v_phone_number from users
        where users.user_id = v_user_id;

        NEW.user_name := v_name;
        NEW.user_surname := v_surname;
        NEW.user_phone_number := v_phone_number;
        NEW.amount := v_amount;
        return new;
    end;
$$ language plpgsql;

create or replace trigger Users_Payments_Denorm_Trigger
    before insert on payments
    for each row execute function Users_Payments_Denorm_Func();

-- adds price of catering to the amount field in reservations table
create or replace function Reservations_Amount() returns trigger as $$
    declare
        v_catering_cost numeric(10,2);
    BEGIN
        select catering.price into v_catering_cost
        from catering
        where catering.catering_id = NEW.catering_id;
        NEW.amount := v_catering_cost;
        return NEW;
    end;
$$ language plpgsql;

create or replace trigger Reservations_Amount_Trigger
    before insert on reservations
    for each row execute function Reservations_Amount();

-- adds price of services to the amount field in reservations table
create or replace function Reservations_Services_Amount() returns trigger as $$
    declare
        v_service_price decimal(10,2);
    begin
        select services.price into v_service_price
        from services
        where services.service_id = NEW.service_id;

        update reservations
        set amount = amount + v_service_price
        where reservation_id = NEW.reservation_id;
        return NEW;
    end;
$$ language plpgsql;

create or replace trigger Reservations_Services_Amount_Trigger
    after insert on services_reservations
    for each row execute function Reservations_Services_Amount();

-- raises exception when trying to change reservation_id in payments table
create or replace function Payments_Reservations_Update_Func() returns trigger as $$
    begin
        raise exception 'Updating the % table is not allowed on the % column!',
            tg_table_name, 'reservation_id';
    end;
$$ language plpgsql;

create or replace trigger Payments_Reservations_Update_Trigger
    before update of reservation_id on payments
    for each row execute function Payments_Reservations_Update_Func();

create or replace function Rooms_Price_Reservations_Insert_Func() returns trigger as
$$
    BEGIN
        if new.reservation_id is null then
            raise exception 'Missing reservation for this time slot!';
        end if;
        IF new.room_id <> (select room_id from reservations where reservation_id = NEW.reservation_id) THEN
                RAISE EXCEPTION 'Invalid room_id for the reservation!';
            END IF;
        update reservations
        set amount = amount + (select price from rooms where room_id = new.room_id)
        where new.reservation_id = reservations.reservation_id;
        return new;
    end;
$$ language plpgsql;

create or replace trigger Rooms_Price_Reservations_Insert_Trigger
    before insert on rooms_availability_time
    for each row execute function Rooms_Price_Reservations_Insert_Func();

insert into rooms_availability_time (room_id, start_time, end_time, reservation_id) values (4, '2023-05-25 8:00:00', '2023-05-25 8:00:00', 13);

create or replace function Rooms_Price_Reservations_Delete_Func() returns trigger as
$$
    BEGIN
        update reservations
        set amount = amount - (select price from rooms where room_id = old.room_id)
        where reservation_id = old.reservation_id;
        return old;
    end;
$$ language plpgsql;

create or replace trigger Rooms_Price_Reservations_Delete_Func
    before delete on rooms_availability_time
    for each row execute function Rooms_Price_Reservations_Delete_Func();