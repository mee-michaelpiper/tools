  METHOD read_mat_classification_detail.

    CREATE OBJECT mo_class.

    set_class_attributes( ).

    mo_class->get_classes( ).

  ENDMETHOD.
