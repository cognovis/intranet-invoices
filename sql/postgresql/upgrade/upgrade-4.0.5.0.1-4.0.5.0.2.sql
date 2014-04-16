-- 
-- packages/intranet-collmex/sql/postgresql/upgrade/upgrade-4.0.5.0.1-4.0.5.0.2.sql
-- 
-- Copyright (c) 2011, cognovís GmbH, Hamburg, Germany
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
-- 
-- @author <yourname> (<your email>)
-- @creation-date 2012-01-27
-- @cvs-id $Id$
--

SELECT acs_log__debug('/packages/intranet-invoices/sql/postgresql/upgrade/upgrade-4.0.5.0.1-4.0.5.0.2.sql','');

-- Add category that marks the VAT to be calculated on line item level
SELECT im_category_new (42021,'Material Based Taxation','Intranet VAT Type');
update im_categories set aux_int1=0 where category_id = 42021;


