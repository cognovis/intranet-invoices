-- 
-- packages/intranet-invoices/sql/postgresql/upgrade/upgrade-4.1.0.0.0-4.1.0.0.1.sql
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
-- @creation-date 2012-01-06
-- @cvs-id $Id$
--

SELECT acs_log__debug('/packages/intranet-invoices/sql/postgresql/upgrade/upgrade-4.1.0.0.0-4.1.0.0.1.sql','');

-- Absolute value of the tax in case we have penny deviations between our calculation and the accounting system
-- due to rounding issues
alter table im_costs add column tax_amount numeric(12,3);
alter table im_costs add column vat_amount numeric(12,3);

-- Calculate the tax amount for every cost item which is not of material based tax calculation
update im_costs set vat_amount = amount * (100+ vat) / 100 - amount;
update im_costs set tax_amount = amount * (100+ tax) / 100 - amount;

