{
    "name": "sober",
    "title": "Трезвый водитель",
    "canCreate": true,
    "canRead": true,
    "canUpdate": true,
    "canDelete": true,
    "applications": [
        {
            "targets": [
                "fromAddress_address"
            ],
            "meta": {
                "label": "Где забрать"
            }
        },
        {
            "targets": [
                "toAddress_address"
            ],
            "meta": {
                "label": "Куда доставить"
            }
        },
        {
            "targets": [
                "soberContractor_partner"
            ],
            "meta": {
                "label": "Партнёр"
            }
        },
        {
            "targets": [
                "payment_payment"
            ],
            "meta": {
                "label": "Стоимость"
            }
        },
        {
            "targets": [
                "payment_paidByRUAMC",
                "payment_paidByClient"
            ],
            "canRead": [ "partner", "front", "back", "head", "parguy" ],
            "canWrite": [ "front", "back", "head", "parguy" ]
        },
        {
            "targets": [
                "fromAddress_address",
                "fromAddress_coords",
                "fromAddress_city",
                "fromAddress_comment"
            ],
            "canRead": [ "partner", "front", "back", "head", "parguy" ],
            "canWrite": [ "front", "back", "head" ]
        },
        {
            "targets": [
                "toAddress_address",
                "toAddress_coords",
                "toAddress_city",
                "toAddress_comment"
            ],
            "canRead": [ "partner", "front", "back", "head", "parguy" ],
            "canWrite": [ "front", "back", "head" ]
        },
        {
            "targets": [
                "soberContractor_partner",
                "soberContractor_partnerTable",
                "soberContractor_coords"
            ],
            "canRead": [ "partner", "front", "back", "head", "parguy" ],
            "canWrite": [ "front", "back", "head" ]
        },
        {
            "targets": [
                "expectedServiceStart",
                "factServiceStart",
                "expectedServiceEnd",
                "factServiceEnd",
                "expectedServiceFinancialClosure",
                "factServiceFinancialClosure",
                "expectedDealerInfo",
                "factDealerInfo",
                "expectedServiceClosure",
                "factServiceClosure"
            ],
            "meta": {
                "regexp": "datetime"
            }
        },
        {
            "targets": [
                "repairEndDate",
                "billingDate"
            ],
            "meta": {
                "regexp": "date"
            }
        }
    ],
    "fields": [
        {
            "name": "parentId",
            "canRead": true,
            "canWrite": true,
            "meta": {
                "invisible": true
            }
        },
        {
            "name": "payType",
            "canRead": [ "partner", "front", "back", "head", "parguy" ],
            "canWrite": [ "front", "back", "head", "parguy" ],
            "type": "dictionary",
            "meta": {
                "dictionaryName": "PaymentTypes",
                "label": "Тип оплаты"
            }
        },
        {
            "name": "payment",
            "canRead": [ "partner", "front", "back", "head", "parguy" ],
            "canWrite": [ "front", "back", "head", "parguy" ],
            "groupName": "payment"
        },
        {
            "name": "warrantyCase",
            "canRead": [ "partner", "front", "back", "head", "parguy" ],
            "canWrite": [ "back", "head", "parguy" ],
            "type": "checkbox",
            "meta": {
                "label": "Гарантийный случай"
            }
        },
        {
            "name": "expectedCost",
            "canRead": [ "partner", "front", "back", "head" ],
            "canWrite": [ "front", "back", "head" ],
            "meta": {
                "label": "Ожидаемая стоимость",
                "infoText": "expextedValue"
            }
        },
        {
            "name": "limitedCost",
            "canRead": [ "back", "head" ],
            "meta": {
                "label": "Предельная стоимость"
            }
        },
        {
            "name": "overcosted",
            "canRead": [ "partner", "front", "back", "head", "parguy" ],
            "type": "checkbox",
            "meta": {
                "label": "Стоимость превышена?"
            }
        },
        {
            "name": "partnerCost",
            "canRead": [ "back", "head", "parguy" ],
            "canWrite": [ "back", "head" ],
            "meta": {
                "label": "Стоимость со слов партнёра"
            }
        },
        {
            "name": "expectedServiceStart",
            "canRead": [ "partner", "front", "back", "head" ],
            "canWrite": [ "front", "back", "head" ],
            "type": "datetime",
            "meta": {
                "label": "Ожидаемое время начала оказания услуги",
                "infoText": "datetime"
            }
        },
        {
            "name": "factServiceStart",
            "canRead": [ "back", "head" ],
            "canWrite": [ "back", "head" ],
            "type": "datetime",
            "meta": {
                "label": "Фактическое  время начала оказания услуги",
                "infoText": "datetime"
            }
        },
        {
            "name": "expectedServiceEnd",
            "canRead": [ "back", "head" ],
            "canWrite": [ "back", "head" ],
            "type": "datetime",
            "meta": {
                "label": "Ожидаемое время окончания оказания услуги",
                "infoText": "datetime"
            }
        },
        {
            "name": "factServiceEnd",
            "canRead": [ "back", "head" ],
            "canWrite": [ "back", "head" ],
            "type": "datetime",
            "meta": {
                "label": "Фактическое время окончания оказания услуги",
                "infoText": "datetime"
            }
        },
        {
            "name": "expectedServiceFinancialClosure",
            "canRead": [ "back", "head" ],
            "canWrite": [ "back", "head" ],
            "type": "datetime",
            "meta": {
                "label": "Ожидаемое время финансового закрытия услуги",
                "infoText": "datetime"
            }
        },
        {
            "name": "factServiceFinancialClosure",
            "canRead": [ "back", "head" ],
            "canWrite": [ "back", "head" ],
            "type": "datetime",
            "meta": {
                "label": "Фактическое время финансового закрытия услуги",
                "infoText": "datetime"
            }
        },
        {
            "name": "expectedDealerInfo",
            "canRead": [ "back", "head" ],
            "canWrite": [ "back", "head" ],
            "type": "datetime",
            "meta": {
                "label": "Ожидаемое время получения информации от дилера",
                "infoText": "datetime"
            }
        },
        {
            "name": "factDealerInfo",
            "canRead": [ "back", "head" ],
            "canWrite": [ "back", "head" ],
            "type": "datetime",
            "meta": {
                "label": "Фактическое время получения информации от дилера",
                "infoText": "datetime"
            }
        },
        {
            "name": "expectedServiceClosure",
            "canRead": [ "back", "head" ],
            "canWrite": [ "back", "head" ],
            "type": "datetime",
            "meta": {
                "label": "Ожидаемое время закрытия услуги",
                "infoText": "datetime"
            }
        },
        {
            "name": "factServiceClosure",
            "canRead": [ "back", "head" ],
            "canWrite": [ "back", "head" ],
            "type": "datetime",
            "meta": {
                "label": "Фактическое время закрытия услуги",
                "infoText": "datetime"
            }
        },
        {
            "name": "repairEndDate",
            "canRead": [ "back", "head" ],
            "canWrite": [ "back", "head" ],
            "type": "date",
            "meta": {
                "label": "Дата окончания ремонта",
                "infoText": "date"
            }
        },
        {
            "name": "falseCall",
            "canRead": [ "partner", "front", "back", "head", "parguy" ],
            "canWrite": [ "front", "back", "head" ],
            "type": "dictionary",
            "meta": {
                "dictionaryName": "FalseStatuses",
                "label": "Ложный вызов",
                "infoText": "falsecall"
            }
        },
        {
            "name": "billingDate",
            "canRead": [ "head", "parguy" ],
            "canWrite": [ "parguy" ],
            "type": "date",
            "meta": {
                "label": "Дата выставления счёта",
                "infoText": "date"
            }
        },
        {
            "name": "billingCost",
            "canRead": [ "head", "parguy" ],
            "canWrite": [ "parguy" ],
            "meta": {
                "label": "Сумма по счёту"
            }
        },
        {
            "name": "billNumber",
            "canRead": [ "head", "parguy" ],
            "canWrite": [ "parguy" ],
            "meta": {
                "label": "Номер счёта"
            }
        },
        {
            "name": "fromAddress",
            "canRead": [ "partner", "front", "back", "head", "parguy" ],
            "canWrite": [ "front", "back", "head" ],
            "groupName": "address",
            "meta": {
                "label": "Где забрать"
            }
        },
        {
            "name": "toAddress",
            "canRead": [ "partner", "front", "back", "head", "parguy" ],
            "canWrite": [ "front", "back", "head" ],
            "groupName": "address",
            "meta": {
                "label": "Куда доставить"
            }
        },
        {
            "name": "soberContractor",
            "canRead": [ "partner", "front", "back", "head", "parguy" ],
            "canWrite": [ "front", "back", "head" ],
            "groupName": "partner",
            "meta": {
                "label": "Название партнёра"
            }
        },
        {
            "name": "multidrive",
            "canRead": [ "partner", "front", "back", "head", "parguy" ],
            "canWrite": [ "front", "back", "head" ],
            "meta": {
                "label": "Мультидрайв"
            },
            "type": "checkbox"
        },
        {
            "name": "status",
            "canRead": [ "partner", "front", "back", "head", "parguy" ],
            "canWrite": [ "front", "back", "head", "parguy" ],
            "type": "dictionary",
            "meta": {
                "label": "Статус услуги",
                "dictionaryName": "ServiceStatuses"
            }
        },
        {
            "name": "clientSatisfied",
            "canRead": [ "partner", "front", "back", "head", "parguy" ],
            "canWrite": [ "back", "head" ],
            "type": "checkbox",
            "meta": {
                "label": "Клиент доволен"
            }
        }
    ]
}
