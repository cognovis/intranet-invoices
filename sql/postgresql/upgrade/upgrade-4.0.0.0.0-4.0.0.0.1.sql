-- upgrade-4.0.0.0.0-4.0.0.0.1.sql

SELECT acs_log__debug('/packages/intranet-invoices/sql/postgresql/upgrade/upgrade-4.0.0.0.0-4.0.0.0.1.sql','');

create or replace function inline_0 ()
returns integer as '
declare
        v_count         integer;
begin
        select count(*) into v_count from user_tab_columns
        where lower(table_name) = ''im_invoice_items'' and lower(column_name) = ''item_source_project_id'';
        IF v_count > 0 THEN return 1; END IF;

	alter table im_invoice_items 
	add column item_source_project_id integer 
	constraint im_invoice_items_project_id_fk references im_projects; 

        RETURN 0;

end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

