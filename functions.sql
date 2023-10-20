create or replace function validate_password(IN p_phone_number varchar,
    IN p_password varchar) returns integer AS
$$
    declare
        v_password varchar(12);
        v_user_id integer;
    BEGIN
        select users.password, users.user_id into v_password, v_user_id
        from users
        where users.phone_number = p_phone_number;
        if v_password is null or v_password <> p_password then
            return 0;
        end if;
        return v_user_id;
    end;
$$ LANGUAGE plpgsql;

create or replace function get_available_rooms(p_start_date date, p_end_date date)
returns table(
    room_id integer,
    price numeric(10, 2),
    capacity integer
             ) as $$
    BEGIN
        return query
            select r.room_id, r.price, r.capacity from rooms r
            where exists (
                select rat.availability_date_id from rooms_availability_time rat
                where r.room_id = rat.room_id
                  and rat.reservation_id is null
                  and date(rat.start_time) between p_start_date and p_end_date
                  and date(rat.end_time) between p_start_date and p_end_date
            );
    end;
$$ language plpgsql;

create or replace function is_payment_exists(p_reservation_id integer)
returns boolean as $$
    begin
        if (select exists(select 1 from payments p where p.reservation_id = p_reservation_id)) then
            return true;
        end if;
        return false;
    end;
$$ language plpgsql;


create function get_room_info(id integer)
    returns TABLE(street character varying, street_number character varying, catering_name character varying, catering_price numeric, catering_description character varying, food_name character varying, service_name character varying, service_price numeric, service_description character varying, equipment_name character varying)
    language plpgsql
as
$$
BEGIN
    return query
  select building.street, building.number, c.name, c.price, c.description, fd.name, service.name, service.price,
  service.description, e.name from rooms join buildings building on rooms.building_id = building.building_id join rooms_catering rc on rooms.room_id = rc.room_id
  join catering c on rc.catering_id = c.catering_id join rooms_food rf on rooms.room_id = rf.room_id join food_drinks fd on rf.food_drinks_id = fd.item_id join equipment e on rooms.room_id = e.room_id
  join services_rooms sr on rooms.room_id = sr.room_id join services service on sr.service_id = service.service_id where rooms.room_id = id;
END;
$$;

create function get_unavailable_time_spaces(event_date date, selected_room_id integer)
    returns TABLE(time_space time without time zone)
    language plpgsql
as
$$
BEGIN
    return query
  select start_time::time from rooms_availability_time where DATE(start_time) = event_date and room_id = selected_room_id;
END;
$$;

