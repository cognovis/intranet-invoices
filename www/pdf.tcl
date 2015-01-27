# packages/intranet-invoices/www/pdf.tcl
#
# Copyright (c) 2015, cognovís GmbH, Hamburg, Germany
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
    
    Return a PDF of the invoice
    
    @author Malte Sussdorff (malte.sussdorff@cognovis.de)
    @creation-date 2011-04-27
    @cvs-id $Id$
} {
    invoice_id:notnull
    {new_revision_p "0"}
    {return_url ""}
} 

set page_title "[_ intranet-invoices.Invoice_Mail]"

set invoice_nr [db_string name "select invoice_nr from im_invoices where invoice_id = :invoice_id"]

set invoice_item_id [content::item::get_id_by_name -name "${invoice_nr}.pdf" -parent_id $invoice_id]
if {"" == $invoice_item_id || $new_revision_p} {
    set invoice_revision_id [intranet_openoffice::invoice_pdf -invoice_id $invoice_id]
} else {
    set invoice_revision_id [content::item::get_best_revision -item_id $invoice_item_id]
}


set outputheaders [ns_conn outputheaders]
ns_set cput $outputheaders "Content-Disposition" "attachment; filename=${invoice_nr}.pdf"
ns_returnfile 200 application/pdf [content::revision::get_cr_file_path -revision_id $invoice_revision_id]