# packages/intranet-mail/www/reply.tcl
#
# Copyright (c) 2011, cognovís GmbH, Hamburg, Germany
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see
# <http://www.gnu.org/licenses/>.
#
 
ad_page_contract {
    
    Allow to reply to write a new E-Mail
    
    @author Malte Sussdorff (malte.sussdorff@cognovis.de)
    @creation-date 2011-04-27
    @cvs-id $Id$
} {
    invoice_id:notnull
    {return_url ""}
} 

set page_title "[_ intranet-invoices.Invoice_Mail]"

db_1row invoice_info "select invoice_nr,last_modified from im_invoices,acs_objects where invoice_id = :invoice_id and invoice_id = object_id"

set invoice_item_id [content::item::get_id_by_name -name "${invoice_nr}.pdf" -parent_id $invoice_id]

if {"" == $invoice_item_id} {
    set invoice_revision_id [intranet_openoffice::invoice_pdf -invoice_id $invoice_id]
} else {
    set invoice_revision_id [content::item::get_best_revision -item_id $invoice_item_id]

    # Check if we need to create a new revision
    if {[db_string date_check "select 1 from acs_objects where object_id = :invoice_revision_id and last_modified < :last_modified" -default 0]} {
        set invoice_revision_id [intranet_openoffice::invoice_pdf -invoice_id $invoice_id]
    }
}

set user_id [ad_conn user_id]

if {![db_0or1row related_projects_sql "
        select distinct
        r.object_id_one as project_id,
        p.project_name,
        project_lead_id,
        im_name_from_id(project_lead_id) as project_manager,
        p.project_nr,
        p.parent_id,
        p.description,
        trim(both p.company_project_nr) as customer_project_nr
    from
            acs_rels r,
        im_projects p
    where
        r.object_id_one = p.project_id
        and r.object_id_two = :invoice_id
        order by project_id desc
        limit 1
"]} {
    set project_name ""
    set project_manager [im_name_from_user_id $user_id]
    set project_lead_id $user_id
    set customer_project_nr ""
    set project_nr ""
}

set recipient_id [db_string company_contact_id "select company_contact_id from im_invoices where invoice_id = :invoice_id" -default $user_id]

db_1row user_info "select first_names, last_name from persons where person_id = :recipient_id"

# Get the type information so we can get the strings
set invoice_type_id [db_string type "select cost_type_id from im_costs where cost_id = :invoice_id"]

set recipient_locale [lang::user::locale -user_id $recipient_id]
set subject [lang::util::localize "#intranet-invoices.invoice_email_subject_${invoice_type_id}#" $recipient_locale]
set body [lang::util::localize "#intranet-invoices.invoice_email_body_${invoice_type_id}#" $recipient_locale]
if {![ad_looks_like_html_p $body]} {
    set body [ad_text_to_html $body]
}
