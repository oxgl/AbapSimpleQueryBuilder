***************************************************************************
* Program:    ZBC_SIMPLE_QUERY_BUILDER                                    *
* Developer:  Oxyggen s.r.o.                                              *
***************************************************************************

CLASS lcl_query_builder DEFINITION.

  PUBLIC SECTION.
    METHODS:
      constructor
        IMPORTING
          table   TYPE csequence
          alias   TYPE csequence OPTIONAL
          opensql TYPE abap_bool DEFAULT abap_true,

      add_join
        IMPORTING
          table TYPE csequence
          alias TYPE csequence OPTIONAL
          pred  TYPE csequence OPTIONAL
          on    TYPE csequence OPTIONAL,

      add_result
        IMPORTING
          field TYPE csequence
          alias TYPE csequence OPTIONAL,

      add_where
        IMPORTING
          field TYPE csequence
          op    TYPE csequence DEFAULT 'IN'
          value TYPE csequence,

      get_result
        RETURNING
          VALUE(rv_result) TYPE string,

      get_from
        RETURNING
          VALUE(rv_from) TYPE string,

      get_where
        RETURNING
          VALUE(rv_where) TYPE string,

      execute
        EXPORTING
          et_result TYPE ANY TABLE,

      open_cursor
        CHANGING
          cursor TYPE cursor.


  PRIVATE SECTION.
    TYPES:
      BEGIN OF ts_table,
        table TYPE string,
        alias TYPE string,
        pred  TYPE string,
        on    TYPE string,
        used  TYPE abap_bool,
      END OF ts_table.

    TYPES:
      tt_tables TYPE STANDARD TABLE OF ts_table WITH DEFAULT KEY.

    TYPES:
      BEGIN OF ts_result,
        field TYPE string,
        alias TYPE string,
      END OF ts_result.

    TYPES:
      tt_result TYPE STANDARD TABLE OF ts_result WITH DEFAULT KEY.

    TYPES:
      BEGIN OF ts_where,
        field TYPE string,
        op    TYPE string,
        value TYPE string,
      END OF ts_where.

    TYPES:
      tt_where TYPE STANDARD TABLE OF ts_where WITH DEFAULT KEY.

    DATA:
      gv_opensql TYPE abap_bool,
      gt_tables  TYPE tt_tables,
      gt_result  TYPE tt_result,
      gt_where   TYPE tt_where.

    METHODS:
      set_used
        IMPORTING
          alias TYPE string.


ENDCLASS.


CLASS lcl_query_builder IMPLEMENTATION.

  METHOD constructor.
    gv_opensql = opensql.
    APPEND VALUE #(
            table = to_upper( table )
            alias = to_upper( alias )
           ) TO gt_tables.
  ENDMETHOD.

  METHOD set_used.
    SPLIT alias AT `~` INTO DATA(lv_table_alias) DATA(lv_field).

    READ TABLE gt_tables ASSIGNING FIELD-SYMBOL(<fss_table>)
      WITH KEY alias = to_upper( lv_table_alias ).

    CHECK sy-subrc IS INITIAL.

    CHECK <fss_table>-used NE abap_true.

    <fss_table>-used = abap_true.
    IF <fss_table>-pred IS NOT INITIAL.
      SPLIT <fss_table>-pred AT ',' INTO TABLE DATA(lt_pred).
      LOOP AT lt_pred ASSIGNING FIELD-SYMBOL(<fsv_pred>).
        set_used( alias = <fsv_pred> ).
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

  METHOD add_join.
    DATA(lv_table) = to_upper( table ).
    DATA(lv_alias) = to_upper( alias ).

    IF NOT line_exists( gt_tables[ table = lv_table alias = lv_alias ] ).
      APPEND VALUE #(
              table = lv_table
              alias = lv_alias
              pred  = to_upper( pred )
              on    = on
             ) TO gt_tables.
    ENDIF.
  ENDMETHOD.

  METHOD add_result.
    APPEND VALUE #(
            field = field
            alias = alias ) TO gt_result.
    set_used( field ).
  ENDMETHOD.

  METHOD add_where.
    APPEND VALUE #(
            field = field
            op    = op
            value = value ) TO gt_where.
    set_used( field ).
  ENDMETHOD.

  METHOD get_result.
    LOOP AT gt_result ASSIGNING FIELD-SYMBOL(<fss_result>).
      IF rv_result IS NOT INITIAL.
        IF gv_opensql EQ abap_true.
          rv_result = rv_result && `, `.
        ELSE.
          rv_result = rv_result && ` `.
        ENDIF.
      ENDIF.
      rv_result = rv_result && <fss_result>-field.
      IF <fss_result>-alias IS NOT INITIAL.
        rv_result = rv_result && ` AS ` && <fss_result>-alias.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_from.
    READ TABLE gt_tables ASSIGNING FIELD-SYMBOL(<fss_table>) INDEX 1.

    rv_from = <fss_table>-table.
    IF <fss_table>-alias IS NOT INITIAL.
      rv_from = rv_from && ` AS ` && <fss_table>-alias.
    ENDIF.

    LOOP AT gt_tables ASSIGNING <fss_table>
                           FROM 2
                          WHERE used   EQ abap_true.
      rv_from = rv_from && ` JOIN ` && <fss_table>-table.
      IF <fss_table>-alias IS NOT INITIAL.
        rv_from = rv_from && ` AS ` && <fss_table>-alias.
      ENDIF.
      rv_from = rv_from && ` ON ` && <fss_table>-on.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_where.
    LOOP AT gt_where ASSIGNING FIELD-SYMBOL(<fss_where>).
      IF rv_where IS NOT INITIAL.
        rv_where = rv_where && ` AND `.
      ENDIF.
      rv_where = rv_where && <fss_where>-field && ` ` && <fss_where>-op && ` ` && <fss_where>-value.
    ENDLOOP.
  ENDMETHOD.

  METHOD execute.
    " Convert to text values
    DATA(lv_result) = get_result( ).
    DATA(lv_from)   = get_from( ).
    DATA(lv_where)  = get_where( ).

    " Execute select
    IF gv_opensql EQ abap_true.
      SELECT (lv_result)
        INTO CORRESPONDING FIELDS OF TABLE @et_result
        FROM (lv_from)
       WHERE (lv_where).
    ELSE.
      SELECT (lv_result)
        INTO CORRESPONDING FIELDS OF TABLE et_result
        FROM (lv_from)
       WHERE (lv_where).
    ENDIF.
  ENDMETHOD.

  METHOD open_cursor.
    " Convert to text values
    DATA(lv_result) = get_result( ).
    DATA(lv_from)   = get_from( ).
    DATA(lv_where)  = get_where( ).

    " Execute select
    IF gv_opensql EQ abap_true.
      OPEN CURSOR @cursor
       FOR SELECT (lv_result)
        FROM (lv_from)
       WHERE (lv_where).
    ELSE.
      OPEN CURSOR cursor
       FOR SELECT (lv_result)
        FROM (lv_from)
       WHERE (lv_where).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
