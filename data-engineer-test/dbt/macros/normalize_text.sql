
{% macro normalize_text(column) %}

    NULLIF(
        UPPER(
            TRIM(
                REGEXP_REPLACE(
                    CAST({{ column }} AS VARCHAR),
                    '\s+',
                    ' ',
                    'g'
                )
            )
        ),
        ''
    )

{% endmacro %}
