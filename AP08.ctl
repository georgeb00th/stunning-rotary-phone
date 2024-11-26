LOAD DATA
INFILE *
APPEND
INTO TABLE AP_INVOICE_IFACE_STG_08
FIELDS TERMINATED BY "," 
OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
(
 invoice_type
, invoice_num
, curr_code                                
, vendor_number                                              
, vendor_site 
, payment_term
, line_number
, description 
, header_amount 
, line_amount
, source   
, distribution_set_name )