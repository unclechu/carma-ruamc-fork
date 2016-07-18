#!/bin/bash
$PSQL -f baseline/1-tables/8-PartnerDelay.sql

$PSQL <<EOF
insert into "FieldPermission" (role, model, field, r, w) values
  (1, 'PartnerDelay', 'id', 't', 'f'),
  (1, 'PartnerDelay', 'ctime', 't', 'f'),
  (1, 'PartnerDelay', 'caseId', 't', 'f'),
  (1, 'PartnerDelay', 'serviceId', 't', 'f'),
  (1, 'PartnerDelay', 'partnerId', 't', 'f'),
  (1, 'PartnerDelay', 'owner', 't', 'f'),
  (1, 'PartnerDelay', 'delayReason', 't', 'f'),
  (1, 'PartnerDelay', 'delayReasonComment', 't', 'f'),
  (1, 'PartnerDelay', 'delayMinutes', 't', 'f'),
  (1, 'PartnerDelay', 'notified', 't', 'f'),
  (1, 'PartnerDelay', 'delayConfirmed', 't', 'f'),
  (1, 'PartnerDelay', 'exceptional', 't', 'f'),
  (1, 'PartnerDelay', 'exceptionalComment', 't', 'f'),
  (14, 'PartnerDelay', 'id', 't', 't'),
  (14, 'PartnerDelay', 'ctime', 't', 't'),
  (14, 'PartnerDelay', 'caseId', 't', 't'),
  (14, 'PartnerDelay', 'serviceId', 't', 't'),
  (14, 'PartnerDelay', 'partnerId', 't', 't'),
  (14, 'PartnerDelay', 'owner', 't', 't'),
  (14, 'PartnerDelay', 'delayReason', 't', 't'),
  (14, 'PartnerDelay', 'delayReasonComment', 't', 't'),
  (14, 'PartnerDelay', 'delayMinutes', 't', 't'),
  (14, 'PartnerDelay', 'notified', 't', 't'),
  (14, 'PartnerDelay', 'delayConfirmed', 't', 't'),
  (14, 'PartnerDelay', 'exceptional', 't', 't'),
  (14, 'PartnerDelay', 'exceptionalComment', 't', 't'),
  (1, 'PartnerDelay_Reason', 'id', 't', 'f'),
  (1, 'PartnerDelay_Reason', 'label', 't', 'f'),
  (1, 'PartnerDelay_Notified', 'id', 't', 'f'),
  (1, 'PartnerDelay_Notified', 'label', 't', 'f'),
  (1, 'PartnerDelay_Confirmed', 'id', 't', 'f'),
  (1, 'PartnerDelay_Confirmed', 'label', 't', 'f'),
  (1, 'PartnerDelay_Exceptional', 'id', 't', 'f'),
  (1, 'PartnerDelay_Exceptional', 'label', 't', 'f'),
  (6, 'PartnerDelay_Reason', 'id', 't', 't'),
  (6, 'PartnerDelay_Reason', 'label', 't', 't'),
  (6, 'PartnerDelay_Notified', 'id', 't', 't'),
  (6, 'PartnerDelay_Notified', 'label', 't', 't'),
  (6, 'PartnerDelay_Confirmed', 'id', 't', 't'),
  (6, 'PartnerDelay_Confirmed', 'label', 't', 't'),
  (6, 'PartnerDelay_Exceptional', 'id', 't', 't'),
  (6, 'PartnerDelay_Exceptional', 'label', 't', 't');
EOF