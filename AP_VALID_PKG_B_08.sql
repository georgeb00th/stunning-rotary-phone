-- Package Body definition for AP_VALID_PKG_08
CREATE OR REPLACE PACKAGE BODY AP_VALID_PKG_08 AS
   -- Global variables declaration
   gn_request_id       NUMBER;            -- Request ID placeholder
   gn_user_id          NUMBER;            -- User ID placeholder
   gn_org_id           NUMBER;            -- Organization ID used in transactions
   gn_organization_id  NUMBER;            -- Additional Organization ID, may be unused here
   gc_val_status       VARCHAR2(10) := 'VALIDATED'; -- Constant for validated status
   gc_err_status       VARCHAR2(10) := 'ERROR';     -- Constant for error status
   gc_new_status       VARCHAR2(10) := 'NEW';       -- Constant for new status

   -- Main procedure to handle AP invoice processing
   PROCEDURE main(p_errbuf OUT NOCOPY VARCHAR2,
                  p_retcode OUT NOCOPY NUMBER) IS
      -- Local variables
      v_vendor_id      NUMBER;             -- Vendor ID placeholder
      v_vendor_site_id NUMBER;             -- Vendor site ID placeholder
      v_invoice_id     NUMBER;             -- Invoice ID placeholder

      -- Cursor to fetch data from AP_INVOICE_IFACE_STG_08 table
      CURSOR cur_ap_order IS
         SELECT invoice_type,
                invoice_num,
                curr_code,
                vendor_number,
                vendor_site,
                payment_term,
                header_amount,
                line_number,
                description,
                line_amount,
                source
         FROM AP_INVOICE_IFACE_STG_08;

   BEGIN
      -- Initialize gn_org_id using profile value, default to 204 if null
      gn_org_id := NVL(fnd_profile.value('ORG_ID'), 204);

      -- Iterate over each row in cur_ap_order cursor
      FOR j IN cur_ap_order LOOP
         BEGIN

            -- Insert into AP_INVOICES_INTERFACE table
            INSERT INTO AP_INVOICES_INTERFACE(INVOICE_ID, INVOICE_NUM, INVOICE_TYPE_LOOKUP_CODE,
                                              VENDOR_ID, VENDOR_SITE_ID, INVOICE_AMOUNT, 
                                              PAYMENT_CURRENCY_CODE, INVOICE_DATE, SOURCE, ORG_ID)
            VALUES (AP_INVOICES_INTERFACE_S.NEXTVAL, j.invoice_num, j.invoice_type,
                    v_vendor_id, v_vendor_site_id, j.header_amount, j.curr_code,
                    SYSDATE, j.source, gn_org_id)
            RETURNING INVOICE_ID INTO v_invoice_id;

            -- Loop through cur_ap_order cursor again for line items
            FOR j IN cur_ap_order LOOP
               -- Generate new vendor site ID
               SELECT AP_INVOICE_LINES_INTERFACE_S.NEXTVAL
               INTO v_vendor_site_id
               FROM DUAL;

               -- Insert into AP_INVOICE_LINES_INTERFACE table
               INSERT INTO AP_INVOICE_LINES_INTERFACE(INVOICE_LINE_ID, INVOICE_ID, LINE_NUMBER,
                                                      LINE_TYPE_LOOKUP_CODE, AMOUNT, DESCRIPTION, 
                                                      ORG_ID, ACCOUNTING_DATE)
               VALUES (AP_INVOICE_LINES_INTERFACE_S.NEXTVAL, v_invoice_id, j.line_number, 'ITEM', 
                       j.line_amount, j.description, gn_org_id, SYSDATE);

               -- Log success message
               fnd_file.put_line(fnd_file.log, 'A Line was inserted: The Invoice ID was: ' || AP_INVOICES_INTERFACE_S.CURRVAL);
            END LOOP;

         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               -- Log error if vendor number is not found
               fnd_file.put_line(fnd_file.log, 'Vendor Number does not exist: ' || j.vendor_number);
            WHEN OTHERS THEN
               -- Log any other errors that occur
               fnd_file.put_line(fnd_file.log, 'The Error: ' || SQLERRM);
               RAISE;  -- Rethrow the exception
         END;
      END LOOP;

      -- Commit the transaction after all rows are processed
      COMMIT;
   END main;
END AP_VALID_PKG_08;