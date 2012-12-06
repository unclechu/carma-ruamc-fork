{
    "name": "vin",
    "title": "VIN",
    "canCreate": false,
    "canRead": true,
    "canUpdate": true,
    "canDelete": false,
    "applications": [
        {
            "targets": true,
            "canWrite": true,
            "canRead": true
        }
    ],
    "fields": [
        {
            "name": "car",
            "canRead": [ "partner", "front", "back", "head", "parguy", "account" ],
            "groupName": "car"
        },
        {
            "name": "cardNumber",
            "canRead": [ "partner", "front", "back", "head", "parguy", "account" ],
            "groupName": "cardNumber"
        },
        {
            "name": "contact",
            "canRead": [ "partner", "front", "back", "head", "parguy", "account" ],
            "canWrite": [ "front", "back", "head", "parguy" ],
            "groupName": "carContact",
            "meta": {
                "label": "Владелец",
                "infoText": "ownerName"
            }
        }

    ]
}
