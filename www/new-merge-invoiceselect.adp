<master src="../../intranet-core/www/master">
<property name="title">@page_title;noquote@</property>
<property name="main_navbar_label">finance</property>

<%= [im_costs_navbar "none" "/intranet/invoices/index" "" "" [list]] %>

<div id="fullwidth-list" class="fullwidth-list-no-side-bar">
<form action=new-merge enctype=multipart/form-data method=POST>
<%= [export_form_vars cost_type_id cost_status_id source_cost_type_id target_cost_type_id provider_id customer_id company_id return_url] %>

  <table cellpadding=0 cellspacing=10 bordercolor=#6699CC border=0>
  <tr valign=top> 
    <td>
  
      <table border=0 cellPadding=0 cellspacing=2 width=100%>
      <tr>
        <td  class=rowodd>@target_cost_type@ nr.:</td>
        <td  class=rowodd> 
          <input type=text name=target_invoice_nr size=15>
        </td>
      </tr>
    <tr> 
      <td  class=roweven>@target_cost_type@ date:</td>
      <td  class=roweven> 
        <input type=text name=target_invoice_date size=15 value='@effective_date@'>
      </td>
    </tr>
          <tr> 
	          <td class=rowodd>Payment Method</td>
	          <td class=rowodd>@payment_method_select;noquote@</td>
	        </tr>
	        <tr> 
	          <td class=roweven>#intranet-invoices.Payment_terms#</td>
	          <td class=rowodd>@payment_term_select;noquote@</td>
	        </tr>
          <tr> 
	          <td class=roweven>#intranet-invoices.Invoice_Currency#</td>
	          <td class=rowodd>@invoice_currency_select;noquote@</td>
	        </tr>    </table>  
    </td>
    <td>
    <table border=0 cellPadding=0 cellspacing=2 width=100%>
  @dynfield_attributes_html;noquote@
      </table>
    </td>
    <td>  
        <table border=0>
          <tr>
            <td align=left>#intranet-filestorage.Filename#</td>
           </tr>
           <tr> 
            <td>
              <input type=file name=upload_file size=30>
    <%= [im_gif help "Use the 'Browse...' button to locate your file, then click 'Open'."] %>
            </td>
          </tr>
        </table>
       </td> 
   </tr>     
</table>
  <table width=100% cellpadding=2 cellspacing=2 border=0>
    @table_header_html;noquote@
    @table_body_html;noquote@

    <tr><td colspan=@colspan@ class=rowplain align=right>
	<input type=submit value="@submit_button_text@">
    </td></tr>

    @table_continuation_html;noquote@
  </table>
</form>
</div>