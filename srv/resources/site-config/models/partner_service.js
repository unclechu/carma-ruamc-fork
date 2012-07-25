
{
    "name": "partner_service",
    "title": "Тариф",
    "canCreate": true,
    "canRead": true,
    "canUpdate": true,
    "canDelete": true,
    "applications": [
        {
            "targets": true,
            "canWrite": true,
            "canRead": true
        }
    ],
    "fields": [
        {
            "name": "serviceName",
            "type": "dictionary",
            "meta": {
                "dictionaryName": "Services",
                "label": "Услуга"
            }
        },
        {
            "name": "tarifName",
            "meta": {
                "label": "Тарифная опция"
            }
        },
        {
            "name": "price1",
            "meta": {
                "label": "Стоимость за единицу за нал"
            }
        },
        {
            "name": "price2",
            "meta": {
                "label": "Стоимость за единицу по безналу"
            }
        }
    ]
}
