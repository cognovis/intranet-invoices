# /packages/intranet-invoices/www/new-copy.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------

ad_page_contract { 
    Copy existing financial document to a new one.
    @author frank.bergmann@project-open.com
} {
    { source_invoice_id:integer,multiple "" }
    source_cost_type_id:integer,optional
    target_cost_type_id:integer
    upload_file:optional
    {customer_id:integer ""}
    {provider_id:integer ""}
    {project_id:integer ""}
    {company_id:integer ""}
    {target_invoice_date ""}
    {target_invoice_nr ""}
    {payment_method_id ""}
    {payment_term_id ""}
    {invoice_currency ""}
    {cost_status_id "3802"}
}

# ---------------------------------------------------------------
# Security
# ---------------------------------------------------------------
set current_cost_type_id $target_cost_type_id

set user_id [ad_maybe_redirect_for_registration]
if {![im_permission $user_id add_invoices]} {
    ad_return_complaint "Insufficient Privileges" "
    <li>You don't have sufficient privileges to see this page."
    ad_script_abort
}

foreach source_id $source_invoice_id {
    im_cost_permissions $user_id $source_id view_p read_p write_p admin_p
    if {!$read_p} {
	ad_return_complaint "Insufficient Privileges" "
        <li>You don't have sufficient privileges to see the source document."
        ad_script_abort
    }
    set allowed_cost_type [im_cost_type_write_permissions $user_id]
    if {[lsearch -exact $allowed_cost_type $target_cost_type_id] == -1} {
	ad_return_complaint "Insufficient Privileges" "
        <li>You can't create documents of type #$target_cost_type_id."
        ad_script_abort
    }
}

# ---------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------

# The user hasn't yet specified the source invoice from which
# we want to copy. So let's redirect and this page is going
# to refer us back to this one.
if {0 == [llength $source_invoice_id]} {
    ad_returnredirect new-merge-invoiceselect?[export_url_vars source_cost_type_id target_cost_type_id customer_id provider_id project_id return_url company_id]
    ad_script_abort
}

lappend source_invoice_id 0

set todays_date [db_string get_today "select now()::date"]

# Use today's date as effective date, because the
# quote was old...
if {"" == $target_invoice_date} {
    set effective_date $todays_date
} else {
    set effective_date $target_invoice_date
}

set payment_days [db_string payment_days "select aux_int1 from im_categories where category_id = :payment_term_id" -default ""]
if {"" == $payment_days} {
    set payment_days [ad_parameter -package_id [im_package_cost_id] "DefaultProviderBillPaymentDays" "" 30]
}

# ---------------------------------------------------------------
# Get the latest project end date as delivery date
# ---------------------------------------------------------------

# Get the list of projects
set project_ids [db_list projects "select distinct project_id from im_costs where cost_id in ([template::util::tcl_to_sql_list $source_invoice_id]) and project_id is not null"]
if {[llength $project_ids]>0} {
    set delivery_date [db_string delivery_date "select to_char(max(end_date),'YYYY-MM-DD') from im_projects where project_id in ([template::util::tcl_to_sql_list $project_ids])"]
    set project_id [lindex $project_ids 0]
} else {
    set delivery_date ""
    set project_id ""
}
if {"" == $delivery_date} {
    set delivery_date $effective_date
}


# ---------------------------------------------------------------
# Determine whether it's an Invoice or a Bill
# ---------------------------------------------------------------

# Invoices and Quotes have a "Company" fields.
set invoice_or_quote_p [im_cost_type_is_invoice_or_quote_p $target_cost_type_id]

# Invoices and Bills have a "Payment Terms" field.
set invoice_or_bill_p [im_cost_type_is_invoice_or_bill_p $target_cost_type_id]

if {$invoice_or_quote_p} {
    set company_id $customer_id
    set company_type [_ intranet-core.Customer]
} else {
    set company_id $provider_id
    set company_type [_ intranet-core.Provider]
}

# Default for template: Get it from the company
set template_id [im_invoices_default_company_template $target_cost_type_id $company_id]
if {$template_id eq "unknown"} {set template_id ""}
# Get the company contact id
set company_contact_id [im_invoices_default_company_contact $company_id $project_id]

# Get the invoice office id
set invoice_office_id [db_string company_main_office_info "select main_office_id from im_companies where company_id = :company_id" -default ""]

# Get the correct cost_center_id
set cost_center_id [db_string cost_center "select cost_center_id from im_costs where cost_id in ([template::util::tcl_to_sql_list $source_invoice_id]) order by cost_center_id limit 1" -default ""]

# Get a reasonable default value for the vat_type_id,
# either from the invoice or from the company.
    
set vat_type_id [db_string vat_type_info "select max(vat_type_id) from im_costs where cost_id in ([template::util::tcl_to_sql_list $source_invoice_id])" -default ""]
if {"" == $vat_type_id} {
    	set vat_type_id [db_string vat_info "select vat_type_id from im_companies where company_id = :company_id" -default ""]
}


# ---------------------------------------------------------------
# Modify some variable between the source and the target invoice
# ---------------------------------------------------------------

# Old one: add an "a" behind the invoice_nt to indicate
# a variant.
# set invoice_nr [im_invoice_nr_variant $org_invoice_nr]

# New One: Just create a new invoice nr
# for the target FinDoc type.

set invoice_nr $target_invoice_nr
if {"" == $invoice_nr} {
    set invoice_nr [im_next_invoice_nr -cost_type_id $target_cost_type_id]
}

set new_invoice_id [im_new_object_id]

ds_comment "company_id :: $company_id :: $provider_id"

# ---------------------------------------------------------------
# Update invoice base data
# ---------------------------------------------------------------

# Let's create the new invoice
set invoice_id [db_exec_plsql create_invoice "  select im_invoice__new (
          :new_invoice_id,		-- invoice_id
          'im_invoice',		-- object_type
          now(),			-- creation_date 
         :user_id,		-- creation_user
         '[ad_conn peeraddr]',	-- creation_ip
          null,			-- context_id
         :invoice_nr,		-- invoice_nr
         :company_id,		-- company_id
         :provider_id,		-- provider_id
         null,			-- company_contact_id
         :effective_date,		-- invoice_date
         'EUR',			-- currency
         :template_id,		-- invoice_template_id
                  :cost_status_id,	-- invoice_status_id
                  :target_cost_type_id,		-- invoice_type_id
                  :payment_method_id,	-- payment_method_id
                  :payment_days,		-- payment_days
                  0,			-- amount
                  null,			-- vat
                  null,			-- tax
                  ''			-- note
              )"]


# Give company_contact_id READ permissions - required for Customer Portal 
permission::grant -object_id $invoice_id -party_id $company_contact_id -privilege "read"

# Check if the cost item was changed via outside SQL
im_audit -object_type "im_invoice" -object_id $invoice_id -action before_update

# Get the vat from the vat_type_id
if {"" != $vat_type_id} {
    set vat [db_string get_int1 "select aux_int1 from im_categories where category_id = :vat_type_id"]
}

# Update the invoice itself
db_dml update_invoice "
update im_invoices 
set 
    invoice_nr	= :invoice_nr,
    payment_method_id = :payment_method_id,
    company_contact_id = :company_contact_id,
    invoice_office_id = :invoice_office_id
where
    invoice_id = :invoice_id
"


db_dml update_costs "
update im_costs
set
    project_id	= :project_id,
    cost_name	= :invoice_nr,
    customer_id	= :company_id,
    cost_nr		= :invoice_id,
    provider_id	= :provider_id,
    cost_status_id	= :cost_status_id,
    cost_type_id	= :target_cost_type_id,
    cost_center_id	= :cost_center_id,
    template_id	= :template_id,
    effective_date	= :effective_date,
    delivery_date   = :delivery_date,
    start_block	= ( select max(start_block) 
                from im_start_months 
                where start_block < :effective_date),
    payment_days	= :payment_days,
    payment_term_id	= :payment_term_id,
    variable_cost_p = 't',
    amount		= null,
    currency	= :invoice_currency,
    vat_type_id     = :vat_type_id
where
    cost_id = :invoice_id
"

# ---------------------------------------------------------------
# Associate the invoice with the project via acs_rels
# ---------------------------------------------------------------

foreach project_id $project_ids {
    set rel_id [db_exec_plsql create_rel "      select acs_rel__new (
             null,             -- rel_id
             'relationship',   -- rel_type
             :project_id,      -- object_id_one
             :invoice_id,      -- object_id_two
             null,             -- context_id
             null,             -- creation_user
             null             -- creation_ip
      )"]
}

# ---------------------------------------------------------------
# Associate the invoice with the source invoices via acs_rels
# ---------------------------------------------------------------

foreach source_id $source_invoice_id {
    if {$source_id >0} {
        set rel_id [db_exec_plsql create_invoice_rel "      select acs_rel__new (
             null,             -- rel_id
             'im_invoice_invoice_rel',   -- rel_type
             :source_id,      -- object_id_one
             :invoice_id,      -- object_id_two
             null,             -- context_id
             null,             -- creation_user
             null             -- creation_ip
          )"]
    }
}


# ---------------------------------------------------------------
# Create one invoice item per source invoice id
# ---------------------------------------------------------------

set sort_order 1
foreach source_id $source_invoice_id {

    if {$source_id > 0 } {
        db_1row source_invoice_info {
            select cost_name,project_id, amount, currency
            from im_costs where cost_id = :source_id
        }
        set item_id [db_nextval "im_invoice_items_seq"]

        set insert_invoice_items_sql "
        INSERT INTO im_invoice_items (
            item_id, item_name,
            project_id, invoice_id,
            item_units, item_uom_id,
            price_per_unit, currency,
            sort_order,
            item_source_invoice_id
        ) VALUES (
            :item_id, :cost_name,
            :project_id, :invoice_id,
            1, 322,
            :amount, :currency,
            :sort_order,
            :source_id
        )" 

        db_dml insert_invoice_items $insert_invoice_items_sql
        incr sort_order
    }
}


# ---------------------------------------------------------------
# Update the invoice amount and currency 
# based on the invoice items
# ---------------------------------------------------------------

set currencies [db_list distinct_currencies "
    select distinct
        currency
    from	    im_invoice_items
    where	invoice_id = :invoice_id
    and currency is not null
"]

if {1 != [llength $currencies]} {
    util_user_message -html -message "<b>[_ intranet-invoices.Error_multiple_currencies]:</b><br>
    [_ intranet-invoices.Blurb_multiple_currencies] <pre>$currencies</pre>"
}

set discount_perc 0.0
set surcharge_perc 0.0

# ---------------------------------------------------------------
# Update the invoice value
# ---------------------------------------------------------------

im_invoice_update_rounded_amount \
    -invoice_id $invoice_id \
    -discount_perc $discount_perc \
    -surcharge_perc $surcharge_perc

# ---------------------------------------------------------------
# Audit
# ---------------------------------------------------------------

im_audit -object_type "im_invoice" -object_id $invoice_id -action after_create -status_id $cost_status_id -type_id $target_cost_type_id

# ---------------------------------------------------------------
# Deal with the filename
# ---------------------------------------------------------------
set tmp_filename [ns_queryget upload_file.tmpfile]
if { 0 != [file size $tmp_filename] } {

    im_security_alert_check_tmpnam -location "upload-2" -value $tmp_filename
    ns_log Notice "upload-2: tmp_filename=$tmp_filename"
    set max_n_bytes [ad_parameter -package_id [im_package_filestorage_id] MaxNumberOfBytes "" 0]
    
    if { $max_n_bytes && ([file size $tmp_filename] > $max_n_bytes) } {
        ad_return_complaint 1 "Your file is larger than the maximum permissible upload size:  [util_commify_number $max_n_bytes] bytes"
        return 0
    }
    
    set file_extension [string tolower [file extension $upload_file]]
    # remove the first . from the file extension
    regsub "\." $file_extension "" file_extension
    set guessed_file_type [ns_guesstype $upload_file]
    set n_bytes [file size $tmp_filename]
    
    # strip off the C:\directories... crud and just get the file name
    if ![regexp {([^//\\]+)$} $upload_file match client_filename] {
        # couldn't find a match
        set client_filename $upload_file
    }
    
    if {[regexp {\.\.} $client_filename]} {
        set error "<li>Path contains forbidden characters<br>
        Please don't use '.' characters."
        ad_return_complaint "User Error" $error
    }
    
    # ---------- Check for charset compliance -----------
    
    set filename $client_filename
    set charset [ad_parameter -package_id [im_package_filestorage_id] FilenameCharactersSupported "" "alphanum"]
    if {![im_filestorage_check_filename $charset $filename]} {
        ad_return_complaint 1 [lang::message::lookup "" intranet-filestorage.Invalid_Character_Set "
                    <b>Invalid Character(s) found</b>:<br>
                    Your filename '%filename%' contains atleast one character that is not allowed
                    in your character set '%charset%'."]
        ad_script_abort
    }
    

    set base_path [im_filestorage_cost_path $invoice_id]
    if {"" == $base_path} {
        ad_return_complaint 1 "<LI>Unknown folder type \"$folder_type\"."
        return
    }
    set dest_path "$base_path/$client_filename"
    
    # --------------- Let's copy the file into the FS --------------------
    
    ns_log Notice "dest_path=$dest_path"
    if { [catch {
        exec /bin/mkdir -p $base_path
        exec /bin/chmod ug+w $base_path
        ns_log Notice "/bin/mv $tmp_filename $dest_path"
        exec /bin/cp $tmp_filename $dest_path
        ns_log Notice "/bin/chmod ug+w $dest_path"
        exec /bin/chmod ug+w $dest_path
    } err_msg] } {
        # Probably some permission errors
        ad_return_complaint  "Error writing upload file"  $err_msg
        return
    }
    
    # --------------- Log the interaction --------------------
    
    db_dml insert_action "
    insert into im_fs_actions (
            action_type_id,
            user_id,
            action_date,
            file_name
    ) values (
            [im_file_action_upload],
            :user_id,
            now(),
            :dest_path || '/' || :client_filename
    )"
}

db_release_unused_handles
ad_returnredirect "/intranet-invoices/view?invoice_id=$invoice_id"



