begin;
create table public.staff (
 id uuid primary key references auth.users(id), name text not null,
 role text not null check(role in ('trainer','supervisor')),
 opening_days integer not null default 0 check(opening_days>=0)
);
create table public.duty (
 id uuid primary key default gen_random_uuid(), owner uuid not null default auth.uid() references public.staff(id),
 day date not null, kind text not null check(kind in ('Normal duty','Holiday duty','Comp-off taken')),
 starts time not null, ends time not null, note text not null default '' check(length(note)<=400),
 status text not null default 'Pending' check(status in ('Pending','Approved','Rejected')),
 ot numeric not null default 0, days integer not null default 0,
 reviewed_by uuid references public.staff(id), reviewed_at timestamptz,
 check(ends>starts)
);
create unique index one_active_day on public.duty(owner,day) where status <> 'Rejected';
alter table public.staff enable row level security;
alter table public.duty enable row level security;
create function public.is_supervisor() returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.staff where id=auth.uid() and role='supervisor')
$$;
create policy staff_visibility on public.staff for select to authenticated using(id=auth.uid() or public.is_supervisor());
create policy duty_visibility on public.duty for select to authenticated using(owner=auth.uid() or public.is_supervisor());
create policy submit_own on public.duty for insert to authenticated with check(owner=auth.uid() and exists(select 1 from public.staff where id=auth.uid() and role='trainer'));
revoke all on public.duty,public.staff from anon,authenticated,public;
grant select on public.duty,public.staff to authenticated;
grant insert(day,kind,starts,ends,note) on public.duty to authenticated;
create function public.review(entry uuid, decision text, overtime numeric, credit integer) returns void
language plpgsql security definer set search_path='' as $$
declare r public.duty; hours numeric; balance integer;
begin
 if not public.is_supervisor() then raise exception 'Supervisor access required'; end if;
 select * into strict r from public.duty where id=entry for update;
 if r.status<>'Pending' then raise exception 'Entry already reviewed'; end if;
 select opening_days into balance from public.staff where id=r.owner for update;
 select balance+coalesce(sum(days),0) into balance from public.duty where owner=r.owner and status='Approved';
 hours:=extract(epoch from r.ends-r.starts)/3600;
 if decision is null or decision not in ('Approved','Rejected') then raise exception 'Invalid decision'; end if;
 if decision='Rejected' then overtime:=0; credit:=0;
 elsif overtime is null or credit is null or overtime<0 or overtime>hours or
 (r.kind='Normal duty' and (credit<>0 or overtime>3.5)) or
 (r.kind='Holiday duty' and (credit<0 or credit*8+overtime>hours)) or
 (r.kind='Comp-off taken' and (credit<>-1 or overtime<>0 or balance<1))
 then raise exception 'Check overtime, comp-off allocation and available balance'; end if;
 update public.duty set status=decision, ot=overtime, days=credit, reviewed_by=auth.uid(),reviewed_at=now() where id=entry;
end $$;
revoke all on function public.review(uuid,text,numeric,integer) from public,anon;
grant execute on function public.review(uuid,text,numeric,integer) to authenticated;
commit;
