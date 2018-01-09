# AbapSimpleQueryBuilder
Very simple query builder (query optimizer)

Sometimes the developer needs to create join queries (selects) dynamically based on required fields and filter criteria. Let's say you have a huge join with many tables. Some of the tables are used only in special scenarios, so in other scenarios these tables will only slow down your select. This simple query builder offers you a solution. It's far from perfect, but it works. :) Query builder will create result field list, from clause and where criteria dynamically as a string. What's important it will add only "touched" tables (which appears in field list or where clause). 
# Example
I need to select all orders from table CRMD_ORDERADM_H. First step is to create the query builder object. By default the query builder uses the OpenSQL syntax, so all variables (from ABAP code) must have character “@” as prefix.
```ABAP
DATA(lro_qb) = NEW lcl_query_builder( table = 'CRMD_ORDERADM_H' alias = 'H' ).
```
Add another table, define the JOIN:
```ABAP
lro_qb->add_join( table = 'CRMD_ORDER_INDEX' alias = 'IC' pred = 'H' on = 'IC~HEADER EQ H~GUID' ).
```
Add criteria and result fields:
```ABAP
lro_qb->add_where( field = 'H~PROCESS_TYPE' op = 'EQ' value = |'PRTY'| ).
lro_qb->add_result( 'H~GUID' ).
lro_qb->add_result( 'H~OBJECT_ID' ).
lro_qb->add_result( 'H~PROCESS_TYPE' ).
```
In some scenarios the user wants to filter by some partner function and he wants to see this partner function in the result. The partner range is in global range GT_COMPT. To add this range to where clause use method ADD_WHERE and in value write the name of the range variable with prefix “@”. Because this value will be concatenated into dynamic WHERE string in case of string constants you have to add also single quotes.
```ABAP
IF gt_compt[] IS NOT INITIAL.
  lro_qb->add_where( field = 'IC~PARTNER_NO'  value = '@GT_COMPT' ).
  lro_qb->add_where( field = 'IC~PFT_9'       op = 'EQ' value = |'X'| ).
  lro_qb->add_result( field = 'IC~PARTNER_NO' alias = 'COMPETITOR_NO' ).
ENDIF.
```
Finally let’s create the strings:
```ABAP
DATA(lv_result) = lro_qb->get_result( ).
DATA(lv_from)   = lro_qb->get_from( ).
DATA(lv_where)  = lro_qb->get_where( ).
```
Execute the select:
```ABAP
SELECT (lv_result)
    INTO CORRESPONDING FIELDS OF lt_data
  FROM (lv_from)
 WHERE (lv_where).
```
The result:
If the gt_compt[] contains some data the following select will be executed:
```ABAP
SELECT H~GUID, H~OBJECT_ID, H~PROCESS_TYPE, IC~PARTNER_NO AS COMPETITOR_NO
  FROM CRMD_ORDERADM_H AS H 
  JOIN CRMD_ORDER_INDEX AS IC 
    ON IC~HEADER EQ H~GUID
 WHERE H~PROCESS_TYPE EQ 'PRTY' 
   AND IC~PARTNER_NO IN @GT_COMPT 
   AND IC~PFT_9 EQ 'X'.
```
otherwise:
```ABAP
SELECT H~GUID, H~OBJECT_ID, H~PROCESS_TYPE
  FROM CRMD_ORDERADM_H AS H
 WHERE H~PROCESS_TYPE EQ 'PRTY'.
```
