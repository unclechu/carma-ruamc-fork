{
    "name": "smsTpl",
    "title": "Шаблон смс",
    "canCreate": true,
    "canRead": true,
    "canUpdate": true,
    "canDelete": true,
    "fields": [
      {
        "name":"name",
        "canRead": true,
        "canWrite": true,
        "meta": {
            "label": "Имя шаблона"
        }
      },
      {
        "name":"text",
        "canRead": true,
        "canWrite": true,
        "type": "textarea",
        "meta": {
            "label": "Текст"
        }
      },
      {
        "name": "smsReciever",
        "canRead": true,
        "canWrite": true,
        "type": "dictionary",
        "meta": {
          "dictionaryName": "SmsRecieverNames",
          "label": "Кому отправлять"
        }
      },
      {
        "name": "isActive",
        "type": "checkbox",
        "canRead": true,
        "canWrite": true,
        "meta": {
            "label": "Активный"
        }
      }
    ]
}