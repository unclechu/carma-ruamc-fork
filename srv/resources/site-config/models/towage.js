{
    "name": "towage",
    "title": "Эвакуация",
    "canCreate": true,
    "canRead": true,
    "canUpdate": true,
    "canDelete": true,
    "applications": [
        {
            "targets": [
                "towAddress_address"
            ],
            "meta": {
                "label": "Адрес доставки"
            }
        },
        {
            "targets": [
                "towerAddress_address"
            ],
            "meta": {
                "label": "Адрес выезда эвакуатора"
            }
        },
        {
            "targets": [
                "towDealer_partner"
            ],
            "meta": {
                "label": "Дилер"
            }
        },
        {
            "targets": [
                "towContractor_partner"
            ],
            "meta": {
                "label": "Партнёр"
            }
        },
        {
            "targets": [
                "towAddress_address",
                "towAddress_coords",
                "towAddress_city",
                "towAddress_comment"
            ],
            "canRead": [ "partner", "front", "back", "head", "parguy" ],
            "canWrite": [ "front", "back", "head" ]
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
                "towerAddress_address",
                "towerAddress_coords",
                "towerAddress_city",
                "towerAddress_comment"
            ],
            "canRead": [ "partner", "front", "back", "head", "parguy" ],
            "canWrite": [ "front", "back", "head" ]
        },
        {
            "targets": [
                "towDealer_partner",
                "towDealer_partnerTable",
                "towDealer_coords"
            ],
            "canRead": [ "partner", "front", "back", "head", "parguy" ],
            "canWrite": [ "front", "back", "head" ]
        },
        {
            "targets": [
                "towContractor_partner",
                "towContractor_partnerTable",
                "towContractor_coords"
            ],
            "canRead": [ "partner", "front", "back", "head", "parguy" ],
            "canWrite": [ "front", "back", "head" ]
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
            "name": "towerType",
            "canRead": [ "partner", "front", "back", "head", "parguy" ],
            "canWrite": [ "front", "back", "head" ],
            "meta": {
                "dictionaryName": "TowerTypes",
                "label": "Тип эвакуатора"
            },
            "index": true,
            "type": "dictionary"
        },
        {
            "name": "towType",
            "canRead": [ "partner", "front", "back", "head", "parguy" ],
            "canWrite": [ "front", "back", "head" ],
            "meta": {
                "dictionaryName": "TowTypes",
                "label": "Вид эвакуации"
            },
            "type": "dictionary"
        },
        {
            "name": "vandalism",
            "canRead": [ "partner", "front", "back", "head", "parguy" ],
            "canWrite": [ "front", "back", "head" ],
            "meta": {
                "label": "Случай вандализма"
            },
            "type": "checkbox"
        },
        {
            "name": "accident",
            "canRead": [ "partner", "front", "back", "head", "parguy" ],
            "canWrite": [ "front", "back", "head" ],
            "meta": {
                "label": "ДТП"
            },
            "type": "checkbox"
        },
        {
            "name": "caseAddress",
            "canRead": [ "partner", "front", "back", "head", "parguy" ],
            "canWrite": [ "front", "back", "head" ],
            "groupName": "address"
        },
        {
            "name": "towDealer",
            "canRead": [ "partner", "front", "back", "head", "parguy" ],
            "canWrite": [ "front", "back", "head" ],
            "groupName": "partner",
            "meta": {
                "label": "Дилер"
            }
        },
        {
            "name": "towerAddress",
            "canRead": [ "partner", "front", "back", "head", "parguy" ],
            "canWrite": [ "front", "back", "head" ],
            "groupName": "address",
            "meta": {
                "label": "Адрес выезда эвакуатора"
            }
        },
        {
            "name": "towAddress",
            "canRead": [ "partner", "front", "back", "head", "parguy" ],
            "canWrite": [ "front", "back", "head" ],
            "groupName": "address",
            "meta": {
                "label": "Адрес доставки"
            }
        },
        {
            "name": "towContractor",
            "canRead": [ "partner", "front", "back", "head", "parguy" ],
            "canWrite": [ "front", "back", "head" ],
            "groupName": "partner",
            "meta": {
                "label": "Партнёр"
            }
        },
        {
            "name": "wheelsUnblocked",
            "canRead": [ "partner", "front", "back", "head", "parguy" ],
            "canWrite": [ "front", "back", "head" ],
            "meta": {
                "dictionaryName": "WheelsBlockedCount",
                "label": "Количество заблокированных колёс"
            },
            "type": "dictionary"
        },
        {
            "name": "canNeutral",
            "canRead": [ "partner", "front", "back", "head", "parguy" ],
            "canWrite": [ "front", "back", "head" ],
            "meta": {
                "label": "Переключается на нейтральную передачу"
            },
            "type": "checkbox"
        },
        {
            "name": "towingPointPresent",
            "canRead": [ "partner", "front", "back", "head", "parguy" ],
            "canWrite": [ "front", "back", "head" ],
            "meta": {
                "label": "Есть буксировочный крюк"
            },
            "type": "checkbox"
        },
        {
            "name": "manipulatorPossible",
            "canRead": [ "partner", "front", "back", "head", "parguy" ],
            "canWrite": [ "front", "back", "head" ],
            "meta": {
                "label": "Есть место для манипулятора"
            },
            "type": "checkbox"
        },
        {
            "name": "suburbanMilage",
            "canRead": [ "partner", "front", "back", "head", "parguy" ],
            "canWrite": [ "front", "back", "head" ],
            "meta": {
                "label": "Пробег эвакуатора за городом"
            }
        },        
        {
            "name": "orderNumber",
            "canRead": [ "back", "head" ],
            "canWrite": [ "back", "head" ],
            "type": "date",
            "meta": {
                "label": "Номер заказ-наряда"
            }
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
